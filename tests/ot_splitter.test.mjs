// Employer splitter tests, pinned to IRS FS-2026-13 worked examples.

import test from "node:test";
import assert from "node:assert/strict";
import { splitOvertime, resultToCSV } from "../site/js/ot_splitter.js";
import { parseCSV } from "../site/js/csv.js";

test("[IRS-FS Q16] double-time payer: qualified stays at the FLSA half", () => {
  // $20/hr, 10 OT hours, paid double time (x2): employer paid $400 of OT,
  // FLSA required $300, qualified overtime = $100.
  const csv = "employee,regular_rate,ot_hours,multiplier\nAlex,20,10,2\n";
  const { rows, errors } = splitOvertime(csv);
  assert.equal(errors.length, 0);
  assert.equal(rows[0].qualified, 100);
  assert.equal(rows[0].paidEstimate, 400);
  assert.equal(rows[0].nonQualified, 300);
});

test("[TAXACT] $30/hr at time-and-a-half: $15 of each OT hour qualifies", () => {
  const csv = "employee,regular_rate,ot_hours\nBrianna,30,10\n";
  const { rows } = splitOvertime(csv);
  assert.equal(rows[0].qualified, 150);
  assert.equal(rows[0].paidEstimate, 450);
});

test("header aliases and dollar formatting are tolerated", () => {
  const csv = 'Name,Hourly Rate,Overtime Hours\n"Smith, Pat","$22.50",8\n';
  const { rows, errors } = splitOvertime(csv);
  assert.equal(errors.length, 0);
  assert.equal(rows[0].employee, "Smith, Pat");
  assert.equal(rows[0].qualified, 90); // 0.5 * 22.50 * 8
});

test("bad rows are skipped with line-numbered errors, good rows survive", () => {
  const csv = "employee,regular_rate,ot_hours\nGood,20,5\n,15,3\nBadRate,zero,4\n";
  const { rows, errors, totals } = splitOvertime(csv);
  assert.equal(rows.length, 1);
  assert.equal(errors.length, 2);
  assert.match(errors[0], /Row 3/);
  assert.match(errors[1], /Row 4/);
  assert.equal(totals.qualified, 50);
});

test("sub-1.5x multiplier is flagged but still computed at the required rate", () => {
  const csv = "employee,regular_rate,ot_hours,multiplier\nCasey,20,10,1.2\n";
  const { rows, errors } = splitOvertime(csv);
  assert.equal(rows.length, 1);
  assert.equal(rows[0].qualified, 100);
  assert.match(errors[0], /below time-and-a-half/);
});

test("missing required columns produce a helpful error", () => {
  const { errors } = splitOvertime("employee,hours\nA,5\n");
  assert.match(errors[0], /Missing column/);
});

test("export round-trips through the CSV parser", () => {
  const csv = "employee,regular_rate,ot_hours\nDee,18,12\n";
  const { rows } = splitOvertime(csv);
  const out = parseCSV(resultToCSV(rows));
  assert.equal(out.length, 2);
  assert.equal(out[1][0], "Dee");
  assert.equal(out[1][4], "108.00"); // 0.5*18*12
});

test("totals add up across employees", () => {
  const csv = "employee,regular_rate,ot_hours\nA,20,10\nB,30,4\n";
  const { totals } = splitOvertime(csv);
  assert.equal(totals.qualified, 160); // 100 + 60
  assert.equal(totals.otHours, 14);
});
