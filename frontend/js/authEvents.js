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

export function bindProfileEvents({ closeProfile, switchBook }) {
  if (DOM.profileOverlay) {
    DOM.profileOverlay.addEventListener('click', (e) => {
      if (e.target === DOM.profileOverlay) closeProfile();
    });
  }
  if (DOM.btnProfileClose) DOM.btnProfileClose.addEventListener('click', () => closeProfile());
  if (DOM.btnProfileSave) DOM.btnProfileSave.addEventListener('click', switchBook);
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
