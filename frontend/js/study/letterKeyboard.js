// ==================== MOBILE LETTER KEYBOARD ====================
// Tapping a spelling input on a touch device shows a custom 26-letter +
// symbol keyboard instead of the system one. With no real text input
// available, mobile voice-to-text (iOS dictation / Gboard microphone)
// has no channel to inject answers — the user must tap letters by hand.
//
// Desktop keeps the normal system keyboard and this module is inert.

/** True on touch devices (phones, tablets); desktop is false. */
export const IS_MOBILE =
  typeof window !== 'undefined' &&
  ((typeof window.matchMedia === 'function' &&
    window.matchMedia('(pointer: coarse)').matches) ||
    /Android|iPhone|iPad|iPod|Mobile/i.test(navigator.userAgent));

// Zero-width space — same value/format as groupSpelling.js. One ZWS is
// inserted after every visible character so the old keyboard-based
// anti-prediction rewrite logic stays compatible.
const ZWS = '​';
const ZWS_RE = new RegExp(ZWS, 'g');

const KEYS_ROW1 = ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'];
const KEYS_ROW2 = ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'];
const KEYS_ROW3 = ['Z', 'X', 'C', 'V', 'B', 'N', 'M'];
const KEYS_SYMBOLS = ['(', ')', "'", '-', '.', '/'];

const BACKSPACE_SVG =
  '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M21 4H8l-7 8 7 8h13a2 2 0 0 0 2-2V6a2 2 0 0 0-2-2Z"/><line x1="18" y1="9" x2="12" y2="15"/><line x1="12" y1="9" x2="18" y2="15"/></svg>';

let kbEl = null;      // root keyboard element (built lazily, appended to body)
let activeInput = null;
let phaseEl = null;   // #groupSpellingPhase — gets bottom padding while open

function buildKeyboard() {
  kbEl = document.createElement('div');
  kbEl.className = 'letter-keyboard';

  const key = (char, extra = '') =>
    `<div class="lk-key${extra}" data-char="${char}">${char}</div>`;
  const actionKey = (action, inner, extra = '') =>
    `<div class="lk-key${extra}" data-action="${action}">${inner}</div>`;

  const row = (keys) =>
    `<div class="lk-row">${keys.map((k) => key(k)).join('')}</div>`;

  kbEl.innerHTML =
    row(KEYS_ROW1) +
    row(KEYS_ROW2) +
    `<div class="lk-row">${KEYS_ROW3.map((k) => key(k)).join('')}${actionKey(
      'backspace',
      BACKSPACE_SVG,
      ' lk-backspace',
    )}</div>` +
    `<div class="lk-row">${KEYS_SYMBOLS.map((k) => key(k)).join('')}${key(
      ' ',
      ' lk-space',
    )}</div>`;

  // One delegated listener for every key.
  kbEl.addEventListener('click', (e) => {
    const keyEl = e.target.closest('.lk-key');
    if (!keyEl || !activeInput) return;
    if (keyEl.dataset.action === 'backspace') {
      backspace();
    } else if (keyEl.dataset.char !== undefined) {
      insertChar(keyEl.dataset.char);
    }
  });

  document.body.appendChild(kbEl);
}

/** Make [input] the active spelling field and show the letter keyboard. */
export function activateSpellingKeyboard(input) {
  if (!IS_MOBILE) return;
  if (!kbEl) buildKeyboard();

  activeInput = input;
  phaseEl = document.getElementById('groupSpellingPhase');

  // Focus the readonly field — cursor lands where the user tapped but the
  // system keyboard never opens.
  input.focus();

  // Highlight the active row so the user knows which word is being typed.
  document
    .querySelectorAll('.group-spell-item.active-input')
    .forEach((el) => el.classList.remove('active-input'));
  const item = input.closest('.group-spell-item');
  if (item) item.classList.add('active-input');

  kbEl.classList.add('visible');
  if (phaseEl) phaseEl.classList.add('kb-open');
}

/** Hide the letter keyboard (no active field). */
export function hideSpellingKeyboard() {
  if (kbEl) kbEl.classList.remove('visible');
  if (phaseEl) phaseEl.classList.remove('kb-open');
  if (activeInput) {
    const item = activeInput.closest('.group-spell-item');
    if (item) item.classList.remove('active-input');
  }
  activeInput = null;
}

// ── Editing helpers ────────────────────────────────────────────
// Values are stored as "char + ZWS" pairs (see groupSpelling.js), so
// editing goes through the clean text and re-encodes afterwards.

function insertChar(char) {
  const inp = activeInput;
  const pos = inp.selectionStart ?? inp.value.length;
  const before = inp.value.slice(0, pos).replace(ZWS_RE, '');
  const after = inp.value.slice(pos).replace(ZWS_RE, '');
  inp.value = before + char + ZWS + after;
  const newPos = (before + char).length * 2;
  inp.setSelectionRange(newPos, newPos);
  // Re-run the original input handler so the ZWS format stays canonical.
  inp.dispatchEvent(new Event('input', { bubbles: true }));
}

function backspace() {
  const inp = activeInput;
  const pos = inp.selectionStart ?? inp.value.length;
  if (pos <= 0) return;
  // One tap deletes one visible char: the char itself plus its trailing ZWS.
  let start = pos;
  if (inp.value[start - 1] === ZWS) start -= 2;
  else start -= 1;
  inp.value = inp.value.slice(0, start) + inp.value.slice(pos);
  inp.setSelectionRange(start, start);
  inp.dispatchEvent(new Event('input', { bubbles: true }));
}
