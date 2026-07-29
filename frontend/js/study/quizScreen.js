// ==================== QUIZ SCREEN ====================
import { escapeHtml, checkEquivalent, formatDuration } from '../utils.js';
import { apiFetch } from '../api.js';
import { setQuizStartTime, startTimer, stopTimer, getElapsedSeconds } from '../state/quizTimer.js';
import { QuizState } from '../state/quizState.js';
import { currentUser } from '../state/auth.js';

export function createQuizScreen({ allUnits, selectedUnitIds }) {

  let _retestCallback = null;

  function startRetestQuiz(wrongAnswers) {
    if (!wrongAnswers || wrongAnswers.length === 0) return;
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
    showQuestion();
  }

  async function startQuiz() {
    if (selectedUnitIds.size === 0) return;
    const book = currentUser.current_book;
    const ids = Array.from(selectedUnitIds).join(',');
    const words = await apiFetch(`/api/words?unit_ids=${ids}&book_schema=${book}&random=1`);
    if (words.length === 0) { alert('所选单元没有词汇数据'); return; }
    QuizState.quizWords = words;
    const names = allUnits.filter(u => selectedUnitIds.has(u.id)).map(u => u.name);
    QuizState.currentIndex = 0;
    QuizState.results = [];
    setQuizStartTime(Date.now());
    document.getElementById('selectScreen').style.display = 'none';
    document.getElementById('quizScreen').style.display = 'block';
    document.getElementById('resultsScreen').style.display = 'none';
    document.getElementById('unitTag').textContent = names.join(', ');
    showQuestion();
  }

  function showQuestion() {
    if (QuizState.currentIndex >= QuizState.quizWords.length) { showResults(); return; }
    const w = QuizState.quizWords[QuizState.currentIndex];
    document.getElementById('wordZh').textContent = w.chinese;
    document.getElementById('wordHint').textContent = '请输入对应的英文翻译';
    document.getElementById('counter').textContent = `${QuizState.currentIndex + 1} / ${QuizState.quizWords.length}`;
    document.getElementById('progressFill').style.width = `${(QuizState.currentIndex / QuizState.quizWords.length) * 100}%`;
    document.getElementById('answerInput').value = '';
    document.getElementById('answerInput').focus();
    startTimer();
  }

  function submitAnswer() {
    const input = document.getElementById('answerInput');
    const userAnswer = input.value.trim();
    if (!userAnswer) return;
    const w = QuizState.quizWords[QuizState.currentIndex];
    QuizState.results.push({ word_id: w.id, word: w, userAnswer, isCorrect: checkEquivalent(userAnswer, w.english) });
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
    sc.textContent = accuracy + '%';
    sc.style.background = accuracy >= 90 ? '#58997A' : accuracy >= 70 ? '#7AB89A' : accuracy >= 50 ? '#C8A87A' : '#C86F50';
    const title = document.getElementById('resultTitle'), sub = document.getElementById('resultSub');
    if (accuracy >= 95) { title.textContent = '太棒了！'; sub.textContent = '你几乎全部掌握，继续保持！'; }
    else if (accuracy >= 80) { title.textContent = '非常优秀！'; sub.textContent = '你已经掌握了大部分高频词汇。'; }
    else if (accuracy >= 60) { title.textContent = '继续加油！'; sub.textContent = '已经过半，再多练练就能突破。'; }
    else { title.textContent = '需要努力！'; sub.textContent = '建议反复记忆这些词汇。'; }
    document.getElementById('totalCount').textContent = total;
    document.getElementById('correctCount').textContent = correct;
    document.getElementById('wrongCount').textContent = wrong;
    document.getElementById('resultSub').textContent += ` · 用时 ${formatDuration(dur)}`;
    document.getElementById('detailTitle').textContent = `全部答题详情（共 ${total} 题）`;
    document.getElementById('detailBody').innerHTML = QuizState.results.map((r,i) => `
      <tr><td>${i+1}</td><td class="zh" style="font-size:13px;">${escapeHtml(r.word.chinese)} <span style="color:#8C8C8C;font-weight:400;font-size:11px;">[${escapeHtml(r.word.unit_name)}]</span></td>
      <td class="${r.isCorrect?'correct-ans':'user-ans'}">${escapeHtml(r.userAnswer)}</td>
      <td class="correct-ans">${escapeHtml(r.word.english)}</td>
      <td class="icon">${r.isCorrect?'✓':'✗'}</td></tr>`).join('');

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

  function backToSelect() {
    if (QuizState.isRetest) {
      retestDone();
      return;
    }
    if (document.getElementById('quizScreen').style.display !== 'none' && QuizState.results.length > 0) {
      if (!confirm('确定要退出吗？\n\n当前测验进度将不会保存，下次进入时需要重新开始。')) return;
    }
    stopTimer();
    QuizState.results = [];
    document.getElementById('quizScreen').style.display = 'none';
    document.getElementById('resultsScreen').style.display = 'none';
    document.getElementById('selectScreen').style.display = 'block';
    document.getElementById('progressFill').style.width = '0%';
  }

  function exitQuiz() {
    if (QuizState.isRetest) {
      retestDone();
      return;
    }
    if (QuizState.results.length > 0) {
      if (!confirm('确定要退出测验吗？\n\n当前测验进度将不会保存。')) return;
    }
    stopTimer();
    QuizState.results = [];
    document.getElementById('quizScreen').style.display = 'none';
    document.getElementById('resultsScreen').style.display = 'none';
    document.getElementById('selectScreen').style.display = 'block';
    document.getElementById('progressFill').style.width = '0%';
  }

  return { startQuiz, submitAnswer, backToSelect, exitQuiz, startRetestQuiz };
}
