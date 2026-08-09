// ==================== PROFILE / BOOK SWITCHING ====================
import { apiFetch } from '../api.js';
import { ensureBookList, getBookList } from './bookSelection.js';
import { StatsState } from '../state/statsState.js';
import { currentUser } from '../state/auth.js';
import { escapeHtml } from '../utils.js';
import { icon } from '../ui/icons.js';

export function createProfileScreen({ allWordsGrouped, currentTab, onUnitSelection, onStudyMode, onStatsScreen }) {

  async function openProfile() {
    try {
      // Close book selection overlay if it's showing (so it doesn't block profile)
      document.getElementById('bookSelectOverlay').style.display = 'none';
      await ensureBookList();
      document.getElementById('profileUsername').textContent = currentUser.username || '';
      document.getElementById('profileCurrentBook').textContent =
        (getBookList().find(b => b.schema === currentUser.current_book) || {}).name || currentUser.current_book || '未选择';
      document.getElementById('profileBookSelect').innerHTML = getBookList().map(b =>
        `<option value="${b.schema}" ${b.schema === currentUser.current_book ? 'selected' : ''}>${b.name}</option>`
      ).join('');
      document.getElementById('profileMsg').textContent = '';
      document.getElementById('profileOverlay').style.display = 'flex';
    } catch (e) {
      console.error('openProfile error:', e);
      // Still try to show the overlay even if something failed
      try {
        document.getElementById('profileUsername').textContent = currentUser ? (currentUser.username || '') : '';
        document.getElementById('profileCurrentBook').textContent = currentUser ? (currentUser.current_book || '未选择') : '';
        document.getElementById('profileBookSelect').innerHTML = '<option value="">加载失败，请刷新重试</option>';
        document.getElementById('profileOverlay').style.display = 'flex';
      } catch (e2) {
        console.error('openProfile fallback error:', e2);
      }
    }
  }

  function closeProfile(e) {
    if (e && e.target !== document.getElementById('profileOverlay')) return;
    document.getElementById('profileOverlay').style.display = 'none';
  }

  async function switchBook() {
    const newBook = document.getElementById('profileBookSelect').value;
    if (!newBook || newBook === currentUser.current_book) { closeProfile(); return; }
    try {
      const result = await apiFetch('/api/auth/book', { method:'PUT', body: JSON.stringify({ book_schema: newBook }) });
      currentUser.current_book = result.current_book;
      document.getElementById('profileCurrentBook').textContent = result.book_name;
      document.getElementById('profileMsg').innerHTML = `${icon('check-circle', 13)} 词书已切换为：` + escapeHtml(result.book_name);
      allWordsGrouped.length = 0;
      StatsState.statsAllUnits = [];
      StatsState.statsTrendUnitFilter = '';
      setTimeout(() => {
        if (currentTab === 'quiz') onUnitSelection();
        else if (currentTab === 'study') onStudyMode();
        else if (currentTab === 'stats') onStatsScreen();
      }, 600);
    } catch (e) { document.getElementById('profileMsg').innerHTML = `${icon('x-circle', 13)} 切换失败：` + escapeHtml(e.message); }
  }

  // ── Change username ─────────────────────────────────────
  function openUsernameModal() {
    const curName = currentUser.username || '';
    document.getElementById('usernameInput').value = curName;
    document.getElementById('usernameMsg').textContent = '';
    document.getElementById('usernameMsg').style.color = 'var(--sage)';
    const curEl = document.getElementById('umCurrentName');
    if (curEl) curEl.textContent = curName || '—';
    const countEl = document.getElementById('usernameCount');
    if (countEl) countEl.textContent = curName.length + ' / 50';
    document.getElementById('usernameModal').style.display = 'flex';
    setTimeout(() => {
      const inp = document.getElementById('usernameInput');
      if (inp) { inp.focus(); inp.select(); }
    }, 100);
  }

  function closeUsernameModal(e) {
    if (e && e.target !== document.getElementById('usernameModal')) return;
    document.getElementById('usernameModal').style.display = 'none';
  }

  async function saveUsername() {
    const username = document.getElementById('usernameInput').value.trim();
    const msgEl = document.getElementById('usernameMsg');
    if (!username) { msgEl.style.color = 'var(--terracotta)'; msgEl.textContent = '用户名不能为空'; return; }
    try {
      const result = await apiFetch('/api/auth/username', { method: 'PUT', body: JSON.stringify({ username }) });
      currentUser.username = result.username;
      document.getElementById('profileUsername').textContent = result.username;
      const userNameDisplay = document.getElementById('userNameDisplay');
      if (userNameDisplay) userNameDisplay.textContent = result.username;
      closeUsernameModal();
    } catch (e) {
      msgEl.style.color = 'var(--terracotta)';
      msgEl.textContent = e.message || '修改失败';
    }
  }

  return { openProfile, closeProfile, switchBook, openUsernameModal, closeUsernameModal, saveUsername };
}
