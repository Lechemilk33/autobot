// Employer splitter page controller.
import { $, fmtUSD } from "./ui.js";
import { splitOvertime, resultToCSV } from "./ot_splitter.js";

const input = $("#csv-input");
const errBox = $("#split-errors");
const resBox = $("#split-results");
const drop = $("#drop-zone");

const SAMPLE = `employee,regular_rate,ot_hours,multiplier
Jordan Alvarez,22.50,184,1.5
Sam Okafor,19.00,92,1.5
Riley Chen,31.00,210,2
Morgan Diaz,17.25,45,1.5`;

$("#sample-btn").addEventListener("click", () => {
  input.value = SAMPLE;
  run();
});

$("#run-btn").addEventListener("click", run);

["dragover", "dragenter"].forEach((ev) =>
  drop.addEventListener(ev, (e) => { e.preventDefault(); drop.classList.add("drag"); }));
["dragleave", "drop"].forEach((ev) =>
  drop.addEventListener(ev, (e) => { e.preventDefault(); drop.classList.remove("drag"); }));
drop.addEventListener("drop", (e) => {
  const file = e.dataTransfer?.files?.[0];
  if (!file) return;
  file.text().then((t) => { input.value = t; run(); });
});

let lastRows = null;

function run() {
  const text = input.value.trim();
  errBox.innerHTML = "";
  resBox.innerHTML = "";
  lastRows = null;
  if (!text) return;

  const { rows, totals, errors } = splitOvertime(text);

  if (errors.length) {
    errBox.innerHTML = `<div class="callout ${rows.length ? "warn" : "bad"}"><strong>${rows.length ? "Some rows need attention:" : "Couldn't process that:"}</strong><ul style="margin:8px 0 0 18px; padding:0;">${errors.map((e) => `<li>${e}</li>`).join("")}</ul></div>`;
  }
  if (!rows.length) return;
  lastRows = rows;

  const body = rows.map((r) => `<tr>
      <td>${escapeHtml(r.employee)}</td>
      <td class="num">$${r.rate.toFixed(2)}</td>
      <td class="num">${r.otHours}</td>
      <td class="num">x${r.multiplier}</td>
      <td class="num"><strong>${fmtUSD(r.qualified, true)}</strong></td>
      <td class="num">${fmtUSD(r.paidEstimate, true)}</td>
      <td class="num">${fmtUSD(r.nonQualified, true)}</td>
    </tr>`).join("");

  resBox.innerHTML = `
    <div class="result-panel">
      <div class="rp-label">Total qualified overtime (sum of code TT amounts)</div>
      <div class="rp-big">${fmtUSD(totals.qualified, true)}</div>
      <p class="rp-sub">${rows.length} employee${rows.length === 1 ? "" : "s"} · ${totals.otHours} overtime hours · ${fmtUSD(totals.nonQualified, true)} of overtime pay does <em>not</em> qualify and must stay out of Box 12.</p>
    </div>
    <div class="table-scroll">
      <table>
        <thead><tr><th>Employee</th><th class="num">Regular rate</th><th class="num">OT hours</th><th class="num">Paid at</th><th class="num">Code TT amount</th><th class="num">Total OT pay</th><th class="num">Not qualified</th></tr></thead>
        <tbody>${body}</tbody>
      </table>
    </div>
    <button class="btn" id="download-btn" type="button">Download results as CSV</button>
    <p class="small">The download happens locally — the file is built on your device.</p>
  `;

  $("#download-btn").addEventListener("click", () => {
    const blob = new Blob([resultToCSV(lastRows)], { type: "text/csv" });
    const a = document.createElement("a");
    a.href = URL.createObjectURL(blob);
    a.download = "qualified-overtime-code-TT.csv";
    a.click();
    URL.revokeObjectURL(a.href);
  });
}

function escapeHtml(s) {
  return s.replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
}
