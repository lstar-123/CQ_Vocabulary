// ==================== UTILITY FUNCTIONS ====================
// Migrated verbatim from quiz.html — no logic changes.

/** HTML-escape a string using a DOM div. */
export function escapeHtml(s) { const d = document.createElement('div'); d.textContent = s; return d.innerHTML; }

/** Format seconds to Chinese-readable duration string. */
export function formatDuration(totalSeconds) {
  if (totalSeconds == null) return '—';
  const mins = Math.floor(totalSeconds / 60);
  const secs = totalSeconds % 60;
  return mins > 0 ? `${mins}分${secs}秒` : `${secs}秒`;
}

/** Format milliseconds to mm:ss (group-learning timing). */
export function formatDurationMs(ms) {
  if (!ms || ms < 0) return '00:00';
  const totalSec = Math.floor(ms / 1000);
  const min = Math.floor(totalSec / 60);
  const sec = totalSec % 60;
  return String(min).padStart(2, '0') + ':' + String(sec).padStart(2, '0');
}

/** Normalize: trim, collapse whitespace, lowercase. */
export function normalize(s) { return s.trim().replace(/\s+/g, ' ').toLowerCase(); }

/** Check if user answer matches any slash-delimited correct answer. */
export function checkEquivalent(userAns, correctAns) {
  const u = normalize(userAns);
  return correctAns.split('/').map(v => normalize(v)).some(v => u === v);
}

/** Fisher-Yates shuffle — returns a NEW array, never mutates input. */
export function shuffleArray(arr) {
  const a = arr.slice();
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}
