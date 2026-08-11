// ==================== MVP CELEBRATION ====================
// Full-screen celebration shown when a quiz scores 100%.
// The three mascots (奶龙 / 咕咕嘎嘎 / 噜噜) bounce in and cheer
// in Lottie loops, a golden halo pulses, "PERFECT!" pops in
// letter-by-letter, the score counts up, then golden confetti rains.
//
// Layering (low → high):
//   resultsScreen < .mvp-overlay (z 380) < .confetti-layer (z 400)
//
// No-op when the user prefers reduced motion.

import { burstConfetti } from './confetti.js';

const GOLD_COLORS = ['#F6C343', '#D4A017', '#FFD700', '#FFF3BF', '#C8860D', '#FFE08A'];

const CHARS = [
  { id: 'mvpDragon', file: 'assets/lottie/nailong.json', cls: 'char-center', label: '奶龙' },
  { id: 'mvpChick', file: 'assets/lottie/chick.json', cls: 'char-left', label: '咕咕嘎嘎' },
  { id: 'mvpPig', file: 'assets/lottie/pig.json', cls: 'char-right', label: '噜噜' },
];

function prefersReducedMotion() {
  return window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
}

/**
 * Show the MVP celebration overlay.
 * @param {object} opts { total, correct }
 * @returns {Promise<void>} resolves once the overlay has fully faded out
 */
export function showMvpCelebration({ total, correct }) {
  // Reduced motion: skip the show entirely — the plain results screen
  // (with its own count-ups) is already on stage below the overlay.
  if (prefersReducedMotion()) return Promise.resolve();

  // Clean up any leftover overlay from a previous quiz
  const old = document.querySelector('.mvp-overlay');
  if (old) old.remove();

  const overlay = document.createElement('div');
  overlay.className = 'mvp-overlay';
  overlay.setAttribute('role', 'dialog');
  overlay.setAttribute('aria-label', '满分通关庆祝');
  overlay.innerHTML = `
    <div class="mvp-scrim" aria-hidden="true"></div>
    <div class="mvp-stage">
      <div class="mvp-glow" aria-hidden="true"></div>
      <div class="mvp-halo" aria-hidden="true"></div>
      <h2 class="mvp-title" aria-hidden="true"></h2>
      <div class="mvp-score" aria-hidden="true"><span class="mvp-score-num">0</span><span class="mvp-score-unit">%</span></div>
      <div class="mvp-sub" aria-hidden="true">满分通关 · 全部答对</div>
      <div class="mvp-chars">
        <div class="mvp-char ${CHARS[1].cls}" id="${CHARS[1].id}"></div>
        <div class="mvp-char ${CHARS[0].cls}" id="${CHARS[0].id}"></div>
        <div class="mvp-char ${CHARS[2].cls}" id="${CHARS[2].id}"></div>
      </div>
    </div>
    <button class="mvp-close" aria-label="关闭庆祝动画">×</button>`;
  document.body.appendChild(overlay);

  // ── start the show (next frame so the overlay paints before animating) ──
  requestAnimationFrame(() => {
    overlay.classList.add('is-on');
    overlay.querySelector('.mvp-glow').classList.add('pulse');
    overlay.querySelector('.mvp-halo').classList.add('pulse');
  });

  // ── load the three mascot loops ──
  const animations = [];
  if (window.lottie) {
    CHARS.forEach(c => {
      const el = document.getElementById(c.id);
      if (!el) return;
      try {
        animations.push(window.lottie.loadAnimation({
          container: el,
          renderer: 'svg',
          loop: true,
          autoplay: true,
          path: c.file,
        }));
      } catch (e) { /* overlay still works without the mascot */ }
    });
  }

  // ── "PERFECT!" pops in letter by letter ──
  const title = overlay.querySelector('.mvp-title');
  'PERFECT'.split('').forEach((ch, i) => {
    const s = document.createElement('span');
    s.textContent = ch;
    s.style.animationDelay = (0.9 + i * 0.08) + 's';
    title.appendChild(s);
  });

  // ── score counts up to 100 ──
  const scoreNum = overlay.querySelector('.mvp-score-num');
  setTimeout(() => {
    const t0 = performance.now();
    const DURATION = 900;
    function frame(now) {
      const t = Math.min(1, (now - t0) / DURATION);
      const eased = 1 - Math.pow(1 - t, 3);
      scoreNum.textContent = String(Math.round(eased * 100));
      if (t < 1) requestAnimationFrame(frame);
    }
    requestAnimationFrame(frame);
  }, 850);

  // ── golden confetti burst after the title pops ──
  setTimeout(() => burstConfetti({ count: 150, colors: GOLD_COLORS }), 1500);

  // ── dismiss: click anywhere, Escape, or auto after ~4.6s ──
  let closed = false;
  let resolveFn;
  const done = new Promise(resolve => { resolveFn = resolve; });

  const close = () => {
    if (closed) return;
    closed = true;
    clearTimeout(autoTimer);
    document.removeEventListener('keydown', onKey);
    animations.forEach(a => { try { a.destroy(); } catch (e) {} });
    overlay.classList.remove('is-on');
    setTimeout(() => overlay.remove(), 400);
    setTimeout(resolveFn, 500);
  };
  overlay.addEventListener('click', (e) => {
    if (e.target === overlay || e.target.closest('.mvp-close')) close();
  });
  const onKey = (e) => { if (e.key === 'Escape') close(); };
  document.addEventListener('keydown', onKey);
  const autoTimer = setTimeout(close, 4600);

  return done;
}
