// ==================== STUDY UNIT FILTER ====================
import { escapeHtml } from '../utils.js';

// null = "全部" (all units), number = specific unit ID
let cardUnitFilter = null;

export function buildUnitChips(allUnits, mode) {
  const container = document.getElementById('catFilterChips');

  if (mode !== 'card') {
    container.innerHTML = '';
    return;
  }

  // Card mode: single-select radio chips
  const allActive = cardUnitFilter === null;
  let html = `<button class="cat-chip${allActive ? ' active-chip' : ''}" id="chipSelectAll">📚 全部</button>`;
  html += allUnits.map(u => {
    const active = cardUnitFilter === u.id ? ' active-chip' : '';
    return `<button class="cat-chip${active}" data-unit="${u.id}">📖 ${escapeHtml(u.name)}</button>`;
  }).join('');
  container.innerHTML = html;
}

export function selectCardUnit(unitId, allUnits, allWordsGrouped, onChanged) {
  // unitId: null = "全部", number = specific unit
  if (cardUnitFilter === unitId) return; // already selected, no-op
  cardUnitFilter = unitId;

  // Update chip active states
  const chipAll = document.getElementById('chipSelectAll');
  if (chipAll) chipAll.classList.toggle('active-chip', unitId === null);

  allUnits.forEach(u => {
    const chip = document.querySelector(`.cat-chip[data-unit="${u.id}"]`);
    if (chip) chip.classList.toggle('active-chip', unitId === u.id);
  });

  updateStudyToolbarInfo(allUnits, allWordsGrouped);
  if (onChanged) onChanged();
}

export function getFilteredWords(allWordsGrouped) {
  if (cardUnitFilter === null) {
    // "全部": return all words from all units
    const result = [];
    allWordsGrouped.forEach(group => {
      group.words.forEach(w => result.push({ ...w, unit_name: group.unit_name, unit_id: group.unit_id }));
    });
    return result;
  }
  // Specific unit selected
  const result = [];
  allWordsGrouped.forEach(group => {
    if (group.unit_id === cardUnitFilter) {
      group.words.forEach(w => result.push({ ...w, unit_name: group.unit_name, unit_id: group.unit_id }));
    }
  });
  return result;
}

export function getTotalWordCount(allWordsGrouped) {
  let count = 0;
  allWordsGrouped.forEach(g => { count += g.words.length; });
  return count;
}

export function updateStudyToolbarInfo(allUnits, allWordsGrouped) {
  const words = getFilteredWords(allWordsGrouped);
  if (cardUnitFilter === null) {
    document.getElementById('studyToolbarInfo').textContent = `共 ${words.length} 个词汇 · 全部单元`;
  } else {
    const unitName = allUnits.find(u => u.id === cardUnitFilter)?.name || '';
    document.getElementById('studyToolbarInfo').textContent = `共 ${words.length} 个词汇 · ${unitName}`;
  }
}
