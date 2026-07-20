// ==================== DOM BUILDER ====================
// Factory functions — ZERO colour knowledge.  All colours live in CSS variables.

/** Create a <span> for one grapheme segment.
 *  @param {object}  segment  { text, silent }
 *  @param {boolean} playing  true → fc-playing / fc-playing-silent; false → fc-normal */
export function createSegmentElement(segment, playing) {
  const span = document.createElement('span');
  span.textContent = segment.text;
  span.className = playing
    ? (segment.silent ? 'fc-playing-silent' : 'fc-playing')
    : 'fc-normal';
  return span;
}

/** Create a syllable-boundary hyphen <span class="fc-hyphen">-</span>. */
export function createHyphenElement() {
  const span = document.createElement('span');
  span.textContent = '-';
  span.className = 'fc-hyphen';
  return span;
}

/** Simple TTS-only playback for list mode (no phonics display). */
export function speakWord(text) {
  const a = new Audio('/api/tts?text=' + encodeURIComponent(text) + '&lang=en');
  a.play().catch(() => {});
}
