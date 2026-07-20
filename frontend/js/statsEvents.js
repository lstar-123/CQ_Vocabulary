// ==================== STATS PAGE EVENTS ====================
import { DOM } from './dom.js';

export function bindStatsEvents({
  showHome,
  switchTrendUnit, switchHistoryUnit,
  goHistoryPage, toggleHistoryDetail,
}) {
  DOM.btnBackStats.addEventListener('click', showHome);

  DOM.trendUnitFilter.addEventListener('click', (e) => {
    const btn = e.target.closest('.trend-unit-btn[data-unit]');
    if (btn) switchTrendUnit(btn.dataset.unit);
  });

  DOM.historyUnitFilter.addEventListener('click', (e) => {
    const btn = e.target.closest('.trend-unit-btn[data-unit]');
    if (btn) switchHistoryUnit(btn.dataset.unit);
  });

  DOM.historyList.addEventListener('click', (e) => {
    const item = e.target.closest('.history-item[data-sid]');
    if (item) toggleHistoryDetail(parseInt(item.dataset.sid), item);
  });

  DOM.historyPagination.addEventListener('click', (e) => {
    const btn = e.target.closest('.page-btn[data-page]');
    if (btn && !btn.disabled) goHistoryPage(parseInt(btn.dataset.page));
  });
}
