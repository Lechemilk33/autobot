// Engine tests pinned to authoritative worked examples.
// Fixture sources:
//  [IRS-FS]  IRS FS-2026-13 (Aug 2026 overtime FAQ) https://www.irs.gov/pub/taxpros/fs-2026-13.pdf
//  [TAXACT]  https://blog.taxact.com/no-tax-on-overtime-explained/
//  [FIDELITY] https://www.fidelity.com/learning-center/personal-finance/no-tax-on-tips
//  [RP-25-32] Rev. Proc. 2025-32 (2026 inflation adjustments)

import test from "node:test";
import assert from "node:assert/strict";
import {
  qualifiedOTFromHours,
  tipsDeduction,
  overtimeDeduction,
  estimate,
} from "../site/js/obbba.js";
import { taxFromBrackets, marginalRate } from "../site/js/fed_tax.js";
import { YEARS } from "../site/js/tax_data.js";

test("[IRS-FS Q16] $20/hr, 10 OT hours, double-time paid: only the FLSA half counts -> $100", () => {
  // Employer paid $400 of OT ($40/hr double time); FLSA required $300;
  // qualified overtime is the required premium only: 10 x 0.5 x $20 = $100.
  assert.equal(qualifiedOTFromHours(20, 10), 100);
});

test("[TAXACT] rate anatomy: $30/hr -> $15/OT-hr deductible; $20/hr -> $10/OT-hr", () => {
  assert.equal(qualifiedOTFromHours(30, 1), 15);
  assert.equal(qualifiedOTFromHours(20, 1), 10);
  // $30/hr with 10 OT hours: $150 qualified, not the $450 paid.
  assert.equal(qualifiedOTFromHours(30, 10), 150);
});

test("[IRS-FS Q10/Q19] $30,000 W-2 code TT caps at $12,500 single / $25,000 joint", () => {
  assert.equal(overtimeDeduction({ qualifiedOT: 30000, magi: 60000, filing: "single" }).deduction, 12500);
  assert.equal(overtimeDeduction({ qualifiedOT: 30000, magi: 60000, filing: "mfj" }).deduction, 25000);
});

test("[TAXACT] single filer, MAGI $155,000: max OT deduction reduced to $12,000", () => {
  assert.equal(overtimeDeduction({ qualifiedOT: 30000, magi: 155000, filing: "single" }).deduction, 12000);
});

test("[TAXACT] single filer, $5,000 qualified OT, MAGI $200,000: fully phased out to $0", () => {
  assert.equal(overtimeDeduction({ qualifiedOT: 5000, magi: 200000, filing: "single" }).deduction, 0);
});

test("[FIDELITY] $20,000 tips fully inside 22% bracket saves $4,400", () => {
  // Single 2026, $90,000 income: taxable $73,900 -> $53,900; both in the 22% bracket.
  const r = estimate({ year: 2026, filing: "single", totalIncome: 90000, qualifiedTips: 20000 });
  assert.equal(r.tips.deduction, 20000);
  assert.equal(Math.round(r.savings), 4400);
  assert.equal(r.marginalRateBefore, 0.22);
});

test("[FIDELITY] $30,000 tips cap at $25,000; $18,000 tips deduct in full", () => {
  assert.equal(tipsDeduction({ qualifiedTips: 30000, magi: 75000, filing: "single" }).deduction, 25000);
  assert.equal(tipsDeduction({ qualifiedTips: 18000, magi: 75000, filing: "single" }).deduction, 18000);
});

test("[IRS] tips cap is $25,000 per return — it does NOT double for joint filers", () => {
  assert.equal(tipsDeduction({ qualifiedTips: 40000, magi: 100000, filing: "mfj" }).deduction, 25000);
});

test("[IRS] married filing separately is ineligible for both deductions", () => {
  assert.equal(tipsDeduction({ qualifiedTips: 10000, magi: 50000, filing: "mfs" }).deduction, 0);
  assert.equal(overtimeDeduction({ qualifiedOT: 10000, magi: 50000, filing: "mfs" }).deduction, 0);
});

test("[IRS] phase-outs hit both deductions independently and simultaneously", () => {
  // Single, MAGI $160,000: $10,000 excess -> $1,000 off EACH deduction.
  const tips = tipsDeduction({ qualifiedTips: 25000, magi: 160000, filing: "single" });
  const ot = overtimeDeduction({ qualifiedOT: 12500, magi: 160000, filing: "single" });
  assert.equal(tips.deduction, 24000);
  assert.equal(ot.deduction, 11500);
});

test("[IRS] full phase-out boundaries: tips gone at $400k single; OT gone at $275k single", () => {
  assert.equal(tipsDeduction({ qualifiedTips: 25000, magi: 400000, filing: "single" }).deduction, 0);
  assert.ok(tipsDeduction({ qualifiedTips: 25000, magi: 399000, filing: "single" }).deduction > 0);
  assert.equal(overtimeDeduction({ qualifiedOT: 12500, magi: 275000, filing: "single" }).deduction, 0);
  assert.ok(overtimeDeduction({ qualifiedOT: 12500, magi: 274000, filing: "single" }).deduction > 0);
});

test("[IRS] self-employed tips deduction limited to business net income", () => {
  const r = tipsDeduction({ qualifiedTips: 20000, magi: 40000, filing: "single", selfEmployedNetIncome: 5000 });
  assert.equal(r.deduction, 5000);
});

test("[RP-25-32] 2026 bracket math: single, taxable exactly at 10% top pays $1,240", () => {
  assert.equal(taxFromBrackets(12400, YEARS[2026].brackets.single), 1240);
  // Standard deductions
  assert.equal(YEARS[2026].standardDeduction.single, 16100);
  assert.equal(YEARS[2026].standardDeduction.mfj, 32200);
  assert.equal(YEARS[2026].standardDeduction.hoh, 24150);
});

test("[RP-25-32] 2026 single, $60,000 taxable: cross-check full bracket sum", () => {
  // 10%*12400 + 12%*(50400-12400) + 22%*(60000-50400) = 1240 + 4560 + 2112 = 7912
  assert.equal(taxFromBrackets(60000, YEARS[2026].brackets.single), 7912);
  assert.equal(marginalRate(60000, YEARS[2026].brackets.single), 0.22);
});

test("deduction cannot push taxable income below zero", () => {
  // $20,000 income, $10,000 tips: taxable before = $3,900; deduction floors at 0 taxable.
  const r = estimate({ year: 2026, filing: "single", totalIncome: 20000, qualifiedTips: 10000 });
  assert.equal(r.taxableAfter, 0);
  assert.equal(Math.round(r.savings), 390);
});

test("estimate() 2025 works with 2025 constants", () => {
  const r = estimate({ year: 2025, filing: "mfj", totalIncome: 80000, qualifiedTips: 12000, qualifiedOT: 4000 });
  assert.equal(r.combinedDeduction, 16000);
  // Taxable before: 80000-31500 = 48500 (12% bracket, MFJ 2025). Savings = 16000*0.12 = 1920
  assert.equal(Math.round(r.savings), 1920);
});
