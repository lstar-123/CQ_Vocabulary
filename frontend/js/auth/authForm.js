// ==================== AUTH FORM ====================
import { escapeHtml } from '../utils.js';

let authMode = 'login';
let authError = '';

export function getAuthMode() {
  return authMode;
}

export function renderAuthForm(mode) {
  authMode = mode;
  authError = '';
  const overlay = document.getElementById('authOverlay');
  overlay.className = 'auth-overlay';
  overlay.innerHTML = `
    <div class="auth-card">
      <h2>${mode === 'login' ? '欢迎回来' : '创建账户'}</h2>
      <p class="auth-sub">登录以保存你的答题记录和学习进度</p>
      <div class="auth-tabs">
        <button class="auth-tab ${mode === 'login' ? 'active' : ''}" data-mode="login">登录</button>
        <button class="auth-tab ${mode === 'register' ? 'active' : ''}" data-mode="register">注册</button>
      </div>
      <div class="auth-error" id="authError">${authError}</div>
      <div class="form-group">
        <label>用户名</label>
        <input type="text" id="authUsername" placeholder="请输入用户名" autocomplete="username">
      </div>
      <div class="form-group">
        <label>密码</label>
        <input type="password" id="authPassword" placeholder="请输入密码" autocomplete="${mode === 'login' ? 'current-password' : 'new-password'}">
      </div>
      <button class="btn-auth">
        ${mode === 'login' ? '登 录' : '注 册'}
      </button>
    </div>
  `;
  // Focus username input
  setTimeout(() => {
    const inp = document.getElementById('authUsername');
    if (inp) inp.focus();
  }, 100);
}
