// ==================== GROUP RENDER ====================
import { escapeHtml } from '../utils.js';
import { GroupLearning } from '../state/groupLearning.js';
import { ensurePhonicsData } from '../state/phonics.js';

export function renderGroupOverview() {
  document.getElementById('groupOverviewTitle').textContent = '📖 ' + GroupLearning.unitName;

  const cards = document.getElementById('groupRoundCards');
  cards.innerHTML = GroupLearning.rounds.map((round, ri) =>
    renderRoundCard(ri, round, getRoundStatus(ri))
  ).join('');
}

/** Derive round status from GroupLearning position — uses maxCompletedRound
 *  as the permanent completion watermark.  Once a round is completed it can
 *  never revert to "in_progress" or "locked". */
export function getRoundStatus(roundIndex) {
  // Rounds ≤ maxCompletedRound are permanently completed
  if (roundIndex <= GroupLearning.maxCompletedRound) {
    // During re-learning, the re-learned round shows as in_progress
    if (GroupLearning.isRelearning && roundIndex === GroupLearning.relearnRoundIndex) {
      return 'in_progress';
    }
    return 'completed';
  }
  // First round after maxCompletedRound — unlocked (ready or in progress)
  if (roundIndex === GroupLearning.maxCompletedRound + 1) {
    // If the unit status is COMPLETED from a prior full completion,
    // this round is also completed (can happen when maxCompletedRound
    // was set from completed_at records but roundIndex is behind).
    if (GroupLearning.status === 'COMPLETED' && !GroupLearning.isRelearning) {
      return 'completed';
    }
    return 'in_progress';
  }
  // Beyond — still locked (shouldn't normally happen if maxCompletedRound
  // is correct, but handle gracefully)
  return 'locked';
}

export function renderRoundCard(ri, round, status) {
  const title = `第${ri + 1}轮（约${round.targetSize}词/组）`;
  const totalGroups = round.groups.length;

  const icons = { completed: '✅', in_progress: '🟢', locked: '🔒' };
  const statusLabels = {
    completed: '已完成', in_progress: '待学习', locked: '已锁定'
  };
  const statusCls = { completed: 'completed', in_progress: 'in-progress', locked: 'locked' };

  const pct = (status === 'completed') ? 100 : 0;

  let detailHTML = '';
  if (status === 'locked') {
    detailHTML = `🔒 完成第${ri}轮后解锁 · ${totalGroups} 组`;
  } else if (status === 'in_progress') {
    detailHTML = `${totalGroups} 组待完成`;
  } else {
    detailHTML = `${totalGroups} 组 · 全部通过`;
  }

  let btnHTML = '';
  if (status === 'in_progress') {
    const label = GroupLearning.hasStartedLearning ? '继续学习' : '开始记忆';
    btnHTML = `<button class="rc-btn start" data-round="${ri}">${label}</button>`;
  } else if (status === 'completed' && round.groups.length > 0) {
    btnHTML = `<button class="rc-btn retry" data-round="${ri}">重新学习</button>`;
  }

  return `
    <div class="round-card ${status}">
      <div class="rc-header">
        <span class="rc-icon">${icons[status]}</span>
        <span class="rc-title">${title}</span>
        <span class="rc-status ${statusCls[status]}">${statusLabels[status]}</span>
      </div>
      ${status !== 'locked' ? `
      <div class="rc-progress">
        <div class="rc-progress-fill" style="width:${pct}%"></div>
      </div>` : ''}
      <div class="rc-detail${status === 'locked' ? ' locked' : ''}">${detailHTML}</div>
      <div class="rc-btn-row">${btnHTML}</div>
    </div>`;
}

export function renderGroupLearning() {
  const group = GroupLearning.currentGroup;
  if (!group) {
    throw new Error(
      `[renderGroupLearning] currentGroup is null — ` +
      `roundIndex=${GroupLearning.roundIndex} ` +
      `groupIndex=${GroupLearning.groupIndex} ` +
      `activeRoundIndex=${GroupLearning.activeRoundIndex} ` +
      `rounds.length=${GroupLearning.rounds.length} ` +
      `currentRound=${GroupLearning.currentRound ? 'exists' : 'NULL'} ` +
      `currentRound.groups?.length=${GroupLearning.currentRound?.groups?.length ?? 'N/A'}`
    );
  }

  GroupLearning.mode = 'learning';
  GroupLearning.groupStartTime = Date.now();

  const activeRI = GroupLearning.activeRoundIndex;

  document.getElementById('groupOverview').style.display = 'none';
  document.getElementById('groupLearningArea').style.display = '';
  document.getElementById('groupLearningPhase').style.display = '';
  document.getElementById('groupSpellingPhase').style.display = 'none';
  document.getElementById('groupResult').style.display = 'none';

  const wrongSet = GroupLearning.wrongWordIndices;
  const hasErrors = wrongSet.size > 0;

  // ── Progress header ──
  document.getElementById('groupUnitLabel').textContent = '📖 ' + GroupLearning.unitName;
  document.getElementById('groupRoundLabel').textContent =
    `第${activeRI + 1}轮 · 组 ${group.groupIndex} / ${GroupLearning.totalGroups}`;
  document.getElementById('groupCounter').textContent =
    `本组 ${group.words.length} 词${hasErrors ? ` · ${wrongSet.size}个需加强` : ''}`;

  // Progress bar: within-round (completed groups / total groups this round)
  const roundTotal = GroupLearning.totalGroups;
  document.getElementById('groupProgressFill').style.width =
    roundTotal > 0 ? ((GroupLearning.groupIndex / roundTotal) * 100) + '%' : '0%';

  // ── Error banner ──
  const errBanner = document.getElementById('groupSpellError');
  if (hasErrors) {
    errBanner.textContent = `⚠️ 还有 ${wrongSet.size} 个单词需要加强`;
    errBanner.style.display = '';
  } else {
    errBanner.textContent = '';
    errBanner.style.display = 'none';
  }

  // ── Word cards ──
  const container = document.getElementById('groupWords');
  container.innerHTML = group.words.map((w, i) => {
    const wid = `gw-${GroupLearning.activeRoundIndex}-${GroupLearning.groupIndex}-${i}`;
    const errCls = wrongSet.has(i) ? ' gw-error' : '';
    return `
    <div class="group-word-card${errCls}" id="${wid}">
      <span class="gw-index">${i + 1}</span>
      <span class="gw-en" id="${wid}-en">${escapeHtml(w.english)}</span>
      <button class="gw-speak" data-word="${escapeHtml(w.english).replace(/'/g,"\\'")}" data-target="${wid}-en" title="发音">🔊</button>
      <span class="gw-zh">${escapeHtml(w.chinese)}</span>
    </div>`;
  }).join('');

  group.words.forEach(w => ensurePhonicsData(w.english));
}
