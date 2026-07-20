// ==================== LIST MODE ====================
import { escapeHtml } from '../utils.js';
import { getTotalWordCount } from './unitFilter.js';

export function buildListMode({ allWordsGrouped, englishVisible }) {
  const container = document.getElementById('studyContent');

  if (allWordsGrouped.length === 0) {
    container.innerHTML = `
      <div style="text-align:center;padding:64px 24px;color:var(--text-muted);">
        <div style="font-size:48px;margin-bottom:16px;">📖</div>
        <div style="font-family:'Playfair Display',serif;font-size:20px;font-weight:600;color:var(--text-headline);margin-bottom:8px;">暂无词汇数据</div>
        <div style="font-family:'Inter',sans-serif;font-size:13px;line-height:1.8;">请先选择词书并添加词汇<br>让词汇在脑海中生根发芽 🌱</div>
      </div>
    `;
    document.getElementById('studyToolbarInfo').textContent = '共 0 个词汇';
    return;
  }

  // Show ALL units, all collapsed initially
  const totalWords = getTotalWordCount(allWordsGrouped);
  container.innerHTML = allWordsGrouped.map(g => `
    <div class="study-cat-card collapsed" id="studyCat${g.unit_id}">
      <div class="study-cat-header" data-cat-id="${g.unit_id}">
        <span class="cat-icon">📖</span>
        <div class="cat-info">
          <div class="cat-name">${escapeHtml(g.unit_name)}</div>
          <div class="cat-count">${g.words.length} 个词汇</div>
        </div>
        <span class="expand-arrow">&#9660;</span>
      </div>
      <div class="study-word-list">
        ${g.words.map((w, i) => `
          <div class="study-word-item">
            <span class="sw-num">${i + 1}</span>
            <span class="sw-en">${escapeHtml(w.english)}</span>
            <button class="btn-speak-sm" data-word="${escapeHtml(w.english).replace(/"/g, '&quot;')}" title="朗读">🔊</button>
            <span class="sw-zh ${englishVisible ? '' : 'hidden'}">${escapeHtml(w.chinese)}</span>
          </div>
        `).join('')}
      </div>
    </div>
  `).join('');

  document.getElementById('studyToolbarInfo').textContent = `共 ${totalWords} 个词汇 · ${allWordsGrouped.length} 个单元`;
}

export function toggleStudyCat(catId) {
  const el = document.getElementById('studyCat' + catId);
  if (el) el.classList.toggle('collapsed');
}
