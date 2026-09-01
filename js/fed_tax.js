// Generic federal income tax bracket math.
// Data (brackets, standard deductions) lives in tax_data.js.

// brackets: [{ rate, upTo }] ascending, last upTo = Infinity. Taxable income in, tax out.
export function taxFromBrackets(taxable, brackets) {
  let tax = 0;
  let lower = 0;
  for (const { rate, upTo } of brackets) {
    if (taxable <= lower) break;
    const slice = Math.min(taxable, upTo) - lower;
    tax += slice * rate;
    lower = upTo;
  }
  return tax;
}

export function marginalRate(taxable, brackets) {
  if (taxable <= 0) return 0;
  let lower = 0;
  for (const { rate, upTo } of brackets) {
    if (taxable > lower && taxable <= upTo) return rate;
    lower = upTo;
  }
  return brackets[brackets.length - 1].rate;
}

// Federal income tax saved by removing `deduction` dollars of taxable income,
// computed exactly (handles bracket crossings), never below zero taxable.
export function taxSavedByDeduction(taxableBefore, deduction, brackets) {
  const before = taxFromBrackets(Math.max(0, taxableBefore), brackets);
  const after = taxFromBrackets(Math.max(0, taxableBefore - deduction), brackets);
  return before - after;
}
