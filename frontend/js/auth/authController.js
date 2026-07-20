// ==================== AUTH CONTROLLER ====================
import { apiFetch } from '../api.js';
import { currentUser, setCurrentUser, clearCurrentUser } from '../state/auth.js';
import { renderAuthForm, getAuthMode } from './authForm.js';

export async function checkAuth({ onAuthenticated, onUnauthenticated }) {
  try {
    const res = await fetch('/api/auth/me', { credentials: 'same-origin' });
    const data = await res.json();
    if (data.id) {
      setCurrentUser(data);
      onAuthenticated();
    } else {
      onUnauthenticated();
    }
  } catch (e) {
    onUnauthenticated();
  }
}

export function showAuth() {
  clearCurrentUser();
  document.getElementById('authOverlay').style.display = 'flex';
  document.getElementById('userBar').style.display = 'none';
  document.getElementById('homeScreen').style.display = 'none';
  document.getElementById('selectScreen').style.display = 'none';
  document.getElementById('quizScreen').style.display = 'none';
  document.getElementById('resultsScreen').style.display = 'none';
  document.getElementById('studyScreen').style.display = 'none';
  document.getElementById('statsScreen').style.display = 'none';
  renderAuthForm('login');
}

export async function handleLogout() {
  await apiFetch('/api/auth/logout', { method: 'POST' });
  clearCurrentUser();
  showAuth();
}

export async function handleAuthSubmit(onSuccess) {
  const username = document.getElementById('authUsername').value.trim();
  const password = document.getElementById('authPassword').value.trim();

  if (!username || !password) {
    document.getElementById('authError').textContent = '请填写用户名和密码';
    return;
  }

  const endpoint = getAuthMode() === 'login' ? '/api/auth/login' : '/api/auth/register';
  try {
    const res = await fetch(endpoint, {
      method: 'POST',
      credentials: 'same-origin',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username, password })
    });
    const data = await res.json();
    if (!res.ok) {
      document.getElementById('authError').textContent = data.error || '操作失败';
      return;
    }
    setCurrentUser(data);
    onSuccess();
  } catch (e) {
    document.getElementById('authError').textContent = '网络错误，请重试';
  }
}
