// ==================== STATS SCREEN ====================
import { escapeHtml, formatDuration } from '../utils.js';
import { apiFetch } from '../api.js';
import { ensureBookList, getBookList } from '../book/bookSelection.js';
import { StatsState } from '../state/statsState.js';
import { currentUser } from '../state/auth.js';
import { countUp } from '../ui/anim.js';
import { showToast } from '../ui/toast.js';
import { skeletonStatsCard, skeletonHistoryRow } from '../ui/skeleton.js';
import { icon } from '../ui/icons.js';

export function createStatsScreen({ startRetestQuiz } = {}) {

  // Monotonic request id — drops stale history renders on rapid page/filter switches
  let _historyReqId = 0;

  async function buildStatsScreen() {
    const book = currentUser.current_book;
    if (StatsState.statsAllUnits.length === 0) {
      try { StatsState.statsAllUnits = await apiFetch(`/api/units?book_schema=${book}`); } catch (e) { StatsState.statsAllUnits = []; }
    }

    // Show skeletons while the stats fetch is in flight
    document.getElementById('statsSummaryCards').innerHTML =
      Array(6).fill(skeletonStatsCard()).join('');
    document.getElementById('historyList').innerHTML =
      Array(5).fill(skeletonHistoryRow()).join('');

    let summary, trend, groupHistory;
    try {
      [summary, trend, groupHistory] = await Promise.all([
        apiFetch(`/api/stats/summary?book_schema=${book}`),
        apiFetch(`/api/stats/trend?book_schema=${book}`),
        apiFetch(`/api/stats/group-history?book_schema=${book}`).catch(e => {
          console.warn('Group history fetch failed:', e.message);
          return [];
        })
      ]);
    } catch (e) {
      console.error('Stats load failed:', e);
      showToast('统计数据加载失败，请重试', { type: 'error' });
      document.getElementById('statsSummaryCards').innerHTML =
        '<div class="no-data">加载失败，请重试</div>';
      document.getElementById('historyList').innerHTML = '';
      return;
    }
    StatsState.statsTrendData = trend;
    StatsState.historyUnitFilter = 'all';
    StatsState.historyPage = 1;

    await ensureBookList();
    const bookName = (getBookList().find(b => b.schema === book) || {}).name || book;
    document.getElementById('statsBookLabel').innerHTML =
      `<span class="unit-tag"><span style="display:inline-flex;vertical-align:-2px;margin-right:6px;">${icon('book-open', 12)}</span>${escapeHtml(bookName)}</span>`;

    document.getElementById('statsSummaryCards').innerHTML = `
      <div class="stats-summary-card">
        <div class="ss-num">${summary.total_quizzes}</div><div class="ss-label">总测验次数</div>
      </div>
      <div class="stats-summary-card">
        <div class="ss-num">${summary.avg_score}%</div><div class="ss-label">平均得分</div>
      </div>
      <div class="stats-summary-card">
        <div class="ss-num">${summary.best_score}%</div><div class="ss-label">最高得分</div>
      </div>
      <div class="stats-summary-card">
        <div class="ss-num">${summary.total_correct}</div><div class="ss-label">累计正确数</div>
      </div>
      <div class="stats-summary-card">
        <div class="ss-num">${summary.total_units_studied || 0}</div><div class="ss-label">学习 Unit 数</div>
      </div>
      <div class="stats-summary-card">
        <div class="ss-num">${summary.total_group_sessions || 0}</div><div class="ss-label">学习次数</div>
      </div>`;

    // Count-up animation for the summary numbers
    document.querySelectorAll('#statsSummaryCards .ss-num').forEach(el => {
      const txt = el.textContent;
      countUp(el, parseFloat(txt), { suffix: txt.endsWith('%') ? '%' : '', duration: 900 });
    });

    renderUnitTrendFilter();
    renderTrendChart();
    renderHistoryUnitFilter();
    renderHistoryList();
    renderGroupHistory(groupHistory);
  }

  function renderGroupHistory(records) {
    const list = document.getElementById('groupHistoryList');
    document.getElementById('groupHistoryCard').style.display = '';
    if (!records || records.length === 0) {
      list.innerHTML = '';
      document.getElementById('groupHistoryEmpty').style.display = '';
      return;
    }
    document.getElementById('groupHistoryEmpty').style.display = 'none';
    list.innerHTML = records.map(r => {
      const date = r.finished_at
        ? new Date(r.finished_at).toLocaleDateString('zh-CN', { year:'numeric', month:'2-digit', day:'2-digit', hour:'2-digit', minute:'2-digit' })
        : '';
      const dur = r.duration_seconds ? ` · 用时 ${formatDuration(r.duration_seconds)}` : '';
      const iconMap = { unit_complete: icon('award', 24), round_complete: icon('check-circle', 24), group_complete: icon('package', 24) };
      const errCount = r.error_count || 0;
      const errInfo = errCount > 0 ? ` · <span style="display:inline-flex;vertical-align:-2px;">${icon('x-circle', 12)}</span> ${errCount}个错误` : '';
      const errCls = errCount > 0 ? ' has-errors' : '';
      const errWords = r.error_words && r.error_words.length > 0 ? r.error_words : [];
      const errWordsHtml = errWords.length > 0 ? errWords.map(ew =>
        `<span style="display:inline-block;margin:2px 6px;padding:2px 10px;background:#FEF5F2;border:1px solid #F5D5CB;border-radius:999px;font-size:12px;color:var(--terracotta);">${escapeHtml(ew.english)} <span style="color:var(--text-muted);font-size:11px;">${escapeHtml(ew.chinese)}</span></span>`
      ).join('') : '';
      const detailId = `ghd-${r.id}`;
      return `<div class="group-history-item${errCls}" onclick="toggleGroupHistoryDetail('${detailId}', this)">
        <span class="ghi-icon">${iconMap[r.event_type] || icon('check-circle', 24)}</span>
        <div class="ghi-info">
          <div class="ghi-unit">${escapeHtml(r.unit_name)}</div>
          <div class="ghi-meta">${date}${dur}${r.group_size ? ` · ${r.group_size}词` : ''}${errInfo}</div>
        </div>
        <span class="ghi-round">${escapeHtml(r.label || r.event_type)}</span>
        <span class="ghi-time">${date}</span>
        ${errWords.length > 0 ? `<span class="ghi-expand">${icon('chevron-down', 12)}</span>` : ''}
      </div>
      ${errWords.length > 0 ? `
      <div class="group-history-detail" id="${detailId}" style="display:none;">
        <div style="font-size:12px;font-weight:600;color:var(--terracotta);margin-bottom:8px;display:flex;align-items:center;gap:5px;"><span style="display:inline-flex;">${icon('x-circle', 13)}</span>错误单词（${errCount}个）：</div>
        <div style="line-height:2;">${errWordsHtml}</div>
      </div>` : ''}`;
    }).join('');
  }

  function renderUnitTrendFilter() {
    const unitIdSet = new Map();
    StatsState.statsTrendData.forEach(d => {
      const ids = d.unit_ids.split(',').map(x => parseInt(x.trim())).filter(x => !isNaN(x));
      if (ids.length === 0) return;
      const isMulti = ids.length > 1;
      ids.forEach(unitId => {
        if (!unitIdSet.has(unitId)) {
          const u = StatsState.statsAllUnits.find(u => u.id === unitId);
          unitIdSet.set(unitId, { name: u ? u.name : `Unit ${unitId}`, singleCount:0, multiCount:0 });
        }
        const e = unitIdSet.get(unitId);
        if (isMulti) e.multiCount++; else e.singleCount++;
      });
    });

    const sorted = Array.from(unitIdSet.entries()).sort((a,b) => (b[1].singleCount+b[1].multiCount)-(a[1].singleCount+a[1].multiCount));

    const chartCard = document.querySelector('.stats-chart-card');
    let filterDiv = document.getElementById('trendUnitFilter');
    if (!filterDiv) {
      filterDiv = document.createElement('div');
      filterDiv.id = 'trendUnitFilter';
      filterDiv.className = 'trend-unit-filter';
      chartCard.querySelector('h3').after(filterDiv);
    }
    if (sorted.length === 0) { filterDiv.innerHTML = ''; return; }
    if (!StatsState.statsTrendUnitFilter || !unitIdSet.has(parseInt(StatsState.statsTrendUnitFilter))) {
      StatsState.statsTrendUnitFilter = String(sorted[0][0]);
    }
    filterDiv.innerHTML = sorted.map(([uid, info]) => {
      const active = String(uid) === StatsState.statsTrendUnitFilter ? ' active-filter' : '';
      return `<button class="trend-unit-btn${active}" data-unit="${uid}"><span style="display:inline-flex;vertical-align:-2px;margin-right:5px;">${icon('book', 12)}</span>${escapeHtml(info.name)}</button>`;
    }).join('');
  }

  function switchTrendUnit(unitId) {
    StatsState.statsTrendUnitFilter = unitId;
    document.querySelectorAll('#trendUnitFilter .trend-unit-btn').forEach(btn => {
      btn.classList.toggle('active-filter', btn.dataset.unit === unitId);
    });
    renderTrendChart();
  }

  function getFilteredTrendData() {
    const targetId = parseInt(StatsState.statsTrendUnitFilter);
    const targetIdStr = String(targetId);
    const single = [], multi = [];
    StatsState.statsTrendData.forEach(d => {
      const ids = d.unit_ids.split(',').map(x => parseInt(x.trim())).filter(x => !isNaN(x));
      if (ids.length === 0 || !ids.includes(targetId)) return;
      if (ids.length === 1) { single.push(d); }
      else {
        const us = d.unit_scores && d.unit_scores[targetIdStr];
        multi.push({ date:d.date, score_pct: us ? us.score_pct : d.score_pct, total_count: us ? us.total : d.total_count, correct_count: us ? us.correct : d.correct_count, unit_ids:d.unit_ids, unit_names:d.unit_names, is_multi:true });
      }
    });
    return { single, multi };
  }

  function renderTrendChart() {
    if (StatsState.trendChartInstance) { StatsState.trendChartInstance.destroy(); StatsState.trendChartInstance = null; }
    const { single, multi } = getFilteredTrendData();
    const canvas = document.getElementById('trendChart');
    const emptyEl = document.getElementById('chartEmpty');
    if (single.length === 0 && multi.length === 0) { canvas.style.display = 'none'; if (emptyEl) emptyEl.style.display = 'flex'; return; }
    canvas.style.display = ''; if (emptyEl) emptyEl.style.display = 'none';
    const ctx = canvas.getContext('2d');

    const u = StatsState.statsAllUnits.find(u => u.id === parseInt(StatsState.statsTrendUnitFilter));
    const unitName = u ? u.name : `Unit ${StatsState.statsTrendUnitFilter}`;

    const allDates = new Set(); single.forEach(d => allDates.add(d.date)); multi.forEach(d => allDates.add(d.date));
    const labels = Array.from(allDates).sort();
    const sData = labels.map(d => { const m = single.find(x => x.date === d); return m ? m.score_pct : null; });
    const mData = labels.map(d => { const m = multi.find(x => x.date === d); return m ? m.score_pct : null; });

    const datasets = [];
    if (single.length > 0) datasets.push({ label:`${unitName} · 单独测验`, data:sData, borderColor:'#C86F50', backgroundColor:'rgba(200,111,80,0.08)', borderWidth:2.5, fill:false, tension:0.35, pointRadius:5, pointBackgroundColor:'#C86F50', pointBorderColor:'#fff', pointBorderWidth:2, pointHoverRadius:7, spanGaps:false });
    if (multi.length > 0) datasets.push({ label:`${unitName} · 多单元测验`, data:mData, borderColor:'#C8A87A', backgroundColor:'rgba(200,168,122,0.08)', borderWidth:2.5, borderDash:[6,3], fill:false, tension:0.35, pointRadius:6, pointBackgroundColor:'#C8A87A', pointBorderColor:'#fff', pointBorderWidth:2, pointHoverRadius:8, pointStyle:'rectRounded', spanGaps:false });

    StatsState.trendChartInstance = new Chart(ctx, {
      type:'line', data:{ labels, datasets },
      options:{
        responsive:true, maintainAspectRatio:false,
        plugins:{ legend:{ display:true, position:'bottom', labels:{ usePointStyle:true, padding:20, font:{ family:'Inter', size:12 }, color:'#555555' } },
          tooltip:{ callbacks:{ label(ctx){ const lbl = ctx.dataset.label || ''; if (lbl.includes('多单元测验')) { const m = multi.find(d => d.date === ctx.label); if (m && m.correct_count != null) return lbl + ': ' + ctx.parsed.y + '% (' + m.correct_count + '/' + m.total_count + ')'; } return lbl + ': ' + ctx.parsed.y + '%'; } } } },
        scales:{ y:{ min:0, max:100, ticks:{ callback:v=>v+'%', stepSize:20, font:{ family:'Inter' } }, grid:{ color:'#EDE9E2' } }, x:{ ticks:{ font:{ family:'Inter', size:11 }, maxRotation:45 }, grid:{ display:false } } }
      }
    });
  }

  function renderHistoryUnitFilter() {
    const fd = document.getElementById('historyUnitFilter');
    if (!fd || StatsState.statsAllUnits.length === 0) { if (fd) fd.innerHTML = ''; return; }
    fd.innerHTML = `<button class="trend-unit-btn${StatsState.historyUnitFilter==='all'?' active-filter':''}" data-unit="all"><span style="display:inline-flex;vertical-align:-2px;margin-right:5px;">${icon('bar-chart-2', 12)}</span>全部</button>` +
      StatsState.statsAllUnits.map(u => `<button class="trend-unit-btn${String(u.id)===StatsState.historyUnitFilter?' active-filter':''}" data-unit="${u.id}"><span style="display:inline-flex;vertical-align:-2px;margin-right:5px;">${icon('book', 12)}</span>${escapeHtml(u.name)}</button>`).join('');
  }

  function switchHistoryUnit(unitId) {
    StatsState.historyUnitFilter = unitId;
    StatsState.historyPage = 1;
    document.querySelectorAll('#historyUnitFilter .trend-unit-btn').forEach(b => b.classList.toggle('active-filter', b.dataset.unit === unitId));
    renderHistoryList();
  }

  async function renderHistoryList() {
    const container = document.getElementById('historyList');
    const reqId = ++_historyReqId;
    container.innerHTML = Array(5).fill(skeletonHistoryRow()).join('');
    try {
      let url = `/api/history?page=${StatsState.historyPage}&per_page=10&book_schema=${currentUser.current_book}`;
      if (StatsState.historyUnitFilter !== 'all') url += `&unit_id=${StatsState.historyUnitFilter}`;
      const data = await apiFetch(url);
      if (reqId !== _historyReqId) return;   // stale response — dropped
      const sessions = data.items;
      if (!sessions.length) { container.innerHTML = '<div class="no-data">还没有测验记录，快去答题吧！</div>'; document.getElementById('historyPagination').innerHTML = ''; return; }
      container.innerHTML = sessions.map(s => {
        const sc = s.score_pct >= 80 ? '#58997A' : s.score_pct >= 60 ? '#C8A87A' : '#C86F50';
        const date = s.completed_at ? new Date(s.completed_at).toLocaleDateString('zh-CN', { year:'numeric', month:'2-digit', day:'2-digit', hour:'2-digit', minute:'2-digit' }) : '';
        const un = s.unit_ids.split(',').map(x => { const id = parseInt(x.trim()); const u = StatsState.statsAllUnits.find(u=>u.id===id); return u ? u.name : `Unit ${id}`; }).join(', ');
        return `<div class="history-item" data-sid="${s.id}">
          <div class="hi-card-header">
            <span class="hi-unit-tag">${escapeHtml(un)}</span>
            <span class="hi-score-badge" style="background:${sc};color:#fff;">${s.score_pct}%</span>
          </div>
          <div class="hi-card-stats">
            <div class="hi-stat-item"><span class="hi-stat-val">${s.correct_count}/${s.total_count}</span><span class="hi-stat-lbl">正确/总数</span></div>
            <div class="hi-stat-item"><span class="hi-stat-val" style="color:${sc}">${s.score_pct}%</span><span class="hi-stat-lbl">正确率</span></div>
            <div class="hi-stat-item"><span class="hi-stat-val">${s.total_count}</span><span class="hi-stat-lbl">学习单词</span></div>
          </div>
          <div class="hi-card-footer">
            <span class="hi-date">${date}</span>
            <span class="hi-duration">${escapeHtml(formatDuration(s.duration_seconds))}</span>
            <span class="hi-expand-icon">${icon('chevron-down', 14)}</span>
          </div>
        </div>
        <div class="history-detail" id="histDetail${s.id}" style="display:none;"></div>`;
      }).join('');
      const tp = data.total_pages, tt = data.total;
      if (tp <= 1) { document.getElementById('historyPagination').innerHTML = ''; return; }
      document.getElementById('historyPagination').innerHTML = `<span class="page-info">${tt} 条记录 · 第 ${StatsState.historyPage}/${tp} 页</span><button class="page-btn" data-page="${StatsState.historyPage-1}"${StatsState.historyPage<=1?' disabled':''}>◀ 上一页</button><button class="page-btn" data-page="${StatsState.historyPage+1}"${StatsState.historyPage>=tp?' disabled':''}>下一页 ▶</button>`;
    } catch(e) { if (reqId !== _historyReqId) return; container.innerHTML = '<div class="no-data">加载失败，请重试</div>'; }
  }

  function goHistoryPage(page) {
    const tp = parseInt(document.querySelector('#historyPagination .page-info')?.textContent?.match(/第 \d+\/(\d+) 页/)?.[1] || '1');
    if (page < 1 || page > tp) return;
    StatsState.historyPage = page;
    renderHistoryList();
  }

  async function toggleHistoryDetail(sessionId) {
    const dd = document.getElementById('histDetail' + sessionId);
    if (dd.style.display !== 'none') { dd.style.display = 'none'; dd.classList.remove('show-wrong-only'); return; }
    document.querySelectorAll('.history-detail').forEach(d => { d.style.display = 'none'; d.classList.remove('show-wrong-only'); });
    if (dd.innerHTML) { dd.style.display = 'block'; dd.classList.remove('show-wrong-only'); return; }
    try {
      const detail = await apiFetch(`/api/history/${sessionId}`);
      const totalWrong = detail.answers.filter(a => !a.is_correct).length;
      dd.innerHTML = `
        <div class="detail-toggle-bar">
          <span class="detail-toggle-label">答题详情</span>
          <div class="detail-toggle-group">
            <button class="detail-toggle-btn active" data-filter="all">全部单词</button>
            <button class="detail-toggle-btn" data-filter="wrong">错误单词${totalWrong > 0 ? ' (' + totalWrong + ')' : ''}</button>
          </div>
        </div>
        <table class="detail-table"><thead><tr><th>#</th><th>中文</th><th>你的答案</th><th>正确答案</th><th></th></tr></thead><tbody>${detail.answers.map((a,i) => `<tr class="${a.is_correct?'correct-row':'wrong-row'}" data-is-correct="${a.is_correct}"><td>${i+1}</td><td class="zh">${escapeHtml(a.chinese)}</td><td class="${a.is_correct?'correct-ans':'user-ans'}">${escapeHtml(a.user_answer)}</td><td class="correct-ans">${escapeHtml(a.english)}</td><td class="icon">${icon(a.is_correct ? 'check' : 'x', 15)}</td></tr>`).join('')}</tbody></table>
        ${totalWrong > 0 ? `<button class="btn-retest-wrong" id="btnRetest-${sessionId}"><span style="display:inline-flex;vertical-align:-2px;margin-right:6px;">${icon('refresh-cw', 14)}</span>重新测验错误单词</button>` : ''}`;
      dd.style.display = 'block';
      // Bind toggle click handlers
      dd.querySelectorAll('.detail-toggle-btn').forEach(btn => {
        btn.addEventListener('click', function() {
          dd.querySelectorAll('.detail-toggle-btn').forEach(b => b.classList.remove('active'));
          this.classList.add('active');
          if (this.dataset.filter === 'wrong') {
            dd.classList.add('show-wrong-only');
          } else {
            dd.classList.remove('show-wrong-only');
          }
        });
      });
      // Bind retest button
      const retestBtn = dd.querySelector('.btn-retest-wrong');
      if (retestBtn && typeof startRetestQuiz === 'function') {
        retestBtn.addEventListener('click', () => {
          const wrongs = detail.answers.filter(a => !a.is_correct);
          startRetestQuiz(wrongs);
        });
      }
    } catch(e) { dd.innerHTML = '<div style="padding:12px;color:var(--terracotta);">加载详情失败</div>'; dd.style.display = 'block'; showToast('加载详情失败', { type: 'error' }); }
  }

  return { buildStatsScreen, switchTrendUnit, switchHistoryUnit, goHistoryPage, toggleHistoryDetail };
}

// Global toggle for group history error detail expansion
window.toggleGroupHistoryDetail = function(detailId, itemEl) {
  const detail = document.getElementById(detailId);
  if (!detail) return;
  const expand = itemEl.querySelector('.ghi-expand');
  if (detail.style.display === 'none') {
    detail.style.display = '';
    if (expand) expand.innerHTML = icon('chevron-up', 12);
  } else {
    detail.style.display = 'none';
    if (expand) expand.innerHTML = icon('chevron-down', 12);
  }
};
