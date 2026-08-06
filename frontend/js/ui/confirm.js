// ==================== CONFIRM MODAL ====================
// Styled in-app replacement for window.confirm().
// Import-time side-effect free; renders lazily on first call.
// Returns a Promise<boolean> — resolves true when the user confirms.

let _overlay = null;
let _active = false;

/** True while a confirm modal is open — used as a global keyboard guard. */
export function isModalOpen() { return _active; }

function buildOverlay() {
  const overlay = document.createElement('div');
  overlay.className = 'confirm-overlay';
  overlay.style.display = 'none';
  overlay.innerHTML = `
    <div class="confirm-card" role="alertdialog" aria-modal="true">
      <div class="confirm-title"></div>
      <div class="confirm-msg"></div>
      <div class="confirm-actions">
        <button class="btn-confirm-cancel" type="button"></button>
        <button class="btn-confirm-ok" type="button"></button>
      </div>
    </div>`;
  document.body.appendChild(overlay);

  // Close on overlay (backdrop) click
  overlay.addEventListener('click', (e) => {
    if (e.target === overlay) overlay._resolve(false);
  });
  // Buttons — bound once; dispatch through the current showConfirm handler
  overlay.querySelector('.btn-confirm-cancel').addEventListener('click', (e) => {
    e.stopPropagation();
    if (overlay._resolve) overlay._resolve(false);
  });
  overlay.querySelector('.btn-confirm-ok').addEventListener('click', (e) => {
    e.stopPropagation();
    if (overlay._resolve) overlay._resolve(true);
  });
  return overlay;
}

/**
 * Show a confirm dialog.
 * @param {object} opts { title, message, confirmText, cancelText, danger }
 * @returns {Promise<boolean>} true when confirmed, false on cancel/Esc/backdrop
 */
export function showConfirm({ title = '确认', message = '', confirmText = '确定', cancelText = '取消', danger = false } = {}) {
  return new Promise((resolve) => {
    const overlay = _overlay || (_overlay = buildOverlay());
    const titleEl = overlay.querySelector('.confirm-title');
    const msgEl = overlay.querySelector('.confirm-msg');
    const cancelBtn = overlay.querySelector('.btn-confirm-cancel');
    const okBtn = overlay.querySelector('.btn-confirm-ok');

    titleEl.textContent = title;
    msgEl.textContent = message;           // textContent only — XSS-safe
    cancelBtn.textContent = cancelText;
    okBtn.textContent = confirmText;
    okBtn.classList.toggle('danger', danger);

    // Remember the element that had focus so we can restore it on close
    const prevFocus = document.activeElement;

    // Sequential queueing: if a modal is already open, resolve the previous
    // one as cancelled before showing this one.
    if (overlay._resolve) {
      overlay._resolve(false);
    }

    const finish = (result) => {
      overlay.style.display = 'none';
      _active = false;
      overlay._resolve = null;
      overlay.removeEventListener('keydown', keyHandler);
      if (prevFocus && prevFocus.focus) prevFocus.focus();
      resolve(result);
    };
    overlay._resolve = finish;

    function keyHandler(e) {
      if (e.key === 'Escape') { e.preventDefault(); finish(false); }
      else if (e.key === 'Enter') { e.preventDefault(); finish(true); }
    }
    overlay.addEventListener('keydown', keyHandler);

    overlay.style.display = 'flex';
    _active = true;
    cancelBtn.focus();
  });
}
