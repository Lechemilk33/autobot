// 1099 checker page controller.
import { $, segControl, moneyVal, debounce, fmtUSD } from "./ui.js";
import { expect1099K, expect1099NEC, STATE_1099K, FED_1099K, FED_1099NEC } from "./form1099.js";

const STATES = [
  ["AL","Alabama"],["AK","Alaska"],["AZ","Arizona"],["AR","Arkansas"],["CA","California"],
  ["CO","Colorado"],["CT","Connecticut"],["DE","Delaware"],["DC","District of Columbia"],
  ["FL","Florida"],["GA","Georgia"],["HI","Hawaii"],["ID","Idaho"],["IL","Illinois"],
  ["IN","Indiana"],["IA","Iowa"],["KS","Kansas"],["KY","Kentucky"],["LA","Louisiana"],
  ["ME","Maine"],["MD","Maryland"],["MA","Massachusetts"],["MI","Michigan"],["MN","Minnesota"],
  ["MS","Mississippi"],["MO","Missouri"],["MT","Montana"],["NE","Nebraska"],["NV","Nevada"],
  ["NH","New Hampshire"],["NJ","New Jersey"],["NM","New Mexico"],["NY","New York"],
  ["NC","North Carolina"],["ND","North Dakota"],["OH","Ohio"],["OK","Oklahoma"],["OR","Oregon"],
  ["PA","Pennsylvania"],["RI","Rhode Island"],["SC","South Carolina"],["SD","South Dakota"],
  ["TN","Tennessee"],["TX","Texas"],["UT","Utah"],["VT","Vermont"],["VA","Virginia"],
  ["WA","Washington"],["WV","West Virginia"],["WI","Wisconsin"],["WY","Wyoming"],
  ["OTHER","U.S. territory / other"],
];

const stateSel = $("#state");
for (const [code, name] of STATES) {
  const o = document.createElement("option");
  o.value = code; o.textContent = name;
  stateSel.appendChild(o);
}
stateSel.value = "OTHER";

const yearSeg = segControl($("#seg-year"), recalc);
const el = {
  gross: $("#gross"),
  txns: $("#txns"),
  card: $("#card-payments"),
  backup: $("#backup-wh"),
  driverRow: $("#driver-row"),
  driver: $("#app-driver"),
  clientPaid: $("#client-paid"),
  verdict: $("#verdict"),
};

function recalc() {
  el.driverRow.hidden = stateSel.value !== "CA";

  const year = parseInt(yearSeg.get(), 10);
  const gross = moneyVal(el.gross);
  const txns = parseInt(el.txns.value, 10) || 0;
  const clientPaid = moneyVal(el.clientPaid);

  const anyInput = gross > 0 || txns > 0 || clientPaid > 0 || el.card.checked || el.backup.checked;
  if (!anyInput) { el.verdict.innerHTML = ""; return; }

  const k = expect1099K({
    year, state: stateSel.value, gross, txns,
    cardPayments: el.card.checked,
    backupWithholding: el.backup.checked,
    appDriver: stateSel.value === "CA" && el.driver.checked,
  });
  const nec = expect1099NEC({ year, paidByOneClient: clientPaid });

  const parts = [];

  // 1099-K verdict
  if (gross > 0 || txns > 0 || el.card.checked || el.backup.checked) {
    if (k.expect) {
      const reasons = k.reasons.map((r) => {
        let html = `<li>${r.text}`;
        if (r.confidence === "low") html += ` <em>(reported by platforms and tax publishers — this state hasn't published the figure itself, so treat it as likely rather than certain)</em>`;
        if (r.note) html += ` <em>(${r.note})</em>`;
        return html + "</li>";
      }).join("");
      parts.push(`<div class="callout good"><strong>Expect a 1099-K.</strong><ul style="margin:8px 0 0 18px; padding:0;">${reasons}</ul></div>`);
    } else {
      const fed = FED_1099K[year];
      const st = STATE_1099K[stateSel.value];
      let text = `<strong>A 1099-K is unlikely from this platform.</strong> You're under the federal line (more than ${fmtUSD(fed.amount)} AND more than ${fed.transactions} sales)`;
      text += st ? `, and under your state's lower reporting level too.` : `, and your state follows the federal rule.`;
      parts.push(`<div class="callout info">${text}</div>`);
    }
  }

  // NEC verdict
  if (clientPaid > 0) {
    if (nec.expect) {
      parts.push(`<div class="callout good"><strong>Expect a 1099-NEC from that client.</strong> For ${year}, clients must send one once they've paid you ${fmtUSD(nec.threshold)} or more for work.</div>`);
    } else {
      parts.push(`<div class="callout info"><strong>That client doesn't have to send a 1099-NEC.</strong> The ${year} threshold is ${fmtUSD(nec.threshold)} — ${year === 2026 ? "it jumped from $600 this year" : "it rises to $2,000 next year"}. The income is still taxable.</div>`);
    }
  }

  // Universal honesty note
  if ((gross > 0 || clientPaid > 0)) {
    parts.push(`<div class="callout warn"><strong>Form or no form, the income is taxable.</strong> The thresholds only decide what gets reported automatically — not what you owe. If this is real business income with no withholding, look at the quarterly payment dates below.</div>`);
  }

  el.verdict.innerHTML = parts.join("");
}

[el.gross, el.txns, el.clientPaid].forEach((i) => i.addEventListener("input", debounce(recalc, 120)));
[el.card, el.backup, el.driver].forEach((i) => i.addEventListener("change", recalc));
stateSel.addEventListener("change", recalc);

// FED_1099NEC referenced for completeness in messaging
void FED_1099NEC;
