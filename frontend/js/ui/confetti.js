// ==================== CONFETTI ====================
// Hand-rolled CSS confetti burst — no external dependencies.
// No-op when the user prefers reduced motion.

const COLORS = ['#58997A', '#C86F50', '#C8A87A', '#7AB89A', '#E6F2E9'];
const CLEANUP_MS = 3200;

function prefersReducedMotion() {
  return window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
}

/**
 * Fire a burst of confetti pieces from the top of the screen.
 * @param {object} [opts] { count }
 */
export function burstConfetti({ count = 70 } = {}) {
  if (prefersReducedMotion()) return;

  let layer = document.querySelector('.confetti-layer');
  if (!layer) {
    layer = document.createElement('div');
    layer.className = 'confetti-layer';
    layer.setAttribute('aria-hidden', 'true');
    document.body.appendChild(layer);
  }

  const frag = document.createDocumentFragment();
  for (let i = 0; i < count; i++) {
    const piece = document.createElement('span');
    piece.className = 'confetti-piece';
    piece.style.left = Math.random() * 100 + '%';
    piece.style.background = COLORS[i % COLORS.length];
    piece.style.setProperty('--dx', (Math.random() * 240 - 120) + 'px');
    piece.style.setProperty('--rot', (Math.random() * 720 + 360) + 'deg');
    piece.style.animationDelay = Math.random() * 0.35 + 's';
    piece.style.animationDuration = (Math.random() * 1.2 + 1.6) + 's';
    frag.appendChild(piece);
  }
  layer.appendChild(frag);

  setTimeout(() => {
    layer.querySelectorAll('.confetti-piece').forEach(p => p.remove());
    if (layer.children.length === 0) layer.remove();
  }, CLEANUP_MS);
}
