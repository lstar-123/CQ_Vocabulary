// ==================== QUIZ TIMER STATE ====================

let quizStartTime = null;   // timestamp when quiz started
let quizTimerInterval = null;  // timer interval handle

export function setQuizStartTime(ts) {
  quizStartTime = ts;
}

export function startTimer() {
  if (quizTimerInterval) return;
  updateTimerDisplay();
  quizTimerInterval = setInterval(updateTimerDisplay, 1000);
}

function updateTimerDisplay() {
  const elapsed = Math.floor((Date.now() - quizStartTime) / 1000);
  const mins = Math.floor(elapsed / 60);
  const secs = elapsed % 60;
  document.getElementById('quizTimer').textContent = `⏱ ${mins}:${String(secs).padStart(2, '0')}`;
}

export function stopTimer() {
  if (quizTimerInterval) { clearInterval(quizTimerInterval); quizTimerInterval = null; }
}

export function getElapsedSeconds() {
  return quizStartTime ? Math.floor((Date.now() - quizStartTime) / 1000) : 0;
}
