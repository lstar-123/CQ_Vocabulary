// ==================== QUIZ PAGE EVENTS ====================
import { DOM } from './dom.js';

export function bindQuizEvents({ showHome, startQuiz, submitAnswer, backToSelect, exitQuiz, toggleUnit }) {
  if (DOM.btnBackSelect) DOM.btnBackSelect.addEventListener('click', showHome);
  if (DOM.btnStart) DOM.btnStart.addEventListener('click', startQuiz);
  if (DOM.btnBackQuiz) DOM.btnBackQuiz.addEventListener('click', backToSelect);
  if (DOM.btnExitQuiz) DOM.btnExitQuiz.addEventListener('click', exitQuiz);
  if (DOM.submitBtn) DOM.submitBtn.addEventListener('click', submitAnswer);
  if (DOM.btnRestart) DOM.btnRestart.addEventListener('click', backToSelect);

  if (DOM.unitOptions) {
    DOM.unitOptions.addEventListener('click', (e) => {
      const opt = e.target.closest('.unit-option[data-unit]');
      if (opt) toggleUnit(opt.dataset.unit);
    });
  }
}
