// ==================== QUIZ SCREEN ====================
import { escapeHtml, checkEquivalent, formatDuration } from '../utils.js';
import { apiFetch } from '../api.js';
import { setQuizStartTime, startTimer, stopTimer, getElapsedSeconds } from '../state/quizTimer.js';
import { QuizState } from '../state/quizState.js';
import { currentUser } from '../state/auth.js';
import { showToast } from '../ui/toast.js';
import { showConfirm, isModalOpen } from '../ui/confirm.js';
import { playAnswerTick } from '../ui/sound.js';
import { countUp, animateRing } from '../ui/anim.js';
import { burstConfetti } from '../ui/confetti.js';
import { showMvpCelebration } from '../ui/mvpCelebration.js';
import { icon } from '../ui/icons.js';

export function createQuizScreen({ allUnits, selectedUnitIds }) {

  let _retestCallback = null;

  // ── Answer feedback ────────────────────────────────────────────
  // Per the product decision: submitting an answer advances to the next
  // question immediately — the correct word and per-word result are
  // deliberately NOT shown during the quiz (they appear on the final
  // results screen). Sound + screen-reader announcement still play.
  function _cancelFeedback() {
    // Kept for API compatibility with quiz.html exit paths — nothing to do.
  }

  function startRetestQuiz(wrongAnswers) {
    if (!wrongAnswers || wrongAnswers.length === 0) return;
    _cancelFeedback();
    // Build minimal word objects for the quiz
    const words = wrongAnswers.map(a => ({
      id: a.word_id || 0,
      chinese: a.chinese || '',
      english: a.english || '',
      unit_name: '',
    }));
    QuizState.quizWords = words;
    QuizState.currentIndex = 0;
    QuizState.results = [];
    QuizState.isRetest = true;
    setQuizStartTime(Date.now());
    document.getElementById('selectScreen').style.display = 'none';
    document.getElementById('quizScreen').style.display = 'block';
    document.getElementById('resultsScreen').style.display = 'none';
    document.getElementById('statsScreen').style.display = 'none';
    document.getElementById('unitTag').textContent = 'Retest (' + words.length + ' words)';
    _setupAntiPrediction();
    showQuestion();
  }

  async function startQuiz() {
    if (selectedUnitIds.size === 0) return;
    const book = currentUser.current_book;
    const ids = Array.from(selectedUnitIds).join(',');
    const words = await apiFetch(`/api/words?unit_ids=${ids}&book_schema=${book}&random=1`);
    if (words.length === 0) { showToast('所选单元没有词汇数据', { type: 'error' }); return; }
    QuizState.quizWords = words;
    const names = allUnits.filter(u => selectedUnitIds.has(u.id)).map(u => u.name);
    QuizState.currentIndex = 0;
    QuizState.results = [];
    setQuizStartTime(Date.now());
    document.getElementById('selectScreen').style.display = 'none';
    document.getElementById('quizScreen').style.display = 'block';
    document.getElementById('resultsScreen').style.display = 'none';
    document.getElementById('unitTag').textContent = names.join(', ');
    _setupAntiPrediction();
    showQuestion();
  }

  // ── Anti-prediction via zero-width spaces ──────────────────
  // Insert ​ between characters so the keyboard sees isolated
  // letters instead of words — prevents prediction bar on mobile.
  // The ZWS chars are invisible; stripped on submit.

  const ZWS = '​';
  const ZWS_RE = new RegExp(ZWS, 'g');

  function _reinsertZWS(input) {
    const cursorWas = input.selectionStart;
    const before = input.value.slice(0, cursorWas).replace(ZWS_RE, '');
    const after  = input.value.slice(cursorWas).replace(ZWS_RE, '');
    const clean  = before + after;
    let result = '';
    for (const ch of clean) { result += ch + ZWS; }
    input.value = result;
    const newCursor = Math.min(before.length * 2, result.length);
    input.setSelectionRange(newCursor, newCursor);
  }

  function _setupAntiPrediction() {
    const input = document.getElementById('answerInput');
    if (input._antiPredictionSetup) return;
    input._antiPredictionSetup = true;

    input.addEventListener('input', function() { _reinsertZWS(input); });

    // One Backspace = delete one visible char (letter + its trailing ZWS)
    input.addEventListener('keydown', function(e) {
      if (isModalOpen()) return;   // confirm modal open — never submit
      if (e.key === 'Backspace') {
        const pos = input.selectionStart;
        if (pos > 0 && input.value[pos - 1] === ZWS) {
          e.preventDefault();
          const before = input.value.slice(0, pos - 2);
          const after = input.value.slice(pos);
          input.value = before + after;
          input.setSelectionRange(pos - 2, pos - 2);
          input.dispatchEvent(new Event('input', { bubbles: true }));
        }
      } else if (e.key === 'Enter') {
        e.preventDefault();
        submitAnswer();
      }
    });
  }

  function _cleanInput(input) {
    return input.value.replace(ZWS_RE, '');
  }

  function showQuestion() {
    if (QuizState.currentIndex >= QuizState.quizWords.length) { showResults(); return; }
    const w = QuizState.quizWords[QuizState.currentIndex];
    document.getElementById('wordZh').textContent = w.chinese;
    document.getElementById('wordHint').textContent = '请输入对应的英文翻译';
    document.getElementById('counter').textContent = `${QuizState.currentIndex + 1} / ${QuizState.quizWords.length}`;
    document.getElementById('progressFill').style.width = `${(QuizState.currentIndex / QuizState.quizWords.length) * 100}%`;
    const input = document.getElementById('answerInput');
    input.value = '';
    input.focus();
    startTimer();

    // Light fade/slide on each new question
    const card = document.querySelector('#quizScreen .card');
    if (card) {
      card.classList.remove('question-in');
      void card.offsetWidth;   // reflow — restart the animation
      card.classList.add('question-in');
    }
  }

  function submitAnswer() {
    const input = document.getElementById('answerInput');
    const userAnswer = _cleanInput(input).trim();
    if (!userAnswer) return;
    const w = QuizState.quizWords[QuizState.currentIndex];
    const isCorrect = checkEquivalent(userAnswer, w.english);
    QuizState.results.push({ word_id: w.id, word: w, userAnswer, isCorrect });

    // Feedback: a single neutral tick (identical for correct/wrong — the
    // result must stay hidden until the quiz ends) + screen-reader
    // announcement only — advance at once.
    playAnswerTick();
    const ariaLive = document.getElementById('quizAriaLive');
    if (ariaLive) {
      ariaLive.textContent = isCorrect
        ? `第 ${QuizState.currentIndex + 1} 题回答正确`
        : `第 ${QuizState.currentIndex + 1} 题回答错误`;
    }

    QuizState.currentIndex++;
    if (QuizState.currentIndex < QuizState.quizWords.length) { showQuestion(); }
    else { showResults(); }
  }

  async function showResults() {
    stopTimer();
    document.getElementById('quizScreen').style.display = 'none';
    document.getElementById('resultsScreen').style.display = 'block';
    const total = QuizState.results.length;
    const correct = QuizState.results.filter(r => r.isCorrect).length;
    const wrong = total - correct;
    const accuracy = total > 0 ? Math.round((correct / total) * 100) : 0;
    const dur = getElapsedSeconds();
    if (!QuizState.isRetest) {
      try {
        await apiFetch('/api/quiz/submit', { method:'POST', body: JSON.stringify({
          unit_ids: Array.from(selectedUnitIds), duration_seconds: dur, book_schema: currentUser.current_book,
          answers: QuizState.results.map(r => ({ word_id: r.word_id, user_answer: r.userAnswer, is_correct: r.isCorrect }))
        })});
      } catch(e) { console.error('Failed to save quiz result:', e); }
    }
    const sc = document.getElementById('scoreCircle');
    const color = accuracy >= 90 ? '#58997A' : accuracy >= 70 ? '#7AB89A' : accuracy >= 50 ? '#C8A87A' : '#C86F50';
    sc.style.background = color;
    sc.textContent = '0%';

    // Animate the score ring + count-up, confetti on high scores,
    // and a full MVP celebration show on a perfect 100% (mascots + gold).
    const ring = document.getElementById('scoreRingProgress');
    if (ring) animateRing(ring, accuracy);
    countUp(sc, accuracy, { suffix: '%', duration: 1000 });
    if (accuracy >= 100) {
      showMvpCelebration({ total, correct });
    } else if (accuracy >= 90) {
      burstConfetti();
    }

    const title = document.getElementById('resultTitle'), sub = document.getElementById('resultSub');
    if (accuracy >= 95) { title.textContent = '太棒了！'; sub.textContent = '你几乎全部掌握，继续保持！'; }
    else if (accuracy >= 80) { title.textContent = '非常优秀！'; sub.textContent = '你已经掌握了大部分高频词汇。'; }
    else if (accuracy >= 60) { title.textContent = '继续加油！'; sub.textContent = '已经过半，再多练练就能突破。'; }
    else { title.textContent = '需要努力！'; sub.textContent = '建议反复记忆这些词汇。'; }
    document.getElementById('totalCount').textContent = 0;
    document.getElementById('correctCount').textContent = 0;
    document.getElementById('wrongCount').textContent = 0;
    countUp(document.getElementById('totalCount'), total, { duration: 800 });
    countUp(document.getElementById('correctCount'), correct, { duration: 800 });
    countUp(document.getElementById('wrongCount'), wrong, { duration: 800 });
    document.getElementById('resultSub').textContent += ` · 用时 ${formatDuration(dur)}`;
    document.getElementById('detailTitle').textContent = `全部答题详情（共 ${total} 题）`;
    document.getElementById('detailBody').innerHTML = QuizState.results.map((r,i) => `
      <tr><td>${i+1}</td><td class="zh" style="font-size:13px;">${escapeHtml(r.word.chinese)} <span style="color:#8C8C8C;font-weight:400;font-size:11px;">[${escapeHtml(r.word.unit_name)}]</span></td>
      <td class="${r.isCorrect?'correct-ans':'user-ans'}">${escapeHtml(r.userAnswer)}</td>
      <td class="correct-ans">${escapeHtml(r.word.english)}</td>
      <td class="icon">${icon(r.isCorrect ? 'check' : 'x', 15)}</td></tr>`).join('');

    // Retest mode: change restart button
    if (QuizState.isRetest) {
      const btnRestart = document.getElementById('btnRestart');
      btnRestart.textContent = '完成 / 返回记录';
      btnRestart.className = 'btn-retest-done';
      btnRestart.onclick = retestDone;
    } else {
      const btnRestart = document.getElementById('btnRestart');
      btnRestart.textContent = '重新选择';
      btnRestart.className = 'btn-restart';
      btnRestart.onclick = backToSelect;
    }
  }

  function retestDone() {
    stopTimer();
    QuizState.results = [];
    QuizState.isRetest = false;
    document.getElementById('quizScreen').style.display = 'none';
    document.getElementById('resultsScreen').style.display = 'none';
    document.getElementById('progressFill').style.width = '0%';
    // Simply show stats screen without rebuilding — preserves expanded card state
    document.getElementById('statsScreen').style.display = 'block';
  }

  async function backToSelect() {
    if (QuizState.isRetest) {
      retestDone();
      return;
    }
    if (document.getElementById('quizScreen').style.display !== 'none' && QuizState.results.length > 0) {
      const ok = await showConfirm({
        title: '退出测验？',
        message: '当前测验进度将不会保存，下次进入时需要重新开始。',
        confirmText: '退出',
        cancelText: '继续答题',
        danger: true,
      });
      if (!ok) return;
    }
    _cancelFeedback();
    stopTimer();
    QuizState.results = [];
    document.getElementById('quizScreen').style.display = 'none';
    document.getElementById('resultsScreen').style.display = 'none';
    document.getElementById('selectScreen').style.display = 'block';
    document.getElementById('progressFill').style.width = '0%';
  }

  async function exitQuiz() {
    if (QuizState.isRetest) {
      retestDone();
      return;
    }
    if (QuizState.results.length > 0) {
      const ok = await showConfirm({
        title: '退出测验？',
        message: '当前测验进度将不会保存。',
        confirmText: '退出',
        cancelText: '继续答题',
        danger: true,
      });
      if (!ok) return;
    }
    _cancelFeedback();
    stopTimer();
    QuizState.results = [];
    document.getElementById('quizScreen').style.display = 'none';
    document.getElementById('resultsScreen').style.display = 'none';
    document.getElementById('selectScreen').style.display = 'block';
    document.getElementById('progressFill').style.width = '0%';
  }

  return { startQuiz, submitAnswer, backToSelect, exitQuiz, startRetestQuiz, cancelQuizFeedback: _cancelFeedback };
}
