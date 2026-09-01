// Shared UI helpers for ShiftMath pages.

export function $(sel, root = document) { return root.querySelector(sel); }
export function $all(sel, root = document) { return [...root.querySelectorAll(sel)]; }

export const fmtUSD = (n, cents = false) =>
  n.toLocaleString("en-US", {
    style: "currency",
    currency: "USD",
    minimumFractionDigits: cents ? 2 : 0,
    maximumFractionDigits: cents ? 2 : 0,
  });

export const fmtPct = (n, digits = 0) => `${(n * 100).toFixed(digits)}%`;

// Parse a currency-ish input value ("1,250.50" -> 1250.5). Empty -> 0.
export function moneyVal(input) {
  const raw = String(input.value ?? "").replace(/[$,\s]/g, "");
  const n = parseFloat(raw);
  return Number.isFinite(n) && n >= 0 ? n : 0;
}

// Segmented control: container with buttons carrying data-value.
// onChange(value) fires on click; returns { get, set }.
export function segControl(el, onChange) {
  const buttons = $all("button", el);
  let value = buttons.find((b) => b.getAttribute("aria-pressed") === "true")?.dataset.value
    ?? buttons[0]?.dataset.value;
  const render = () =>
    buttons.forEach((b) => b.setAttribute("aria-pressed", String(b.dataset.value === value)));
  buttons.forEach((b) =>
    b.addEventListener("click", () => {
      value = b.dataset.value;
      render();
      onChange?.(value);
    })
  );
  render();
  return {
    get: () => value,
    set: (v) => { value = v; render(); },
  };
}

// Debounce for input events.
export function debounce(fn, ms = 150) {
  let t;
  return (...args) => {
    clearTimeout(t);
    t = setTimeout(() => fn(...args), ms);
  };
}
