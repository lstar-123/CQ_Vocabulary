// ==================== APP SHELL VIEW ====================
import { currentUser } from '../state/auth.js';

const PAGE_STORAGE_KEY = 'vocab_current_page';

export function saveCurrentPage(tab) {
  try { sessionStorage.setItem(PAGE_STORAGE_KEY, tab || 'home'); } catch (e) {}
}

export function getSavedPage() {
  try { return sessionStorage.getItem(PAGE_STORAGE_KEY) || 'home'; } catch (e) { return 'home'; }
}

export function finishShowMainApp(targetTab) {
  document.getElementById('bookSelectOverlay').style.display = 'none';
  document.getElementById('userBar').style.display = 'flex';
  document.getElementById('userNameDisplay').textContent = currentUser.username;

  const tab = targetTab || 'home';
  document.getElementById('homeScreen').style.display = tab === 'home' ? '' : 'none';
  document.getElementById('selectScreen').style.display = tab === 'quiz' ? 'block' : 'none';
  document.getElementById('quizScreen').style.display = 'none';
  document.getElementById('resultsScreen').style.display = 'none';
  document.getElementById('studyScreen').style.display = tab === 'study' ? 'block' : 'none';
  document.getElementById('statsScreen').style.display = tab === 'stats' ? 'block' : 'none';
}
