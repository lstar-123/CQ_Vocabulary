// ==================== TOAST ====================
// Lightweight in-app toast notifications.
// Import-time side-effect free — the container is created lazily on first use.

const MAX_VISIBLE = 4;
const LEAVE_MS = 260;   // matches .toast.leaving animation duration

let _container = null;

function getContainer() {
  if (_container) return _container;
  _container = document.createElement('div');
  _container.id = 'toastContainer';
  _container.className = 'toast-container';
  _container.setAttribute('role', 'status');
  _container.setAttribute('aria-live', 'polite');
  document.body.appendChild(_container);
  return _container;
}

/**
 * Show a toast notification.
 * @param {string} message  plain text — always set via textContent (XSS-safe)
 * @param {object} [opts]   { type: 'info'|'success'|'error'|'warning', duration: ms }
 */
export function showToast(message, { type = 'info', duration = 2600 } = {}) {
  const container = getContainer();

  // Cap visible toasts — drop the oldest
  while (container.children.length >= MAX_VISIBLE) {
    container.firstChild.remove();
  }

  const toast = document.createElement('div');
  toast.className = `toast toast-${type}`;
  toast.textContent = message;
  container.appendChild(toast);

  setTimeout(() => {
    toast.classList.add('leaving');
    setTimeout(() => toast.remove(), LEAVE_MS);
  }, duration);
}

/** Remove all visible toasts immediately. */
export function clearToasts() {
  if (_container) _container.innerHTML = '';
}
