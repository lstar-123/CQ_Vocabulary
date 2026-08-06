// ==================== ANIMATION HELPERS ====================
// rAF-driven count-up and SVG ring animation.
// Both jump instantly when the user prefers reduced motion.

function prefersReducedMotion() {
  return window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
}

function easeOutCubic(t) { return 1 - Math.pow(1 - t, 3); }

/**
 * Animate a number from 0 to `target` inside `el`.
 * @param {HTMLElement} el
 * @param {number}      target
 * @param {object}      [opts] { suffix, duration }
 */
export function countUp(el, target, { suffix = '', duration = 900 } = {}) {
  if (!el) return;
  if (prefersReducedMotion() || !window.requestAnimationFrame || target === 0) {
    el.textContent = target + suffix;
    return;
  }
  const start = performance.now();
  function frame(now) {
    const t = Math.min(1, (now - start) / duration);
    const val = Math.round(easeOutCubic(t) * target);
    el.textContent = val + suffix;
    if (t < 1) requestAnimationFrame(frame);
  }
  requestAnimationFrame(frame);
}

/**
 * Circumference of a circle SVG element (assumes uniform stroke dash).
 * @param {SVGCircleElement} circleEl
 */
export function ringLength(circleEl) {
  return 2 * Math.PI * circleEl.r.baseVal.value;
}

/**
 * Animate an SVG circle's stroke-dashoffset from full to `pct`% of the ring.
 * The element must have stroke-dasharray set via CSS (transition-driven).
 * @param {SVGCircleElement} circleEl
 * @param {number}           pct  0–100
 * @param {object}           [opts] { duration }
 */
export function animateRing(circleEl, pct, { duration = 1100 } = {}) {
  if (!circleEl) return;
  const length = ringLength(circleEl);
  const target = length * (1 - Math.min(100, Math.max(0, pct)) / 100);

  if (prefersReducedMotion()) {
    circleEl.style.strokeDashoffset = String(target);
    return;
  }
  // Two rAFs: let the browser apply the initial offset before the CSS
  // transition on stroke-dashoffset kicks in.
  circleEl.style.strokeDashoffset = String(length);
  requestAnimationFrame(() => requestAnimationFrame(() => {
    circleEl.style.strokeDashoffset = String(target);
  }));
}
