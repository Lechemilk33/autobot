# ShiftMath

Plain-word money math for people who work shifts — live at **https://lechemilk33.github.io/autobot/**

Four free, no-signup tools around the 2025 federal tax law (OBBBA) and the
2025/2026 filing seasons, all running entirely in the browser:

- **Tips & overtime deduction calculator** — what the new deductions (up to
  $25,000 of tips, $12,500/$25,000 of overtime premium) are actually worth,
  with the caps, the FLSA premium-only rule, and the high-income phase-down
  done correctly against real 2025/2026 brackets.
- **W-2 Box 12 decoder** — every current code in plain English, including the
  new 2026 codes TP, TT, TA and Box 14b occupation codes.
- **1099 checker** — federal $20k/200 rule, the $600→$2,000 1099-NEC change,
  and the 11 lower-threshold states, with per-source confidence flagged.
- **Employer overtime splitter** — payroll CSV → per-employee W-2 code TT
  amounts (the qualified FLSA premium), computed locally.

## Structure

- `site/` — the static site (no build step; plain HTML/CSS/ES modules)
- `site/js/tax_data.js`, `form1099.js`, `w2codes.js` — verified data tables
  with source citations in comments
- `tests/` — unit tests pinned to IRS/TaxAct/Fidelity worked examples, plus a
  Playwright end-to-end suite that drives the real pages

## Develop

```
node --test tests/obbba.test.mjs tests/form1099.test.mjs tests/ot_splitter.test.mjs
node tests/browser.test.mjs   # needs Chromium; see PLAYWRIGHT_BROWSERS_PATH
```

Pushing to the deploy branch runs the unit tests in CI and publishes `site/`
to the `gh-pages` branch, which GitHub Pages serves.

## Data maintenance

The numbers that go stale: annual brackets/standard deductions
(`site/js/tax_data.js`), 1099 thresholds and state table
(`site/js/form1099.js`), and estimated-tax dates. Each constant carries the
URL it was verified against. The deductions expire after tax year 2028.
