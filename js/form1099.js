// "Will I get a 1099?" rules for tax years 2025 and 2026.
//
// Sources (verified 2026-09-01):
// - Federal 1099-K: OBBBA restored >$20,000 AND >200 transactions (TPSOs),
//   retroactive to 2022. IRS FS-2025-08:
//   https://www.irs.gov/newsroom/irs-issues-faqs-on-form-1099-k-threshold-under-the-one-big-beautiful-bill-dollar-limit-reverts-to-20000
// - Payment-card (merchant acquirer) 1099-K has NO threshold:
//   https://www.irs.gov/businesses/understanding-your-form-1099-k
// - 1099-NEC/MISC: $600 (TY2025) -> $2,000 (TY2026), indexed after 2026:
//   https://www.avalara.com/blog/en/north-america/2025/07/one-big-beautiful-bill-act-1099-reporting-threshold.html
// - State thresholds: MA (TIR 17-11), VT (32 V.S.A. §5862d), VA (Tax Bulletin
//   20-10), MD (SB 192 2020), IL (35 ILCS 5/704A), NJ/MO/AR/DC/MT/RI per
//   platform policy pages (eBay, PayPal) and tax publishers; confidence noted.
// - Backup withholding 24%:
//   https://www.irs.gov/businesses/small-businesses-self-employed/backup-withholding

export const FED_1099K = {
  2025: { amount: 20000, transactions: 200 }, // BOTH must be exceeded
  2026: { amount: 20000, transactions: 200 },
};

export const FED_1099NEC = { 2025: 600, 2026: 2000 };

// States where platforms issue 1099-Ks at lower thresholds based on the
// seller's state of residence. confidence: "high" = verified against the
// state's own statute/guidance; "medium" = platform practice + tax
// publishers; "low" = publisher-reported only, flagged in the UI.
export const STATE_1099K = {
  MA: { name: "Massachusetts", amount: 600, transactions: null, confidence: "high" },
  VT: { name: "Vermont", amount: 600, transactions: null, confidence: "high" },
  VA: { name: "Virginia", amount: 600, transactions: null, confidence: "high" },
  MD: { name: "Maryland", amount: 600, transactions: null, confidence: "high",
        note: "Maryland's rule is tied to a federal threshold that changed for 2026; some platforms may apply $2,000 for 2026. Expect a form at $600 to be safe." },
  IL: { name: "Illinois", amount: 1000, transactions: 4, confidence: "high",
        note: "Illinois requires BOTH more than $1,000 and at least 4 transactions." },
  NJ: { name: "New Jersey", amount: 1000, transactions: null, confidence: "medium",
        note: "Some platforms send payee copies for New Jersey and some only report to the state." },
  MO: { name: "Missouri", amount: 1200, transactions: null, confidence: "medium" },
  AR: { name: "Arkansas", amount: 2500, transactions: null, confidence: "medium" },
  DC: { name: "District of Columbia", amount: 600, transactions: null, confidence: "medium" },
  MT: { name: "Montana", amount: 600, transactions: null, confidence: "low",
        note: "Reported by platforms and tax publishers; we could not confirm this figure in Montana's own published guidance." },
  RI: { name: "Rhode Island", amount: 1500, transactions: null, confidence: "low",
        note: "Platforms treat Rhode Island as a lower-threshold state but published figures conflict. Expect a form at low totals." },
};

// California follows federal, with a $600 exception for app-based drivers.
export const CA_DRIVER_EXCEPTION = { amount: 600 };

/**
 * Decide whether a seller should expect a 1099-K.
 * @param {object} p
 * @param {number} p.year 2025|2026
 * @param {string} p.state two-letter code or "OTHER"
 * @param {number} p.gross gross payments on the platform
 * @param {number} p.txns number of transactions
 * @param {boolean} p.cardPayments true if payments were card-present/merchant acquirer (e.g. Square reader)
 * @param {boolean} p.backupWithholding true if platform withheld tax (missing/mismatched TIN)
 * @param {boolean} p.appDriver true if app-based driver (CA exception)
 */
export function expect1099K({ year = 2026, state = "OTHER", gross = 0, txns = 0,
                              cardPayments = false, backupWithholding = false, appDriver = false }) {
  const reasons = [];
  let expect = false;

  if (cardPayments) {
    expect = true;
    reasons.push({ kind: "card", text: "Card payments processed for you as a merchant (for example a card reader) are reported with no minimum — every dollar goes on a 1099-K." });
  }

  const fed = FED_1099K[year];
  if (gross > fed.amount && txns > fed.transactions) {
    expect = true;
    reasons.push({ kind: "federal", text: `You crossed the federal line: more than $${fed.amount.toLocaleString()} AND more than ${fed.transactions} transactions.` });
  }

  const st = STATE_1099K[state];
  if (st) {
    const amountHit = gross > st.amount;
    const txnHit = st.transactions == null ? true : txns >= st.transactions;
    if (amountHit && txnHit) {
      expect = true;
      reasons.push({ kind: "state", state, confidence: st.confidence,
        text: `${st.name} makes platforms report at a much lower level (over $${st.amount.toLocaleString()}${st.transactions ? ` and at least ${st.transactions} transactions` : ""}).`,
        note: st.note ?? null });
    }
  }

  if (state === "CA" && appDriver && gross > CA_DRIVER_EXCEPTION.amount) {
    expect = true;
    reasons.push({ kind: "state", state: "CA", confidence: "medium",
      text: "California requires reporting for app-based drivers over $600.",
      note: "Confirmed by tax publishers; California generally follows the federal threshold otherwise." });
  }

  if (backupWithholding) {
    expect = true;
    reasons.push({ kind: "withholding", text: "Platforms send a 1099-K to anyone who had backup withholding during the year, no matter how small the total." });
  }

  return { expect, reasons };
}

/** 1099-NEC expectation for direct-pay gig work / freelance clients. */
export function expect1099NEC({ year = 2026, paidByOneClient = 0 }) {
  const threshold = FED_1099NEC[year];
  return { expect: paidByOneClient >= threshold, threshold };
}

// 2026 quarterly estimated tax dates + safe harbor.
// https://www.irs.gov/faqs/estimated-tax
export const ESTIMATED_2026 = {
  dueDates: [
    { q: "1st", date: "April 15, 2026" },
    { q: "2nd", date: "June 15, 2026" },
    { q: "3rd", date: "September 15, 2026" },
    { q: "4th", date: "January 15, 2027" },
  ],
  owingTrigger: 1000,
  safeHarbor: { currentYearPct: 0.90, priorYearPct: 1.00, priorYearHighAGIPct: 1.10, highAGI: 150000 },
};
