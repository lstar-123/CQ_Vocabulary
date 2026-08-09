// ==================== GROUP SPELLING ====================
import { escapeHtml } from '../utils.js';
import { PlaybackController } from '../playback.js';
import { phonicsCache, ensurePhonicsData } from '../state/phonics.js';
import { createSegmentElement, createHyphenElement } from '../domBuilder.js';
import { GroupLearning } from '../state/groupLearning.js';
import { IS_MOBILE, activateSpellingKeyboard } from './letterKeyboard.js';

export function speakGroupWord(word, targetId) {
  PlaybackController.stop();
  const data = phonicsCache[word];
  if (data && data.syllables) {
    const span = document.getElementById(targetId);
    if (span) {
      const wrapper = document.createElement('span');
      wrapper.className = 'fc-phonics';
      for (const syl of data.syllables) {
        if (!syl.segments) continue;
        for (const seg of syl.segments) wrapper.appendChild(createSegmentElement(seg, true));
        if (syl !== data.syllables[data.syllables.length - 1]) wrapper.appendChild(createHyphenElement());
      }
      span.replaceChildren(wrapper);
    }
  }
  const audio = new Audio('/api/tts?text=' + encodeURIComponent(word) + '&lang=en');
  audio.play().catch(() => {});
  audio.addEventListener('ended', () => {
    const span = document.getElementById(targetId);
    if (span) span.textContent = word;
  });
  audio.addEventListener('error', () => {
    const span = document.getElementById(targetId);
    if (span) span.textContent = word;
  });
  ensurePhonicsData(word);
}

export function startGroupSpelling() {
  const group = GroupLearning.currentGroup;
  if (!group) return;

  GroupLearning.mode = 'spelling';
  GroupLearning.spellingResults = [];
  document.getElementById('groupOverview').style.display = 'none';
  document.getElementById('groupLearningArea').style.display = '';
  document.getElementById('groupLearningPhase').style.display = 'none';
  document.getElementById('groupSpellingPhase').style.display = '';
  document.getElementById('groupResult').style.display = 'none';
  document.getElementById('groupSpellError').textContent = '';

  document.getElementById('groupSpellingInputs').innerHTML = group.words.map((w, i) => `
    <div class="group-spell-item" id="gsi-${i}">
      <span class="gs-index">${i + 1}</span>
      <span class="gs-zh">${escapeHtml(w.chinese)}</span>
      <input type="text" id="gsi-input-${i}" placeholder="输入英文拼写…" autocomplete="off" spellcheck="false" autocorrect="off" autocapitalize="off">
      <span class="gs-result" id="gsi-result-${i}"></span>
    </div>
  `).join('');
  // Anti-prediction: insert zero-width space between characters so
  // the mobile keyboard sees isolated letters instead of words.
  const ZWS = '​';
  const ZWS_RE = new RegExp(ZWS, 'g');
  document.querySelectorAll('#groupSpellingInputs input').forEach(inp => {
    inp.addEventListener('input', function() {
      const cursorWas = inp.selectionStart;
      const before = inp.value.slice(0, cursorWas).replace(ZWS_RE, '');
      const after = inp.value.slice(cursorWas).replace(ZWS_RE, '');
      const clean = before + after;
      let result = '';
      for (const ch of clean) { result += ch + ZWS; }
      inp.value = result;
      inp.setSelectionRange(Math.min(before.length * 2, result.length), Math.min(before.length * 2, result.length));
    });
    // One Backspace = delete one visible char (letter + trailing ZWS)
    inp.addEventListener('keydown', function(e) {
      if (e.key === 'Backspace') {
        const pos = inp.selectionStart;
        if (pos > 0 && inp.value[pos - 1] === ZWS) {
          e.preventDefault();
          inp.value = inp.value.slice(0, pos - 2) + inp.value.slice(pos);
          inp.setSelectionRange(pos - 2, pos - 2);
          inp.dispatchEvent(new Event('input', { bubbles: true }));
        }
      }
    });
  });
  // Mobile: swap the system keyboard for the on-screen letter keyboard so
  // voice-to-text (dictation / Gboard microphone) cannot inject answers.
  // Desktop keeps normal typing on the physical keyboard.
  if (IS_MOBILE) {
    document.querySelectorAll('#groupSpellingInputs input').forEach(inp => {
      inp.setAttribute('readonly', '');
      inp.classList.add('mobile-kb-input');
      inp.addEventListener('click', () => activateSpellingKeyboard(inp));
    });
    const first = document.getElementById('gsi-input-0');
    if (first) activateSpellingKeyboard(first);
  } else {
    document.getElementById('gsi-input-0')?.focus();
  }
}
