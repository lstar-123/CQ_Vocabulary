// ==================== SOUND FEEDBACK ====================
// Tiny Web Audio API feedback sounds — no audio files, no external deps.
// The AudioContext is created lazily on the first play*() call, which always
// happens inside a user-gesture (submit click) → autoplay-safe.
// All calls are wrapped in try/catch: without Web Audio this is a silent no-op.

const MUTE_KEY = 'soundMuted';

let _ctx = null;

function ensureCtx() {
  if (!_ctx) {
    const AC = window.AudioContext || window.webkitAudioContext;
    if (!AC) return null;
    _ctx = new AC();
  }
  if (_ctx.state === 'suspended') _ctx.resume();
  return _ctx;
}

function tone(ctx, { freq, start, dur, type = 'sine', gain = 0.12 }) {
  const osc = ctx.createOscillator();
  const g = ctx.createGain();
  osc.type = type;
  osc.frequency.setValueAtTime(freq, ctx.currentTime + start);
  g.gain.setValueAtTime(gain, ctx.currentTime + start);
  g.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + start + dur);
  osc.connect(g).connect(ctx.destination);
  osc.start(ctx.currentTime + start);
  osc.stop(ctx.currentTime + start + dur + 0.05);
}

/**
 * Single neutral answer "tick" — played for BOTH correct and wrong answers.
 * Design: the user must not learn the per-word result before the quiz ends,
 * so the sound carries no correctness information. (~120 ms)
 */
export function playAnswerTick() {
  if (isSoundMuted()) return;
  try {
    const ctx = ensureCtx();
    if (!ctx) return;
    tone(ctx, { freq: 660, start: 0, dur: 0.12, type: 'sine', gain: 0.1 });
  } catch (e) { /* no Web Audio — silent no-op */ }
}

/** Muted state, persisted to localStorage. */
export function isSoundMuted() {
  try { return localStorage.getItem(MUTE_KEY) === '1'; } catch (e) { return false; }
}

/** Toggle mute; returns the new muted state. */
export function toggleSoundMute() {
  const muted = !isSoundMuted();
  try { localStorage.setItem(MUTE_KEY, muted ? '1' : '0'); } catch (e) {}
  return muted;
}
