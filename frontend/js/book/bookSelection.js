// ==================== BOOK SELECTION ====================
import { apiFetch } from '../api.js';
import { escapeHtml } from '../utils.js';
import { currentUser } from '../state/auth.js';
import { finishShowMainApp, getSavedPage } from '../view/appView.js';

let bookList = [];
let selectedBookSchema = null;

export function getBookList() {
  return bookList;
}

export async function ensureBookList() {
  if (bookList.length === 0) {
    try { bookList = await apiFetch('/api/auth/books'); } catch (e) { bookList = []; }
  }
  return bookList;
}

export async function showBookSelection() {
  await ensureBookList();
  selectedBookSchema = null;
  document.getElementById('bookSelectOptions').innerHTML = bookList.map(b => `
    <div class="book-option" data-schema="${b.schema}">
      <div class="book-radio"></div>
      <span class="book-icon">📚</span>
      <div class="book-info">
        <div class="book-name">${escapeHtml(b.name)}</div>
        <div class="book-desc">词书代码：${escapeHtml(b.schema)}</div>
      </div>
    </div>
  `).join('');
  document.getElementById('btnConfirmBook').disabled = true;
  document.getElementById('bookSelectError').textContent = '';
  document.getElementById('bookSelectOverlay').style.display = 'flex';
}

export function selectBookOption(schema) {
  selectedBookSchema = schema;
  document.querySelectorAll('#bookSelectOptions .book-option').forEach(el => {
    el.classList.toggle('selected', el.dataset.schema === schema);
  });
  document.getElementById('btnConfirmBook').disabled = false;
}

export async function confirmBookSelection() {
  if (!selectedBookSchema) return;
  try {
    const result = await apiFetch('/api/auth/book', {
      method: 'PUT',
      body: JSON.stringify({ book_schema: selectedBookSchema })
    });
    currentUser.current_book = result.current_book;
    finishShowMainApp(getSavedPage());
  } catch (e) {
    document.getElementById('bookSelectError').textContent = '❌ 设置词书失败：' + e.message;
  }
}

export function closeBookSelection() {
  document.getElementById('bookSelectOverlay').style.display = 'none';
}
