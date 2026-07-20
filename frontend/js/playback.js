// ==================== PLAYBACK CONTROLLER ====================
// SINGLE SOURCE OF TRUTH for all audio playback state.
//
// Only PlaybackController may modify the word display (fcEnMain) during
// playback.  External code must NOT call renderSyllableWord /
// renderPlainWord for the flashcard — all UI updates go through
// PlaybackController or showCard() (only when idle).
//
// Design guarantees:
//   1. Exactly one playback state at any time (state: idle|playing|stopped)
//   2. Every async callback is guarded by playId + cardId + word — stale
//      callbacks are silently dropped, never touching the DOM
//   3. All Audio event listeners are explicitly removed → no memory leaks
//   4. play() never awaits — it renders immediately (cache hit) or keeps the
//      current display (cache miss) while audio plays; phonics data is loaded
//      in background for the next tap

import { getCardWords, getCardIndex, getActiveCardId } from './state/cardState.js';
import { renderPlayingWord, renderPlainWord } from './render/phonicsRender.js';
import { ensurePhonicsData } from './state/phonics.js';

export const PlaybackController = {
  // ---- State (single source of truth) ----
  state: 'idle',           // 'idle' | 'playing' | 'stopped'
  currentAudio: null,      // HTMLAudioElement | null
  currentPlayId: 0,        // monotonic — incremented on every play / stop
  currentWord: null,       // word currently being played (string)
  currentCardId: null,     // card identity at the moment play() was called
  _currentHandler: null,   // event-handler reference for removeEventListener

  // ========== PUBLIC API ==========

  /**
   * Start playback for `word` on card `cardId`.
   *
   * Flow:
   *   stop() → state=playing → renderSyllableWord (if cached) → play audio
   *
   * NEVER awaits — renders immediately when phonics data is cached, otherwise
   * keeps the current display.  Phonics data is loaded in background for the
   * next tap.
   */
  play(word, cardId) {
    // 1. Tear down any previous playback (no DOM change)
    this._internalStop();

    // 2. Transition to playing
    this.state = 'playing';
    const playId = ++this.currentPlayId;
    this.currentWord = word;
    this.currentCardId = cardId;

    // 3. Render playing view — all phonics logic delegated to render layer
    if (this._guard(playId, cardId, word)) {
      renderPlayingWord(word);
    }

    // 4. Create Audio element and bind UNIFIED event handler
    const audio = new Audio('/api/tts?text=' + encodeURIComponent(word) + '&lang=en');
    this.currentAudio = audio;

    const handler = (e) => this._handleEvent(e, playId, cardId, word);
    this._currentHandler = handler;
    audio.addEventListener('ended', handler);
    audio.addEventListener('pause', handler);
    audio.addEventListener('error', handler);
    audio.addEventListener('abort', handler);
    audio.addEventListener('loadedmetadata', handler);
    audio.addEventListener('play', handler);

    // 5. Fire-and-forget playback — errors handled in catch + 'error' event
    audio.play().catch((err) => {
      if (this._guard(playId, cardId, word)) {
        this._handleEvent({ type: 'error', error: err }, playId, cardId, word);
      }
    });

    // 6. Background preload phonics data for next playback (never await)
    ensurePhonicsData(word); // fire and forget (no-ops when already cached)
  },

  /**
   * Stop playback and restore the normal word display.
   * Idempotent — safe to call at any time, even when idle.
   */
  stop() {
    if (this.state === 'idle') return;
    this._internalStop();

    const word = this.currentWord;
    // Only restore if the card hasn't changed since playback started
    if (word && this._cardStillShows(word)) {
      renderPlainWord(word);
    }
    this.currentWord = null;
    this.currentCardId = null;
    this.state = 'idle';
  },

  /**
   * Full teardown — call when leaving card mode or the study tab entirely.
   * Stops playback, releases all resources, resets all state.
   */
  destroy() {
    this.stop();
    this.currentWord = null;
    this.currentCardId = null;
    this.state = 'idle';
  },

  // ========== INTERNAL METHODS ==========

  /**
   * Internal stop: release audio resources WITHOUT touching the DOM.
   * Removes ALL event listeners, pauses the audio, clears src, nulls
   * the reference, and increments playId so EVERY pending callback is
   * invalidated.
   */
  _internalStop() {
    this._releaseAudio();
    this.currentPlayId++;
    this.state = 'stopped';
  },

  /**
   * Release audio resources: remove all 6 event listeners, pause,
   * clear src (releases decoder), null the reference and handler.
   * Safe to call even when no audio is active.
   */
  _releaseAudio() {
    const audio = this.currentAudio;
    const handler = this._currentHandler;
    if (audio && handler) {
      audio.removeEventListener('ended', handler);
      audio.removeEventListener('pause', handler);
      audio.removeEventListener('error', handler);
      audio.removeEventListener('abort', handler);
      audio.removeEventListener('loadedmetadata', handler);
      audio.removeEventListener('play', handler);
    }
    if (audio) {
      audio.pause();
      audio.src = '';  // release browser decoder resources
    }
    this.currentAudio = null;
    this._currentHandler = null;
  },

  /**
   * UNIFIED event handler for ALL Audio events.
   * Only 'ended', 'error', 'abort', and external 'pause' trigger cleanup.
   * 'loadedmetadata' and 'play' are informational only.
   */
  _handleEvent(event, playId, cardId, word) {
    if (!this._guard(playId, cardId, word)) return;

    switch (event.type) {
      case 'ended':
      case 'error':
      case 'abort':
        this._finishPlayback(playId);
        break;
      case 'pause':
        // External pause (e.g. user paused via browser controls).
        // Our own _internalStop removes listeners BEFORE pausing, so this
        // only fires for genuine external pauses — treat as end of playback.
        this._finishPlayback(playId);
        break;
      case 'loadedmetadata':
      case 'play':
        // Informational only — no action needed
        break;
    }
  },

  /**
   * Safety guard — the caller may touch the DOM ONLY when this returns true.
   *
   * Checks (in order):
   *   1. playId matches the current playback session
   *   2. cardId matches the card that initiated playback
   *   3. word matches currentWord
   *   4. The current card still shows this word (cardWords[cardIndex])
   *   5. The target DOM element (fcEnMain) still exists
   *
   * ANY mismatch → return false → caller MUST abort.
   */
  _guard(playId, cardId, word) {
    if (playId !== this.currentPlayId) return false;
    if (cardId !== this.currentCardId) return false;
    if (word !== this.currentWord) return false;
    if (!this._cardStillShows(word)) return false;
    if (!document.getElementById('fcEnMain')) return false;
    return true;
  },

  /**
   * Returns true when the currently displayed card still shows `word`.
   */
  _cardStillShows(word) {
    return getCardWords().length > 0 &&
           getCardIndex() < getCardWords().length &&
           getCardWords()[getCardIndex()].english === word;
  },

  /**
   * Finish playback naturally: release audio, restore normal word, set idle.
   * Guarded by playId and state to prevent double execution.
   */
  _finishPlayback(playId) {
    if (playId !== this.currentPlayId) return;
    if (this.state === 'idle') return;  // already finished

    const word = this.currentWord;
    this._releaseAudio();

    if (word && this._cardStillShows(word)) {
      renderPlainWord(word);
    }
    this.currentWord = null;
    this.currentCardId = null;
    this.state = 'idle';
  }
};
