// ==================== GROUP CONTROLLER ====================
import { GroupLearning } from '../state/groupLearning.js';
import { PlaybackController } from '../playback.js';
import { checkEquivalent, escapeHtml, formatDurationMs } from '../utils.js';
import { insertGroupHistory } from '../repository/groupRepository.js';
import { getRoundStatus, renderRoundCard, renderGroupOverview, renderGroupLearning } from './groupRender.js';
import { startGroupSpelling as _startGroupSpelling } from './groupSpelling.js';

// ═══════════════════════════════════════════════════════════════════════════
// FACTORY — receives onExit callback to avoid importing quiz.html
// ═══════════════════════════════════════════════════════════════════════════

export function createGroupController({ onExit, onReset }) {

// ── GroupActions — user-facing action dispatch ──────────────────────────
const GroupActions = {
  startRound(ri) {
    RoundController.enter(ri);
  },
  exitToUnitList() {
    GroupNavigator.showUnitList();
  },
  startSpelling() {
    GroupNavigator.showSpelling();
  },
  returnToLearning() {
    GroupNavigator.showLearning();
  },
  checkAnswers() {
    submitGroupSpelling();
  },
  finishAndExit() {
    GroupLearning.reset();
    onExit();
  },
  advanceAfterPass() {
    advanceGroup();
  },
};

// ── RoundController — round status & card rendering ────────────────────
const RoundController = {
  getStatus(ri) { return getRoundStatus(ri); },
  isUnlocked(ri) { return getRoundStatus(ri) !== 'locked'; },
  enter(ri)     { enterRound(ri); },
  renderCard(ri, round) { return renderRoundCard(ri, round, this.getStatus(ri)); },
};

// ── GroupNavigator — single entry-point for ALL page transitions ───────
const GroupNavigator = {
  _hideAll() {
    document.getElementById('groupOverview').style.display = 'none';
    document.getElementById('groupLearningArea').style.display = 'none';
    document.getElementById('groupResult').style.display = 'none';
  },

  showOverview() {
    GroupLearning.mode = 'overview';
    this._hideAll();
    document.getElementById('groupOverview').style.display = '';
    renderGroupOverview();
  },

  showLearning() {
    GroupLearning.mode = 'learning';
    this._hideAll();
    document.getElementById('groupLearningArea').style.display = '';
    document.getElementById('groupLearningPhase').style.display = '';
    document.getElementById('groupResult').style.display = 'none';
    renderGroupLearning();
  },

  showSpelling() {
    GroupLearning.mode = 'spelling';
    GroupLearning.spellingResults = [];
    document.getElementById('groupOverview').style.display = 'none';
    document.getElementById('groupLearningArea').style.display = '';
    document.getElementById('groupLearningPhase').style.display = 'none';
    document.getElementById('groupSpellingPhase').style.display = '';
    document.getElementById('groupResult').style.display = 'none';
    document.getElementById('groupSpellError').textContent = '';
    _startGroupSpelling();
  },

  showGroupPass() {
    document.getElementById('groupResult').style.display = '';
    renderGroupResult();
  },

  showUnitList() {
    exitGroupLearning();
  }
};

// ── submitGroupSpelling ──────────────────────────────────────────────────

function submitGroupSpelling() {
  const group = GroupLearning.currentGroup;
  if (!group) return;

  const results = [];
  let allCorrect = true;
  group.words.forEach((w, i) => {
    const input = document.getElementById(`gsi-input-${i}`);
    const ua = input ? input.value.replace(/​/g, '').trim() : '';
    const ok = checkEquivalent(ua, w.english);
    if (!ok) allCorrect = false;
    results.push({ word: w, userAnswer: ua, isCorrect: ok });
  });
  GroupLearning.spellingResults = results;

  results.forEach((r, i) => {
    const item = document.getElementById(`gsi-${i}`);
    const rel  = document.getElementById(`gsi-result-${i}`);
    if (item) { item.classList.remove('correct', 'wrong'); item.classList.add(r.isCorrect ? 'correct' : 'wrong'); }
    if (rel)  { rel.textContent = r.isCorrect ? '✓' : '✗'; rel.style.color = r.isCorrect ? 'var(--success)' : 'var(--terracotta)'; }
  });

  // Accumulate errors across the entire unit session (deduplicated by english)
  const wrongWords = results.filter(r => !r.isCorrect).map(r => ({
    english: r.word.english, chinese: r.word.chinese
  }));
  const seen = new Set(GroupLearning.allErrorWords.map(w => w.english));
  wrongWords.forEach(w => {
    if (!seen.has(w.english)) {
      GroupLearning.allErrorWords.push(w);
      seen.add(w.english);
    }
  });

  if (allCorrect) {
    GroupLearning.wrongWordIndices = new Set();
    GroupLearning.mode = 'groupPass';
    GroupNavigator.showGroupPass();
  } else {
    // Track which words were wrong for feedback on return
    GroupLearning.wrongWordIndices = new Set(
      results.map((r, i) => r.isCorrect ? -1 : i).filter(i => i >= 0)
    );
    GroupNavigator.showLearning();
  }
}

// ── enterRound ────────────────────────────────────────────────────────────

function enterRound(roundIndex) {
  const prevStatus = getRoundStatus(roundIndex);
  const isRelearn = prevStatus === 'completed';

  // Always start from the beginning of the round
  GroupLearning.groupIndex = 0;

  if (isRelearn) {
    GroupLearning.isRelearning = true;
    GroupLearning.relearnRoundIndex = roundIndex;
  } else {
    GroupLearning.isRelearning = false;
    GroupLearning.roundIndex = roundIndex;
  }
  GroupLearning.wrongWordIndices = new Set();
  GroupLearning.allErrorWords = [];
  GroupLearning.hasStartedLearning = true;
  GroupLearning.roundStartTime = Date.now();
  GroupNavigator.showLearning();
  // NO database write.  Position is purely in-memory.
  // History is written ONLY when a group/round/unit is completed.
}

// ── renderGroupResult ─────────────────────────────────────────────────────

function renderGroupResult() {
  document.getElementById('groupOverview').style.display = 'none';
  document.getElementById('groupLearningArea').style.display = 'none';
  document.getElementById('groupResult').style.display = '';
  document.getElementById('groupSpellError').textContent = '';

  const icon   = document.getElementById('groupResultIcon');
  const title  = document.getElementById('groupResultTitle');
  const detail = document.getElementById('groupResultDetail');
  const errors = document.getElementById('groupResultErrors');
  const btn    = document.getElementById('btnGroupAdvance');

  const praises = ['🎉 Excellent!', 'Great Job!', 'Perfect!', 'Amazing!', '全部答对啦！', '继续保持！', '太棒了！'];
  const praise = praises[Math.floor(Math.random() * praises.length)];

  // ── Timing ──
  const now = Date.now();
  const unitMs = GroupLearning.unitStartTime ? (now - GroupLearning.unitStartTime) : 0;

  if (GroupLearning.isLastGroup && GroupLearning.isLastRound) {
    // ── Unit complete ──
    GroupLearning.mode = 'unitComplete';
    GroupLearning.status = 'COMPLETED';
    // INSERT immutable history record
    insertGroupHistory('unit_complete');
    const roundStats = GroupLearning.rounds.map((r, ri) =>
      `<div style="margin:4px 0;font-size:13px;color:var(--text-body);">第${ri+1}轮：${r.groups.length} 组</div>`
    ).join('');
    const totalG = GroupLearning.rounds.reduce((s,r) => s + r.groups.length, 0);
    icon.textContent = '🏆';
    title.textContent = 'Unit 完成！';
    detail.innerHTML = `
      <div style="margin:8px 0;">🎉 「${GroupLearning.unitName}」学习完毕！</div>
      ${roundStats}
      <div style="margin-top:8px;font-weight:600;color:var(--sage);">总计：${totalG} 组</div>
      <div style="margin-top:12px;padding-top:12px;border-top:1px solid var(--divider);">
        <div style="font-weight:600;font-size:13px;color:var(--text-headline);margin-bottom:4px;">⏱ 学习用时</div>
        <div style="display:flex;justify-content:space-between;padding:4px 0;font-size:13px;color:var(--text-body);"><span>整个 Unit</span><span style="font-weight:600;color:var(--text-headline);">${formatDurationMs(unitMs)}</span></div>
      </div>`;
    const results = GroupLearning.spellingResults;
    errors.innerHTML = results.length ? results.map(r => `
      <div style="display:flex;justify-content:space-between;align-items:center;padding:8px 12px;border-bottom:1px solid var(--divider);">
        <span style="font-weight:500;color:var(--text-headline);">${escapeHtml(r.word.english)}</span>
        <span style="font-size:12px;color:var(--text-muted);">${escapeHtml(r.word.chinese)}</span>
        <span style="color:var(--success);font-weight:600;">✅ 正确</span>
      </div>
    `).join('') : '';
    btn.textContent = '✅ 返回首页';
    btn.style.display = '';
    btn.setAttribute('data-action', 'finishAndExit');
  } else if (GroupLearning.isLastGroup) {
    // ── Round complete — insert immutable history record ──
    GroupLearning.mode = 'roundComplete';
    insertGroupHistory('round_complete');
    icon.textContent = '🎉';
    title.textContent = praise;
    detail.innerHTML = `
      <div>第${GroupLearning.activeRoundIndex + 1}轮完成！共${GroupLearning.totalGroups}组已全部通过</div>`;
    const results = GroupLearning.spellingResults;
    errors.innerHTML = results.map(r => `
      <div style="display:flex;justify-content:space-between;align-items:center;padding:8px 12px;border-bottom:1px solid var(--divider);">
        <span style="font-weight:500;color:var(--text-headline);">${escapeHtml(r.word.english)}</span>
        <span style="font-size:12px;color:var(--text-muted);">${escapeHtml(r.word.chinese)}</span>
        <span style="color:var(--success);font-weight:600;">✅ 正确</span>
      </div>
    `).join('');
    btn.textContent = '完成本轮 →';
    btn.style.display = '';
    btn.setAttribute('data-action', 'advanceAfterPass');
  } else if (GroupLearning.mode === 'groupPass') {
    // ── Normal group pass — show words with ✅ ──
    icon.textContent = '🎉';
    title.textContent = praise;
    const group = GroupLearning.currentGroup;
    detail.innerHTML = `
      <div>本组 ${group.words.length} / ${group.words.length} 全部拼写正确</div>`;
    const results = GroupLearning.spellingResults;
    errors.innerHTML = results.map(r => `
      <div style="display:flex;justify-content:space-between;align-items:center;padding:8px 12px;border-bottom:1px solid var(--divider);">
        <span style="font-weight:500;color:var(--text-headline);">${escapeHtml(r.word.english)}</span>
        <span style="font-size:12px;color:var(--text-muted);">${escapeHtml(r.word.chinese)}</span>
        <span style="color:var(--success);font-weight:600;">✅ 正确</span>
      </div>
    `).join('');
    btn.textContent = '继续下一组 →';
    btn.style.display = '';
    btn.setAttribute('data-action', 'advanceAfterPass');
  } else {
    // ── Fallback (shouldn't normally reach here) ──
    icon.textContent = '✅';
    title.textContent = `第${GroupLearning.currentGroup.groupIndex}组完成`;
    detail.innerHTML = `
      <div>${GroupLearning.currentGroup.words.length}个单词全部正确</div>`;
    errors.innerHTML = '';
    btn.textContent = '▶ 下一组';
    btn.style.display = '';
    btn.setAttribute('data-action', 'advanceAfterPass');
  }
}

// ── advanceGroup ──────────────────────────────────────────────────────────

function advanceGroup() {
  GroupLearning.wrongWordIndices = new Set();
  if (GroupLearning.mode === 'roundComplete') {
    if (GroupLearning.isRelearning) {
      // Re-learn finished — go back to overview, restore original position
      GroupLearning.isRelearning = false;
    } else {
      // Normal progression — this round is now permanently completed
      if (GroupLearning.roundIndex > GroupLearning.maxCompletedRound) {
        GroupLearning.maxCompletedRound = GroupLearning.roundIndex;
      }
      GroupLearning.roundIndex++;
    }
    GroupLearning.groupIndex = 0;
    // Reset timing for the next round
    GroupLearning.roundStartTime = Date.now();
    document.getElementById('btnGroupAdvance').style.display = '';
    GroupNavigator.showOverview();
    // NO database write — position is in-memory only.
  } else if (GroupLearning.mode === 'unitComplete') {
    GroupLearning.reset(); onReset(); return;
  } else {
    // Group complete — advance to next group, NO per-group DB write.
    // Only round_complete / unit_complete events are recorded.
    GroupLearning.groupIndex++;
    GroupNavigator.showLearning();
  }
  document.getElementById('groupResult').style.display = 'none';
}

// ── exitGroupLearning ─────────────────────────────────────────────────────

function exitGroupLearning() {
  const isMidRound = GroupLearning.hasStartedLearning &&
      GroupLearning.mode !== 'select' &&
      GroupLearning.mode !== 'unitComplete' &&
      GroupLearning.mode !== 'overview' &&
      GroupLearning.mode !== 'roundComplete';
  // Prompt user before exiting mid-round
  if (isMidRound) {
    if (!confirm('确定要退出吗？\n\n当前学习进度将不会保存，下次进入时需要重新开始本轮记忆。')) {
      return false;
    }
    // NO database writes.  All in-memory state is simply discarded.
    // Completed-round history was already saved on each completion event.
  }
  // Exiting from overview — also no DB write.  Position tracking is
  // purely in-memory; the user restarts from the last COMPLETED round
  // next time (derived from immutable history records).
  PlaybackController.destroy();
  GroupLearning.reset();
  document.getElementById('groupUnitSelect').style.display = '';
  document.getElementById('groupActive').style.display = 'none';
  return true;
}

return { GroupActions, RoundController, GroupNavigator, submitGroupSpelling, enterRound, advanceGroup, exitGroupLearning, renderGroupResult };
} // end createGroupController
