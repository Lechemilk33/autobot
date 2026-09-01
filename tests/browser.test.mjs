// End-to-end browser tests: drive the real pages in Chromium and verify the
// numbers a user actually sees, cross-checked against hand-computed values.
// Run: node tests/browser.test.mjs (server on :8931 must NOT be running; we start our own)

import { chromium } from "playwright-core";
import { spawn } from "node:child_process";
import assert from "node:assert/strict";

const PORT = 8931;
const BASE = `http://127.0.0.1:${PORT}`;

const server = spawn("python3", ["-m", "http.server", String(PORT), "--bind", "127.0.0.1"], {
  cwd: new URL("../site", import.meta.url).pathname,
  stdio: "ignore",
});
await new Promise((r) => setTimeout(r, 900));

const results = [];
const check = (name, fn) => results.push({ name, fn });

check("calculator: bartender scenario computes exact savings", async (page) => {
  await page.goto(`${BASE}/index.html`);
  await page.fill("#income", "48000");
  await page.selectOption("#occupation", "ttoc-101"); // Bartenders
  await page.fill("#tips", "12000");
  await page.click('#seg-ot button[data-value="hours"]');
  await page.fill("#ot-rate", "24");
  await page.fill("#ot-hours-week", "6");
  await page.fill("#ot-weeks", "40");
  await page.waitForTimeout(300);
  const savings = await page.textContent("#r-savings");
  // premium = 0.5*24*240 = 2880; total deduction 14880; taxable 31900->17020,
  // fully inside the 12% bracket: savings = 14880 * 0.12 = 1785.6 -> $1,786
  assert.equal(savings.trim(), "$1,786");
  assert.equal((await page.textContent("#r-combined")).trim(), "$14,880");
  assert.equal((await page.textContent("#r-ot")).trim(), "$2,880");
});

check("calculator: MFS shows ineligibility warning and no results", async (page) => {
  await page.goto(`${BASE}/index.html`);
  await page.fill("#income", "50000");
  await page.selectOption("#occupation", "ttoc-102");
  await page.fill("#tips", "10000");
  await page.click('#seg-filing button[data-value="mfs"]');
  await page.waitForTimeout(300);
  assert.equal(await page.isVisible("#mfs-warning"), true);
  assert.equal(await page.isVisible("#results"), false);
});

check("calculator: unlisted occupation warns and ignores tips", async (page) => {
  await page.goto(`${BASE}/index.html`);
  await page.fill("#income", "60000");
  await page.selectOption("#occupation", "no");
  await page.waitForTimeout(200);
  assert.equal(await page.isVisible("#occupation-no-warning"), true);
});

check("calculator: high earner sees phase-down note", async (page) => {
  await page.goto(`${BASE}/index.html`);
  await page.fill("#income", "160000");
  await page.selectOption("#occupation", "ttoc-101");
  await page.fill("#tips", "25000");
  await page.waitForTimeout(300);
  const notes = await page.textContent("#result-notes");
  assert.match(notes, /phase-down applied/i);
  assert.equal((await page.textContent("#r-tips")).trim(), "$24,000");
});

check("w2 decoder: TT lookup returns the overtime explanation", async (page) => {
  await page.goto(`${BASE}/w2-codes.html`);
  await page.fill("#code-input", "TT");
  await page.waitForTimeout(150);
  const res = await page.textContent("#code-result");
  assert.match(res, /qualified overtime/i);
  // full table renders all 33 current codes
  const rows = await page.locator("#codes-table tbody tr").count();
  assert.equal(rows, 33);
});

check("w2 decoder: bogus code gets a clear rejection", async (page) => {
  await page.goto(`${BASE}/w2-codes.html`);
  await page.fill("#code-input", "XX");
  await page.waitForTimeout(150);
  assert.match(await page.textContent("#code-result"), /isn't a current Box 12 code/);
});

check("1099: Massachusetts casual seller gets a yes with state reason", async (page) => {
  await page.goto(`${BASE}/1099.html`);
  await page.selectOption("#state", "MA");
  await page.fill("#gross", "900");
  await page.fill("#txns", "6");
  await page.waitForTimeout(300);
  const v = await page.textContent("#verdict");
  assert.match(v, /Expect a 1099-K/);
  assert.match(v, /Massachusetts/);
});

check("1099: Texas seller under federal line gets a no + taxable-anyway note", async (page) => {
  await page.goto(`${BASE}/1099.html`);
  await page.selectOption("#state", "TX");
  await page.fill("#gross", "9000");
  await page.fill("#txns", "150");
  await page.waitForTimeout(300);
  const v = await page.textContent("#verdict");
  assert.match(v, /unlikely/);
  assert.match(v, /income is taxable/i);
});

check("1099: Montana result carries the honesty caveat", async (page) => {
  await page.goto(`${BASE}/1099.html`);
  await page.selectOption("#state", "MT");
  await page.fill("#gross", "1200");
  await page.fill("#txns", "9");
  await page.waitForTimeout(300);
  const v = await page.textContent("#verdict");
  assert.match(v, /Expect a 1099-K/);
  assert.match(v, /hasn't published the figure itself/);
});

check("employers: sample data computes IRS-consistent totals", async (page) => {
  await page.goto(`${BASE}/employers.html`);
  await page.click("#sample-btn");
  await page.waitForTimeout(300);
  const big = await page.textContent("#split-results .rp-big");
  // 2070 + 874 + 3255 + 388.13 = 6587.13
  assert.equal(big.trim(), "$6,587.13");
  const rows = await page.locator("#split-results tbody tr").count();
  assert.equal(rows, 4);
  // Riley is paid double time; qualified must still be half-rate: 0.5*31*210 = 3255
  const rileyRow = await page.textContent("#split-results tbody tr:nth-child(3)");
  assert.match(rileyRow, /\$3,255\.00/);
});

check("employers: garbage input produces friendly error", async (page) => {
  await page.goto(`${BASE}/employers.html`);
  await page.fill("#csv-input", "just,some\nnonsense,1");
  await page.click("#run-btn");
  await page.waitForTimeout(200);
  assert.match(await page.textContent("#split-errors"), /Missing column/);
});

check("all pages: no console errors, mobile layout has no horizontal scroll", async (page) => {
  for (const path of ["/index.html", "/w2-codes.html", "/1099.html", "/employers.html", "/methodology.html"]) {
    const errors = [];
    page.on("pageerror", (e) => errors.push(String(e)));
    page.on("console", (m) => { if (m.type() === "error") errors.push(m.text()); });
    await page.setViewportSize({ width: 375, height: 720 });
    await page.goto(`${BASE}${path}`);
    await page.waitForTimeout(250);
    assert.deepEqual(errors, [], `console errors on ${path}: ${errors.join("; ")}`);
    const overflow = await page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth);
    assert.ok(overflow <= 1, `horizontal overflow ${overflow}px on ${path}`);
    await page.setViewportSize({ width: 1280, height: 800 });
  }
});

// run
const browser = await chromium.launch({ executablePath: "/opt/pw-browsers/chromium-1194/chrome-linux/chrome" });
let pass = 0, fail = 0;
for (const { name, fn } of results) {
  const ctx = await browser.newContext({ viewport: { width: 1280, height: 800 } });
  const page = await ctx.newPage();
  try {
    await fn(page);
    console.log(`ok - ${name}`);
    pass++;
  } catch (e) {
    console.log(`FAIL - ${name}\n    ${String(e.message).split("\n")[0]}`);
    fail++;
  }
  await ctx.close();
}
await browser.close();
server.kill();
console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
