// OBBBA tips & overtime deduction engine (IRC §224 / §225, tax years 2025–2028).
// See tax_data.js for sources. All figures are federal income tax only.

import { OBBBA, YEARS } from "./tax_data.js";
import { taxFromBrackets, marginalRate, taxSavedByDeduction } from "./fed_tax.js";

// FLSA §7 qualified overtime: only the required premium — half the regular
// rate — for hours past 40 in a workweek counts (IRS FS-2026-13 Q12/Q16).
// Anything paid above time-and-a-half (e.g. double time) does not add
// qualified overtime beyond the 0.5x portion.
export function qualifiedOTFromHours(regularRate, otHours) {
  if (!(regularRate > 0) || !(otHours > 0)) return 0;
  return 0.5 * regularRate * otHours;
}

// Phase-out: reduction = 10% of MAGI excess over the threshold, applied to
// each deduction independently (IRS: "$100 for each $1,000" over
// $150,000 / $300,000 joint; Schedule 1-A worksheet implements linearly).
export function phaseoutReduction(magi, filing) {
  const threshold = filing === "mfj" ? OBBBA.phaseout.thresholdJoint : OBBBA.phaseout.thresholdSingle;
  return Math.max(0, magi - threshold) * OBBBA.phaseout.ratePerDollar;
}

export function tipsDeduction({ qualifiedTips, magi, filing, selfEmployedNetIncome = null }) {
  if (filing === "mfs") return { deduction: 0, capped: 0, reduction: 0, ineligible: "mfs" };
  let base = Math.min(Math.max(0, qualifiedTips), OBBBA.tips.cap);
  // Self-employed: deduction can't exceed net income (before this deduction)
  // from the trade or business in which the tips were earned.
  if (selfEmployedNetIncome !== null) base = Math.min(base, Math.max(0, selfEmployedNetIncome));
  const reduction = phaseoutReduction(magi, filing);
  return { deduction: Math.max(0, base - reduction), capped: base, reduction };
}

export function overtimeDeduction({ qualifiedOT, magi, filing }) {
  if (filing === "mfs") return { deduction: 0, capped: 0, reduction: 0, ineligible: "mfs" };
  const cap = filing === "mfj" ? OBBBA.overtime.capJoint : OBBBA.overtime.capSingle;
  const base = Math.min(Math.max(0, qualifiedOT), cap);
  const reduction = phaseoutReduction(magi, filing);
  return { deduction: Math.max(0, base - reduction), capped: base, reduction };
}

// Full estimate. `totalIncome` = all income before deductions (used both as a
// MAGI approximation and to find taxable income). Deductions stack on top of
// the standard deduction (available to non-itemizers; Schedule 1-A).
export function estimate({
  year = 2026,
  filing = "single",          // single | mfj | hoh | mfs
  totalIncome = 0,
  qualifiedTips = 0,
  qualifiedOT = 0,
  itemizedDeduction = null,   // null -> standard deduction
  selfEmployedNetIncome = null,
}) {
  const yr = YEARS[year];
  if (!yr) throw new Error(`Unsupported year ${year}`);
  const sdKey = filing === "mfs" ? "single" : filing; // MFS uses single-sized SD
  const baseDeduction = itemizedDeduction ?? yr.standardDeduction[sdKey];
  const brackets = yr.brackets[filing === "mfs" ? "single" : filing];

  const magi = totalIncome; // approximation; §911/931/933 exclusions are rare
  const tips = tipsDeduction({ qualifiedTips, magi, filing, selfEmployedNetIncome });
  const ot = overtimeDeduction({ qualifiedOT, magi, filing });
  const combined = tips.deduction + ot.deduction;

  const taxableBefore = Math.max(0, totalIncome - baseDeduction);
  const taxableAfter = Math.max(0, taxableBefore - combined);
  const taxBefore = taxFromBrackets(taxableBefore, brackets);
  const taxAfter = taxFromBrackets(taxableAfter, brackets);

  return {
    year,
    filing,
    magi,
    tips,
    ot,
    combinedDeduction: combined,
    taxableBefore,
    taxableAfter,
    taxBefore,
    taxAfter,
    savings: taxBefore - taxAfter,
    marginalRateBefore: marginalRate(taxableBefore, brackets),
    ineligibleMFS: filing === "mfs",
  };
}

export { taxFromBrackets, marginalRate, taxSavedByDeduction };
