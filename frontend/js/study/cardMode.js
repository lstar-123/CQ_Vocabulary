// ==================== CARD MODE ====================
import { PlaybackController } from '../playback.js';
import { getCardWords, setCardWords, getCardIndex, setCardIndex, resetCardIndex, nextShowCardGeneration, getActiveCardId, setActiveCardId } from '../state/cardState.js';
import { getFilteredWords, updateStudyToolbarInfo } from './unitFilter.js';
import { renderPlainWord } from '../render/phonicsRender.js';
import { ensurePhonicsData } from '../state/phonics.js';
import { escapeHtml } from '../utils.js';
import { icon } from '../ui/icons.js';

export function buildCardMode({ allWordsGrouped, allUnits }) {
  PlaybackController.destroy();
  setCardWords(getFilteredWords(allWordsGrouped));
  resetCardIndex();
  updateStudyToolbarInfo(allUnits, allWordsGrouped);
  showCard();
}

export function showCard() {
  // Kill any in-flight playback BEFORE touching the card
  PlaybackController.stop();

  const myGeneration = nextShowCardGeneration();

  const btnSpeak = document.getElementById('btnSpeakCard');
  const divider = document.querySelector('#flashcard .fc-divider');
  const nav = document.querySelector('.flashcard-nav');
  const fcCat = document.getElementById('fcCat');
  const fcEnMain = document.getElementById('fcEnMain');
  const fcZhSub = document.getElementById('fcZhSub');
  const fcCounter = document.getElementById('fcCounter');
  const sylBar = document.getElementById('fcSylBar');

  if (sylBar) sylBar.style.display = 'none';

  if (getCardWords().length === 0) {
    setActiveCardId(null);
    btnSpeak.style.display = 'none';
    if (divider) divider.style.display = 'none';
    if (nav) nav.style.visibility = 'hidden';
    fcCat.textContent = '';
    fcEnMain.innerHTML = `<span class="fc-empty-emoji">${icon('book', 56)}</span>`;
    fcZhSub.innerHTML = '<span class="fc-empty-text">暂无词汇数据</span><br><span class="fc-empty-hint">请先选择词书并添加词汇<br>让词汇在脑海中生根发芽</span>';
    fcCounter.textContent = '';
    return;
  }

  btnSpeak.style.display = '';
  if (divider) divider.style.display = '';
  if (nav) nav.style.visibility = '';
  const w = getCardWords()[getCardIndex()];
  setActiveCardId(`${myGeneration}:${getCardIndex()}:${w.english}`);
  fcCat.innerHTML = `${icon('book', 13)} ${escapeHtml(w.unit_name)}`;
  fcZhSub.textContent = w.chinese;
  fcCounter.textContent = `${getCardIndex() + 1} / ${getCardWords().length}`;

  // Render plain word — default state is always plain black text
  renderPlainWord(w.english);

  // Background preload phonics data for instant playback (NEVER await — NEVER block UI)
  ensurePhonicsData(w.english);
}

export function nextCard(e) {
  if (e) e.stopPropagation();
  if (getCardWords().length === 0) return;
  PlaybackController.stop();  // stop + restore current word BEFORE changing index
  setCardIndex((getCardIndex() + 1) % getCardWords().length);
  showCard();
}

export function prevCard(e) {
  if (e) e.stopPropagation();
  if (getCardWords().length === 0) return;
  PlaybackController.stop();  // stop + restore current word BEFORE changing index
  setCardIndex((getCardIndex() - 1 + getCardWords().length) % getCardWords().length);
  showCard();
}

export function speakCurrentCard() {
  if (getCardWords().length === 0 || getCardIndex() >= getCardWords().length) return;
  if (!getActiveCardId()) return;
  const word = getCardWords()[getCardIndex()].english;
  // All conditions handled by PlaybackController.play():
  //   - stops previous playback
  //   - renders syllable view if cached
  //   - plays audio immediately
  //   - background-loads phonics data if not cached
  PlaybackController.play(word, getActiveCardId());
}
