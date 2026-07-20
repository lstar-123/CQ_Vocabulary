// ==================== HOME PAGE EVENTS ====================
import { DOM } from './dom.js';

export function bindHomeEvents({ showHome, switchTab, openProfile, handleLogout }) {
  if (DOM.logoHome) DOM.logoHome.addEventListener('click', showHome);
  if (DOM.userNameDisplay) DOM.userNameDisplay.addEventListener('click', openProfile);
  if (DOM.btnLogout) DOM.btnLogout.addEventListener('click', handleLogout);

  // Home cards
  if (DOM.homeCardStudy) DOM.homeCardStudy.addEventListener('click', () => switchTab('study'));
  if (DOM.homeCardQuiz) DOM.homeCardQuiz.addEventListener('click', () => switchTab('quiz'));
  if (DOM.homeCardStats) DOM.homeCardStats.addEventListener('click', () => switchTab('stats'));
}
