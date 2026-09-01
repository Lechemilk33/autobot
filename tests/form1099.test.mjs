// 1099 checker tests. Fixture sources:
//  [IRS-FS-2025-08] https://www.irs.gov/newsroom/irs-issues-faqs-on-form-1099-k-threshold-under-the-one-big-beautiful-bill-dollar-limit-reverts-to-20000
//  [IRS-1099K] https://www.irs.gov/businesses/understanding-your-form-1099-k
//  [STATE] MA TIR 17-11, VT 32 V.S.A. §5862d, VA Tax Bulletin 20-10, IL 35 ILCS 5/704A

import test from "node:test";
import assert from "node:assert/strict";
import { expect1099K, expect1099NEC, FED_1099NEC } from "../site/js/form1099.js";

test("[IRS-FS-2025-08] federal: needs BOTH >$20k AND >200 transactions", () => {
  // $25k over 150 transactions: amount alone is not enough.
  assert.equal(expect1099K({ year: 2026, state: "OTHER", gross: 25000, txns: 150 }).expect, false);
  // 250 transactions but only $15k: count alone is not enough.
  assert.equal(expect1099K({ year: 2026, state: "OTHER", gross: 15000, txns: 250 }).expect, false);
  // Both exceeded -> yes.
  assert.equal(expect1099K({ year: 2026, state: "OTHER", gross: 25000, txns: 250 }).expect, true);
  // Exactly at the line ($20,000 / 200) does NOT trigger — must EXCEED.
  assert.equal(expect1099K({ year: 2026, state: "OTHER", gross: 20000, txns: 200 }).expect, false);
});

test("[STATE] Massachusetts $600 rule catches a casual eBay seller", () => {
  const r = expect1099K({ year: 2026, state: "MA", gross: 900, txns: 6 });
  assert.equal(r.expect, true);
  assert.equal(r.reasons[0].kind, "state");
});

test("[STATE] Illinois needs BOTH >$1,000 AND >=4 transactions", () => {
  assert.equal(expect1099K({ year: 2026, state: "IL", gross: 1500, txns: 3 }).expect, false);
  assert.equal(expect1099K({ year: 2026, state: "IL", gross: 1500, txns: 4 }).expect, true);
  assert.equal(expect1099K({ year: 2026, state: "IL", gross: 800, txns: 10 }).expect, false);
});

test("[IRS-1099K] card-reader (merchant) payments have no minimum", () => {
  const r = expect1099K({ year: 2026, state: "OTHER", gross: 50, txns: 1, cardPayments: true });
  assert.equal(r.expect, true);
  assert.equal(r.reasons[0].kind, "card");
});

test("[PLATFORM] backup withholding triggers a form at any amount", () => {
  const r = expect1099K({ year: 2026, state: "OTHER", gross: 120, txns: 2, backupWithholding: true });
  assert.equal(r.expect, true);
});

test("[STATE] California app-driver exception over $600", () => {
  assert.equal(expect1099K({ year: 2026, state: "CA", gross: 5000, txns: 300, appDriver: true }).expect, true);
  assert.equal(expect1099K({ year: 2026, state: "CA", gross: 5000, txns: 300, appDriver: false }).expect, false);
});

test("[OBBBA] 1099-NEC threshold: $600 in 2025, $2,000 in 2026", () => {
  assert.equal(FED_1099NEC[2025], 600);
  assert.equal(FED_1099NEC[2026], 2000);
  assert.equal(expect1099NEC({ year: 2025, paidByOneClient: 700 }).expect, true);
  assert.equal(expect1099NEC({ year: 2026, paidByOneClient: 700 }).expect, false);
  assert.equal(expect1099NEC({ year: 2026, paidByOneClient: 2000 }).expect, true);
});
