// ==================== RENDER WORD (single unified render path) ====================
// Every word display — plain or syllable — goes through this function.
//   showSyllables: false → plain black word  (idle / ended / fallback)
//   showSyllables: true  → colour-coded syllables (playing)
//
// Uses only document.createElement + replaceChildren — ZERO innerHTML, ZERO string
// concatenation.  Safe by construction.

import { createSegmentElement, createHyphenElement } from '../domBuilder.js';
import { phonicsCache } from '../state/phonics.js';

function renderWord(word, data, options = {}) {
  const container = document.getElementById('fcEnMain');
  if (!container) return;

  if (!options.showSyllables || !data || !data.syllables) {
    // ---- Plain word -------------------------------------------------
    const span = document.createElement('span');
    span.textContent = word;
    span.className = 'fc-normal';
    container.replaceChildren(span);
    return;
  }

  // ---- Syllable view ------------------------------------------------
  const wrapper = document.createElement('span');
  wrapper.className = 'fc-phonics';

  for (let si = 0; si < data.syllables.length; si++) {
    const syl = data.syllables[si];
    if (!syl.segments) continue;
    for (const seg of syl.segments) {
      wrapper.appendChild(createSegmentElement(seg, true));
    }
    if (si < data.syllables.length - 1) {
      wrapper.appendChild(createHyphenElement());
    }
  }

  container.replaceChildren(wrapper);
}

// ---- Public API (thin wrappers — keep existing signatures) ----------

/**
 * Render the word in PLAYING mode.
 * This is the ONLY function that decides how phonics data maps to the
 * playing visual state.  PlaybackController calls this and knows NOTHING
 * about syllables / segments / silent / stress — those are all private
 * to the render layer.
 */
export function renderPlayingWord(word) {
  const data = phonicsCache[word];
  if (data && data.syllables) {
    renderSyllableWord(word, data);
  }
  // No data (yet) → keep current display (plain word from showCard).
  // Next tap will hit the cache.
}

export function renderPlainWord(word) {
  renderWord(word, null, { showSyllables: false });
}

function renderSyllableWord(word, data) {
  renderWord(word, data, { showSyllables: true });
}
