// ==================== STUDY PAGE EVENTS ====================
import { DOM } from './dom.js';

export function bindStudyEvents({
  showHome, switchStudyMode,
  speakCurrentCard, prevCard, nextCard,
  selectCardUnit,
  toggleStudyCat, speakWord,
  selectGroupUnit, speakGroupWord, submitGroupSpelling,
  GroupActions,
}) {
  // ── Toolbar ──
  if (DOM.btnBackStudy) DOM.btnBackStudy.addEventListener('click', showHome);
  if (DOM.btnCardMode) DOM.btnCardMode.addEventListener('click', () => switchStudyMode('card'));
  if (DOM.btnListMode) DOM.btnListMode.addEventListener('click', () => switchStudyMode('list'));
  if (DOM.btnGroupMode) DOM.btnGroupMode.addEventListener('click', () => switchStudyMode('group'));

  // ── Flashcard ──
  if (DOM.btnSpeakCard) DOM.btnSpeakCard.addEventListener('click', speakCurrentCard);
  if (DOM.btnPrevCard) DOM.btnPrevCard.addEventListener('click', (e) => prevCard(e));
  if (DOM.btnNextCard) DOM.btnNextCard.addEventListener('click', (e) => nextCard(e));

  // ── Unit filter chips (card mode: single-select radio) ──
  if (DOM.catFilterChips) {
    DOM.catFilterChips.addEventListener('click', (e) => {
      const chip = e.target.closest('.cat-chip');
      if (!chip) return;
      if (chip.id === 'chipSelectAll') selectCardUnit(null);
      else if (chip.dataset.unit) selectCardUnit(parseInt(chip.dataset.unit));
    });
  }

  // ── List mode ──
  if (DOM.studyContent) {
    DOM.studyContent.addEventListener('click', (e) => {
      const hdr = e.target.closest('.study-cat-header[data-cat-id]');
      if (hdr) { toggleStudyCat(hdr.dataset.catId); return; }
      const spk = e.target.closest('.btn-speak-sm[data-word]');
      if (spk) speakWord(spk.dataset.word);
    });
  }

  // ── Group: unit selection ──
  if (DOM.groupUnitOptions) {
    DOM.groupUnitOptions.addEventListener('click', (e) => {
      const card = e.target.closest('.group-unit-card[data-unit]');
      if (card) selectGroupUnit(parseInt(card.dataset.unit), card);
    });
  }

  // ── Group: actions, rounds, speak, spelling ──
  if (DOM.groupActive) {
    DOM.groupActive.addEventListener('click', (e) => {
      const act = e.target.closest('[data-action]');
      if (act && GroupActions[act.dataset.action]) { GroupActions[act.dataset.action](); return; }
      const rc = e.target.closest('.rc-btn[data-round]');
      if (rc) { GroupActions.startRound(parseInt(rc.dataset.round)); return; }
      const spk = e.target.closest('.gw-speak[data-word]');
      if (spk) speakGroupWord(spk.dataset.word, spk.dataset.target);
    });
    DOM.groupActive.addEventListener('keydown', (e) => {
      if (e.key === 'Enter' && e.target.closest('#groupSpellingPhase input')) submitGroupSpelling();
    });
  }
}
