// Calculator page controller.
import { $, fmtUSD, fmtPct, moneyVal, segControl, debounce } from "./ui.js";
import { estimate, qualifiedOTFromHours } from "./obbba.js";
import { TTOC } from "./tax_data.js";

// --- populate occupation dropdown from the Treasury list ---
const occSelect = $("#occupation");
occSelect.innerHTML = "";
const addOpt = (parent, value, label) => {
  const o = document.createElement("option");
  o.value = value; o.textContent = label;
  parent.appendChild(o);
};
addOpt(occSelect, "", "I don't earn tips");
for (const [code, group] of Object.entries(TTOC)) {
  const og = document.createElement("optgroup");
  og.label = group.category;
  for (const [oc, name] of Object.entries(group.occupations)) {
    addOpt(og, `ttoc-${oc}`, name);
  }
  occSelect.appendChild(og);
}
addOpt(occSelect, "no", "My job isn't listed here");

// --- state ---
const yearSeg = segControl($("#seg-year"), recalc);
const filingSeg = segControl($("#seg-filing"), () => { syncVisibility(); recalc(); });
const otSeg = segControl($("#seg-ot"), () => { syncVisibility(); recalc(); });

const el = {
  income: $("#income"),
  tips: $("#tips"),
  seRow: $("#se-row"),
  seCheck: $("#self-employed"),
  seNetField: $("#se-net-field"),
  seNet: $("#se-net"),
  tipsField: $("#tips-amount-field"),
  occWarn: $("#occupation-no-warning"),
  mfsWarn: $("#mfs-warning"),
  otHoursFields: $("#ot-hours-fields"),
  otDirectField: $("#ot-direct-field"),
  otFlsaNote: $("#ot-flsa-note"),
  otRate: $("#ot-rate"),
  otHoursWeek: $("#ot-hours-week"),
  otWeeks: $("#ot-weeks"),
  otPremium: $("#ot-premium"),
  results: $("#results"),
  rSavings: $("#r-savings"),
  rHeadline: $("#r-headline"),
  rTips: $("#r-tips"),
  rOt: $("#r-ot"),
  rCombined: $("#r-combined"),
  rRate: $("#r-rate"),
  notes: $("#result-notes"),
};

function tipsMode() {
  const v = occSelect.value;
  if (!v) return "none";
  return v === "no" ? "unlisted" : "listed";
}

function syncVisibility() {
  const tm = tipsMode();
  el.tipsField.hidden = tm !== "listed";
  el.occWarn.hidden = tm !== "unlisted";
  el.seRow.hidden = tm !== "listed";
  el.seNetField.hidden = tm !== "listed" || !el.seCheck.checked;

  const ot = otSeg.get();
  el.otHoursFields.hidden = ot !== "hours";
  el.otDirectField.hidden = ot !== "direct";
  el.otFlsaNote.hidden = ot === "none";

  el.mfsWarn.hidden = filingSeg.get() !== "mfs";
}

function currentOTPremium() {
  const mode = otSeg.get();
  if (mode === "direct") return moneyVal(el.otPremium);
  if (mode === "hours") {
    const rate = moneyVal(el.otRate);
    const perWeek = parseFloat(el.otHoursWeek.value) || 0;
    const weeks = Math.min(52, parseFloat(el.otWeeks.value) || 0);
    return qualifiedOTFromHours(rate, perWeek * weeks);
  }
  return 0;
}

function note(kind, html) {
  return `<div class="callout ${kind}">${html}</div>`;
}

function recalc() {
  syncVisibility();
  const year = parseInt(yearSeg.get(), 10);
  const filing = filingSeg.get();
  const income = moneyVal(el.income);
  const tips = tipsMode() === "listed" ? moneyVal(el.tips) : 0;
  const seNet = tipsMode() === "listed" && el.seCheck.checked ? moneyVal(el.seNet) : null;
  const otPremium = currentOTPremium();

  const hasAnything = income > 0 && (tips > 0 || otPremium > 0);
  if (!hasAnything || filing === "mfs") {
    el.results.hidden = true;
    el.notes.innerHTML = filing === "mfs" ? "" : "";
    return;
  }

  const r = estimate({
    year, filing, totalIncome: income,
    qualifiedTips: tips, qualifiedOT: otPremium,
    selfEmployedNetIncome: seNet,
  });

  el.results.hidden = false;
  el.rSavings.textContent = fmtUSD(Math.round(r.savings));
  el.rTips.textContent = fmtUSD(Math.round(r.tips.deduction));
  el.rOt.textContent = fmtUSD(Math.round(r.ot.deduction));
  el.rCombined.textContent = fmtUSD(Math.round(r.combinedDeduction));
  el.rRate.textContent = fmtPct(r.marginalRateBefore);

  if (r.savings > 0) {
    el.rHeadline.textContent =
      `Deducting ${fmtUSD(Math.round(r.combinedDeduction))} from your taxable income cuts your ${year} federal income tax by about ${fmtUSD(Math.round(r.savings))}. You'll typically see it as a bigger refund when you file.`;
  } else {
    el.rHeadline.textContent =
      `Based on these numbers, the deductions don't reduce your federal income tax — see the notes below for why.`;
  }

  // Notes
  const notes = [];
  if (r.tips.capped < tips) {
    notes.push(note("info", `<strong>Tips cap applied.</strong> The tips deduction tops out at $25,000 per return — that's the same cap whether you file alone or jointly.`));
  }
  if (otSeg.get() !== "none" && r.ot.capped < otPremium) {
    const cap = filing === "mfj" ? "$25,000" : "$12,500";
    notes.push(note("info", `<strong>Overtime cap applied.</strong> The overtime deduction tops out at ${cap} of premium pay for your filing status.`));
  }
  if (r.tips.reduction > 0 || r.ot.reduction > 0) {
    const th = filing === "mfj" ? "$300,000" : "$150,000";
    notes.push(note("warn", `<strong>High-income phase-down applied.</strong> Above ${th} of income, both deductions shrink by $100 for every $1,000 over. Yours were reduced by ${fmtUSD(Math.round(Math.min(r.tips.reduction, r.tips.capped) + Math.min(r.ot.reduction, r.ot.capped)))} total.`));
  }
  if (seNet !== null && r.tips.capped <= (seNet ?? Infinity) && seNet < Math.min(tips, 25000)) {
    notes.push(note("info", `<strong>Self-employment limit applied.</strong> Your tips deduction can't exceed the net profit of the business the tips came from.`));
  }
  if (r.taxableAfter === 0 && r.savings >= 0) {
    notes.push(note("info", `<strong>Part of your deduction goes unused.</strong> Your taxable income hit $0 before the full deduction was spent — the standard deduction was already shielding most of your income. The unused part doesn't carry over.`));
  }
  if (tips > 0 || otPremium > 0) {
    notes.push(note("good", `<strong>Heads up for January:</strong> for ${year === 2026 ? "2026, your W-2 Box 12 numbers (codes TP and TT) decide what you can claim — check them against your own records" : "2025, employers weren't required to report these separately — paystubs and any reasonable method are allowed"}. Social Security and Medicare taxes still apply to tips and overtime either way.`));
  }
  el.notes.innerHTML = notes.join("");
}

// wire inputs
[el.income, el.tips, el.seNet, el.otRate, el.otHoursWeek, el.otWeeks, el.otPremium]
  .forEach((i) => i.addEventListener("input", debounce(recalc, 120)));
occSelect.addEventListener("change", recalc);
el.seCheck.addEventListener("change", recalc);

syncVisibility();
