// Employer/bookkeeper batch splitter: turns payroll rows into the
// "qualified overtime compensation" figure that belongs in W-2 Box 12
// code TT — the FLSA §7 required premium (half the regular rate) for hours
// over 40 in a workweek. IRS FS-2026-13 Q12:
//   qualified OT = OT hours x 1/2 x FLSA regular rate.
// Everything the employer pays above that (the straight-time part of the OT
// hour, and anything above time-and-a-half like double time) is NOT
// qualified and must not go into code TT.

import { parseCSV, toCSV } from "./csv.js";

const HEADER_ALIASES = {
  employee: ["employee", "name", "employee name", "employee_name", "worker", "id", "employee id", "emp"],
  rate: ["rate", "regular rate", "regular_rate", "hourly rate", "hourly_rate", "base rate", "pay rate", "flsa regular rate"],
  otHours: ["ot hours", "ot_hours", "othours", "overtime hours", "overtime_hours", "ot", "overtime"],
  multiplier: ["multiplier", "ot multiplier", "ot_multiplier", "ot rate multiplier", "factor"],
};

function matchHeader(cell) {
  const norm = cell.trim().toLowerCase().replace(/\s+/g, " ");
  for (const [key, aliases] of Object.entries(HEADER_ALIASES)) {
    if (aliases.includes(norm)) return key;
  }
  return null;
}

const num = (s) => {
  const n = parseFloat(String(s ?? "").replace(/[$,\s]/g, ""));
  return Number.isFinite(n) ? n : NaN;
};

/**
 * Process a payroll CSV. Expects a header row containing at least an
 * employee column, a regular-rate column, and an overtime-hours column.
 * Optional multiplier column (defaults 1.5) is used only to estimate the
 * total overtime dollars paid, never the qualified amount.
 * Returns { rows, totals, errors, columns }.
 */
export function splitOvertime(csvText) {
  const raw = parseCSV(csvText);
  if (raw.length < 2) {
    return { rows: [], totals: null, errors: ["Need a header row plus at least one data row."], columns: null };
  }

  const header = raw[0];
  const columns = {};
  header.forEach((cell, idx) => {
    const key = matchHeader(cell);
    if (key && !(key in columns)) columns[key] = idx;
  });

  const missing = ["employee", "rate", "otHours"].filter((k) => !(k in columns));
  if (missing.length) {
    const want = { employee: "employee", rate: "regular_rate", otHours: "ot_hours" };
    return {
      rows: [], totals: null, columns,
      errors: [`Missing column${missing.length > 1 ? "s" : ""}: ${missing.map((m) => want[m]).join(", ")}. Headers can be things like "employee, regular_rate, ot_hours, multiplier".`],
    };
  }

  const rows = [];
  const errors = [];
  raw.slice(1).forEach((r, i) => {
    const line = i + 2;
    const employee = (r[columns.employee] ?? "").trim();
    const rate = num(r[columns.rate]);
    const otHours = num(r[columns.otHours]);
    const multiplier = "multiplier" in columns && String(r[columns.multiplier]).trim() !== ""
      ? num(r[columns.multiplier]) : 1.5;

    if (!employee) { errors.push(`Row ${line}: missing employee name — skipped.`); return; }
    if (!(rate > 0)) { errors.push(`Row ${line} (${employee}): regular rate must be a positive number — skipped.`); return; }
    if (!(otHours >= 0)) { errors.push(`Row ${line} (${employee}): overtime hours must be zero or more — skipped.`); return; }
    if (!(multiplier >= 1.5)) {
      errors.push(`Row ${line} (${employee}): overtime paid below time-and-a-half (x${multiplier}) — FLSA requires at least 1.5x; check this row. Qualified amount still computed at the required half-rate.`);
    }

    const qualified = 0.5 * rate * otHours;              // Box 12 code TT
    const paidEstimate = (Number.isFinite(multiplier) ? multiplier : 1.5) * rate * otHours;
    const nonQualified = Math.max(0, paidEstimate - qualified);

    rows.push({
      employee, rate, otHours,
      multiplier: Number.isFinite(multiplier) ? multiplier : 1.5,
      qualified: round2(qualified),
      paidEstimate: round2(paidEstimate),
      nonQualified: round2(nonQualified),
    });
  });

  const totals = rows.length
    ? {
        otHours: round2(rows.reduce((s, r) => s + r.otHours, 0)),
        qualified: round2(rows.reduce((s, r) => s + r.qualified, 0)),
        paidEstimate: round2(rows.reduce((s, r) => s + r.paidEstimate, 0)),
        nonQualified: round2(rows.reduce((s, r) => s + r.nonQualified, 0)),
      }
    : null;

  return { rows, totals, errors, columns };
}

export function resultToCSV(rows) {
  const out = [[
    "employee", "regular_rate", "ot_hours", "ot_multiplier_paid",
    "qualified_overtime_box12_TT", "total_ot_pay_estimate", "not_qualified_portion",
  ]];
  rows.forEach((r) => out.push([
    r.employee, r.rate, r.otHours, r.multiplier, r.qualified.toFixed(2),
    r.paidEstimate.toFixed(2), r.nonQualified.toFixed(2),
  ]));
  return toCSV(out);
}

const round2 = (n) => Math.round(n * 100) / 100;
