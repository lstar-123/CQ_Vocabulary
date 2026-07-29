// ==================== GROUP SPELLING ====================
import { escapeHtml } from '../utils.js';
import { PlaybackController } from '../playback.js';
import { phonicsCache, ensurePhonicsData } from '../state/phonics.js';
import { createSegmentElement, createHyphenElement } from '../domBuilder.js';
import { GroupLearning } from '../state/groupLearning.js';

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
      <input type="text" id="gsi-input-${i}" name="spell_${i}" placeholder="输入英文拼写…" autocomplete="nope" spellcheck="false" autocorrect="off" autocapitalize="off" inputmode="text">
      <span class="gs-result" id="gsi-result-${i}"></span>
    </div>
  `).join('');
  document.getElementById('gsi-input-0')?.focus();
}
