// Smoke test for the mobile letter keyboard (frontend/js/study/letterKeyboard.js).
// Simulates an iPhone UA so IS_MOBILE is true, wires up the same ZWS input
// handler groupSpelling.js installs, then exercises insert/backspace/switch.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { JSDOM } from 'jsdom';

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
// The project's frontend JS is browser ESM but the root package.json is
// commonjs — copy to a temp .mjs so Node parses it as a module.
const tmpFile = path.join(scriptDir, 'tmp_letter_keyboard.mjs');
fs.writeFileSync(
  tmpFile,
  fs.readFileSync(
    path.join(scriptDir, '..', 'frontend', 'js', 'study', 'letterKeyboard.js'),
    'utf8',
  ),
);

const dom = new JSDOM(
  `<!DOCTYPE html><html><body>
    <div id="groupSpellingPhase"><div id="groupSpellingInputs">
      <div class="group-spell-item" id="gsi-0"><input type="text" id="gsi-input-0"></div>
      <div class="group-spell-item" id="gsi-1"><input type="text" id="gsi-input-1"></div>
    </div><button id="checkBtn">检查答案</button></div>
  </body></html>`,
  {
    userAgent:
      'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
  },
);

globalThis.window = dom.window;
globalThis.document = dom.window.document;
globalThis.Event = dom.window.Event;
// jsdom lacks matchMedia; stub it as a touch device so IS_MOBILE is true
// (in real browsers matchMedia is always available).
dom.window.matchMedia = (query) => ({
  matches: query.includes('coarse'),
  media: query,
  addListener() {},
  removeListener() {},
  addEventListener() {},
  removeEventListener() {},
  dispatchEvent() { return false; },
});

const mod = await import(pathToFileURL(tmpFile).href);

let failures = 0;
function check(name, cond, extra = '') {
  console.log(`${cond ? 'PASS' : 'FAIL'}  ${name}${extra ? ' — ' + extra : ''}`);
  if (!cond) failures++;
}

check('IS_MOBILE detected via UA', mod.IS_MOBILE === true);

const { document } = window;

const inp0 = document.getElementById('gsi-input-0');
const inp1 = document.getElementById('gsi-input-1');

// Same ZWS rewrite handler groupSpelling.js installs on every input.
const ZWS = '​';
const ZWS_RE = new RegExp(ZWS, 'g');
function installZwsHandler(inp) {
  inp.addEventListener('input', function () {
    const cursorWas = inp.selectionStart;
    const before = inp.value.slice(0, cursorWas).replace(ZWS_RE, '');
    const after = inp.value.slice(cursorWas).replace(ZWS_RE, '');
    const clean = before + after;
    let result = '';
    for (const ch of clean) result += ch + ZWS;
    inp.value = result;
    inp.setSelectionRange(Math.min(before.length * 2, result.length), Math.min(before.length * 2, result.length));
  });
}
installZwsHandler(inp0);
installZwsHandler(inp1);

const click = (el) => el.dispatchEvent(new window.MouseEvent('click', { bubbles: true }));

// ── activate & type C-A-T ──
mod.activateSpellingKeyboard(inp0);
const kb = document.querySelector('.letter-keyboard');
check('keyboard element built lazily', !!kb);
check('keyboard visible after activate', kb.classList.contains('visible'));
check('active input highlighted', document.getElementById('gsi-0').classList.contains('active-input'));

click(kb.querySelector('[data-char="C"]'));
click(kb.querySelector('[data-char="A"]'));
click(kb.querySelector('[data-char="T"]'));
let clean0 = inp0.value.replace(ZWS_RE, '');
check('types "CAT"', clean0 === 'CAT', JSON.stringify(inp0.value));

// ── space ──
click(kb.querySelector('[data-char=" "]'));
clean0 = inp0.value.replace(ZWS_RE, '');
check('types space (phrase support)', clean0 === 'CAT ', JSON.stringify(inp0.value));

// ── backspace removes one visible char (the space) ──
click(kb.querySelector('[data-action="backspace"]'));
clean0 = inp0.value.replace(ZWS_RE, '');
check('backspace removes one char', clean0 === 'CAT', JSON.stringify(inp0.value));

// ── symbols ──
click(kb.querySelector(`[data-char="'"]`));
click(kb.querySelector('[data-char="-"]'));
click(kb.querySelector('[data-char="("]'));
click(kb.querySelector('[data-char=")"]'));
click(kb.querySelector('[data-char="."]'));
click(kb.querySelector('[data-char="/"]'));
clean0 = inp0.value.replace(ZWS_RE, '');
check("symbols ', -, (, ), ., / all insertable", clean0 === "CAT'-()./", JSON.stringify(inp0.value));

// ── ZWS format still canonical (one ZWS after every visible char) ──
const pairs = inp0.value.length;
const vis = inp0.value.replace(ZWS_RE, '').length;
check('ZWS pair format intact (len=2×visible)', pairs === vis * 2, `len=${pairs} vis=${vis}`);

// ── switching active input ──
mod.activateSpellingKeyboard(inp1);
check('highlight moved to second row', document.getElementById('gsi-0').classList.contains('active-input') === false &&
  document.getElementById('gsi-1').classList.contains('active-input') === true);
click(kb.querySelector('[data-char="B"]'));
check('second input receives "B"', inp1.value.replace(ZWS_RE, '') === 'B');
check('first input untouched', inp0.value.replace(ZWS_RE, '') === "CAT'-()./");

// ── readonly wiring lives in groupSpelling.js — verify it is wired ──
const groupSpellingSrc = fs.readFileSync(
  path.join(scriptDir, '..', 'frontend', 'js', 'study', 'groupSpelling.js'),
  'utf8',
);
check(
  'groupSpelling.js sets readonly + activates keyboard on mobile',
  groupSpellingSrc.includes("inp.setAttribute('readonly', '')") &&
    groupSpellingSrc.includes('activateSpellingKeyboard(inp)') &&
    groupSpellingSrc.includes('IS_MOBILE'),
);

// ── hide ──
mod.hideSpellingKeyboard();
check('keyboard hidden after hide', !kb.classList.contains('visible'));
check('highlight cleared after hide', !document.getElementById('gsi-1').classList.contains('active-input'));

// ── Desktop must stay untouched: no keyboard, module inert ──
{
  const desktop = new JSDOM('<html><body><div id="groupSpellingPhase"><input id="gsi-input-0"></div></body></html>');
  // Point the module at the desktop window (jsdom has no matchMedia and the
  // default UA has no Mobile token → IS_MOBILE false).
  const prevWindow = globalThis.window;
  const prevDocument = globalThis.document;
  globalThis.window = desktop.window;
  globalThis.document = desktop.window.document;
  const desktopMod = await import(pathToFileURL(tmpFile).href + '?desktop');
  globalThis.window = prevWindow;
  globalThis.document = prevDocument;
  check('desktop: IS_MOBILE false', desktopMod.IS_MOBILE === false);
  desktopMod.activateSpellingKeyboard(
    desktop.window.document.getElementById('gsi-input-0'),
  );
  check(
    'desktop: no keyboard element created',
    !desktop.window.document.querySelector('.letter-keyboard'),
  );
}

fs.rmSync(tmpFile, { force: true });

console.log(failures === 0 ? '\nALL PASSED' : `\n${failures} FAILURES`);
process.exit(failures === 0 ? 0 : 1);
