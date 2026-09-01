// W-2 Box 12 codes — 2026 General Instructions for Forms W-2 and W-3
// (rev. Jan 29, 2026): https://www.irs.gov/pub/irs-pdf/iw2w3.pdf
// Letters I, O, U, X are unassigned; retired codes are not listed.

export const BOX12 = {
  A:  { text: "Uncollected Social Security or RRTA tax on tips", plain: "Your employer couldn't withhold all the Social Security tax owed on your tips. You may owe it at filing time (Form 1040 Schedule 2)." },
  B:  { text: "Uncollected Medicare tax on tips", plain: "Your employer couldn't withhold all the Medicare tax owed on your tips. You may owe it at filing time." },
  C:  { text: "Taxable cost of group-term life insurance over $50,000", plain: "The value of employer life insurance above $50,000 of coverage. It's already included in your wages — nothing extra to do." },
  D:  { text: "Elective deferrals to a 401(k) plan", plain: "What you put into your 401(k) before tax this year." },
  E:  { text: "Elective deferrals to a 403(b) plan", plain: "What you put into your 403(b) retirement plan before tax." },
  F:  { text: "Elective deferrals to a 408(k)(6) SEP", plain: "Contributions to a salary-reduction SEP retirement plan." },
  G:  { text: "Deferrals and employer contributions to a 457(b) plan", plain: "Contributions to a government or nonprofit deferred-compensation plan." },
  H:  { text: "Elective deferrals to a 501(c)(18)(D) plan", plain: "Contributions to a certain kind of pre-1959 union pension trust. Rare." },
  J:  { text: "Nontaxable sick pay", plain: "Sick pay that isn't taxable because you paid the insurance premiums. Informational only." },
  K:  { text: "20% excise tax on excess golden parachute payments", plain: "Extra tax on large severance ('golden parachute') payouts. Adds to your tax bill." },
  L:  { text: "Substantiated employee business expense reimbursements", plain: "Work-expense reimbursements your employer paid under an accountable plan. Usually not taxable." },
  M:  { text: "Uncollected Social Security or RRTA tax on group-term life insurance over $50,000 (former employees)", plain: "Social Security tax still owed on life-insurance coverage after you left the job." },
  N:  { text: "Uncollected Medicare tax on group-term life insurance over $50,000 (former employees)", plain: "Medicare tax still owed on life-insurance coverage after you left the job." },
  P:  { text: "Excludable moving expense reimbursements (Armed Forces / intelligence community)", plain: "Tax-free military or intelligence-community moving reimbursements." },
  Q:  { text: "Nontaxable combat pay", plain: "Combat-zone pay that's excluded from tax. Can still count for some credits like the EITC." },
  R:  { text: "Employer contributions to an Archer MSA", plain: "Employer payments into an Archer medical savings account. Report on Form 8853." },
  S:  { text: "Employee contributions to a 408(p) SIMPLE plan", plain: "What you put into a SIMPLE retirement plan." },
  T:  { text: "Adoption benefits", plain: "Employer adoption assistance. Use Form 8839 to figure the excludable part." },
  V:  { text: "Income from exercise of nonstatutory stock options", plain: "Profit from exercising employer stock options. Already included in your wages." },
  W:  { text: "Employer contributions to a Health Savings Account (including cafeteria-plan contributions)", plain: "Money that went into your HSA through work. Report on Form 8889." },
  Y:  { text: "Deferrals under a section 409A nonqualified deferred compensation plan", plain: "Money deferred into a nonqualified deferred-comp plan. Informational." },
  Z:  { text: "Income under a section 409A plan that failed the rules", plain: "Deferred comp that became taxable because the plan broke the rules — extra 20% tax applies." },
  AA: { text: "Designated Roth contributions to a 401(k) plan", plain: "What you put into a Roth 401(k) — after tax, grows tax-free." },
  BB: { text: "Designated Roth contributions to a 403(b) plan", plain: "What you put into a Roth 403(b) — after tax, grows tax-free." },
  DD: { text: "Cost of employer-sponsored health coverage", plain: "What your health insurance through work costs in total. Informational only — not taxable." },
  EE: { text: "Designated Roth contributions to a governmental 457(b) plan", plain: "Roth contributions to a government deferred-comp plan." },
  FF: { text: "Permitted benefits under a Qualified Small Employer HRA (QSEHRA)", plain: "Health-reimbursement benefits offered by a small employer." },
  GG: { text: "Income from qualified equity grants under section 83(i)", plain: "Income from private-company stock grants you elected to defer." },
  HH: { text: "Aggregate deferrals under section 83(i) at year end", plain: "Running total of stock-grant income still deferred." },
  II: { text: "Medicaid waiver payments excluded from gross income under Notice 2014-7", plain: "Home-care payments that are excluded from taxable income." },
  TA: { text: "Employer contributions to a Trump account", plain: "NEW for 2026. Employer money put into a child's Trump account (up to $2,500 per year, not taxed as income to you).", isNew: true },
  TP: { text: "Total cash tips reported to employer", plain: "NEW for 2026. Your reported tips for the year. This is the number that feeds the tips deduction (up to $25,000) — check it against your own records.", isNew: true },
  TT: { text: "Total qualified overtime compensation", plain: "NEW for 2026. The overtime premium that qualifies for the overtime deduction (up to $12,500, or $25,000 filing jointly). Only the extra 'half' of time-and-a-half counts — not your whole overtime paycheck.", isNew: true },
};

export const BOX14B = {
  name: "Box 14b — Treasury Tipped Occupation Code",
  plain: "New for 2026. A 3-digit code for the tipped job you held. It must be filled in when Box 12 has code TP. Code 000 means the job isn't on the government's list of tipped occupations — tips from it don't qualify for the deduction.",
};
