// ==================== AUTH + PROFILE + BOOK EVENTS ====================
import { DOM } from './dom.js';

export function bindAuthEvents({ handleAuthSubmit, renderAuthForm }) {
  DOM.authOverlay.addEventListener('click', (e) => {
    const tab = e.target.closest('.auth-tab[data-mode]');
    if (tab) { renderAuthForm(tab.dataset.mode); return; }
    if (e.target.closest('.btn-auth')) { handleAuthSubmit(); return; }
    if (e.target.closest('.auth-card')) e.stopPropagation();
  });
  DOM.authOverlay.addEventListener('keydown', (e) => {
    if (e.key === 'Enter' && e.target.closest('input')) handleAuthSubmit();
  });
}

export function bindProfileEvents({ closeProfile, switchBook, openUsernameModal, closeUsernameModal, saveUsername }) {
  if (DOM.profileOverlay) {
    DOM.profileOverlay.addEventListener('click', (e) => {
      if (e.target === DOM.profileOverlay) closeProfile();
    });
  }
  if (DOM.btnProfileClose) DOM.btnProfileClose.addEventListener('click', () => closeProfile());
  if (DOM.btnProfileSave) DOM.btnProfileSave.addEventListener('click', switchBook);

  // Change username
  if (DOM.profileUsername) DOM.profileUsername.addEventListener('click', openUsernameModal);
  if (DOM.usernameModal) {
    DOM.usernameModal.addEventListener('click', (e) => {
      if (e.target === DOM.usernameModal) closeUsernameModal();
    });
    DOM.usernameModal.addEventListener('keydown', (e) => {
      if (e.key === 'Enter' && e.target.closest('input')) saveUsername();
    });
  }
  if (DOM.btnUsernameCancel) DOM.btnUsernameCancel.addEventListener('click', () => closeUsernameModal());
  if (DOM.btnUsernameSave) DOM.btnUsernameSave.addEventListener('click', saveUsername);
  if (DOM.usernameInput) {
    DOM.usernameInput.addEventListener('input', () => {
      if (DOM.usernameCount) DOM.usernameCount.textContent = DOM.usernameInput.value.length + ' / 50';
    });
  }
}

export function bindBookSelectEvents({ confirmBookSelection, selectBookOption, closeBookSelection }) {
  if (DOM.btnConfirmBook) DOM.btnConfirmBook.addEventListener('click', confirmBookSelection);
  if (DOM.bookSelectOverlay) {
    DOM.bookSelectOverlay.addEventListener('click', (e) => {
      if (e.target === DOM.bookSelectOverlay) closeBookSelection();
    });
  }
  if (DOM.bookSelectOptions) {
    DOM.bookSelectOptions.addEventListener('click', (e) => {
      const opt = e.target.closest('.book-option[data-schema]');
      if (opt) selectBookOption(opt.dataset.schema);
    });
  }
  // Close book selection via cancel button
  const btnCancelBook = document.getElementById('btnCancelBook');
  if (btnCancelBook) btnCancelBook.addEventListener('click', closeBookSelection);
}
