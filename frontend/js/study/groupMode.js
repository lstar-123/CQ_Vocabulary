// ==================== GROUP MODE ORCHESTRATION ====================
import { GroupLearning } from '../state/groupLearning.js';
import { fetchAllUnitsCompletion, fetchUnitCompletion } from '../repository/groupRepository.js';
import { ACTIVE_STRATEGY, buildRoundsFromWords, getTotalRoundsForUnit } from './groupBuilder.js';
import { escapeHtml } from '../utils.js';
import { apiFetch } from '../api.js';
import { currentUser } from '../state/auth.js';
import { icon } from '../ui/icons.js';

export function createGroupMode({ allUnits, GroupNavigator }) {

  async function buildGroupMode() {
    if (allUnits.length === 0) {
      const book = currentUser.current_book;
      try { const data = await apiFetch(`/api/units?book_schema=${book}`); allUnits.length = 0; allUnits.push(...data); } catch (e) {}
    }
    document.getElementById('catFilterChips').innerHTML = '';
    document.getElementById('studyToolbarInfo').textContent = '';
    document.getElementById('groupUnitSelect').style.display = '';
    document.getElementById('groupActive').style.display = 'none';
    GroupLearning.reset();
    renderGroupUnitOptions();
  }

  function renderGroupUnitOptions() {
    const container = document.getElementById('groupUnitOptions');
    if (allUnits.length === 0) {
      container.innerHTML = '<div class="no-data">暂无可用单元</div>';
      return;
    }
    container.innerHTML = '<div style="text-align:center;padding:20px;color:var(--text-muted);">加载中…</div>';
    fetchAllUnitsCompletion().then(({ unitMaxRound, unitComplete }) => {
      container.innerHTML = '<div class="group-unit-grid">' + allUnits.map(u => {
        const totalRounds = getTotalRoundsForUnit(u.word_count);
        const maxComp = unitMaxRound[String(u.id)] ?? -1;
        const isComplete = unitComplete.has(u.id);
        let roundLabel, roundCls;
        if (isComplete || (maxComp + 1 >= totalRounds)) {
          roundLabel = `${icon('check-circle', 12)} 已完成`; roundCls = 'completed';
        } else if (maxComp >= 0) {
          roundLabel = `第${maxComp + 2}/${totalRounds}轮`; roundCls = 'in-progress';
        } else {
          roundLabel = `${totalRounds}轮待学`; roundCls = 'not-started';
        }
        return `<div class="group-unit-card" data-unit="${u.id}">
          <div class="guc-icon">${icon('book', 32)}</div>
          <div class="guc-name">${escapeHtml(u.name)}</div>
          <div class="guc-count">${u.word_count} 个词汇</div>
          <span class="guc-round ${roundCls}">${roundLabel}</span>
        </div>`;
      }).join('') + '</div>';
    }).catch(() => {
      container.innerHTML = '<div class="group-unit-grid">' + allUnits.map(u => {
        const totalRounds = getTotalRoundsForUnit(u.word_count);
        return `<div class="group-unit-card" data-unit="${u.id}">
          <div class="guc-icon">${icon('book', 32)}</div>
          <div class="guc-name">${escapeHtml(u.name)}</div>
          <div class="guc-count">${u.word_count} 个词汇</div>
          <span class="guc-round not-started">${totalRounds}轮待学</span>
        </div>`;
      }).join('') + '</div>';
    });
  }

  function selectGroupUnit(unitId, el) {
    document.querySelectorAll('#groupUnitOptions .group-unit-card').forEach(o => o.classList.remove('selected'));
    el.classList.add('selected');
    GroupLearning.unitId = unitId;
    GroupLearning.unitName = allUnits.find(u => u.id === unitId)?.name || '';
    GroupLearning.bookSchema = currentUser.current_book;
    document.getElementById('groupUnitError').textContent = '';
    startGroupLearning();
  }

  async function startGroupLearning() {
    if (!GroupLearning.unitId) return;
    const book = currentUser.current_book;
    let words;
    try {
      words = await apiFetch(`/api/words?unit_ids=${GroupLearning.unitId}&book_schema=${book}`);
    } catch (e) {
      document.getElementById('groupUnitError').innerHTML = `${icon('x-circle', 14)} 加载词汇失败`;
      return;
    }
    if (!words || words.length === 0) {
      document.getElementById('groupUnitError').innerHTML = `${icon('x-circle', 14)} 该单元没有词汇`;
      return;
    }
    GroupLearning.words = words;
    GroupLearning.unitName = allUnits.find(u => u.id === GroupLearning.unitId)?.name || '';
    GroupLearning.rounds = buildRoundsFromWords(words, ACTIVE_STRATEGY);

    const completion = await fetchUnitCompletion(GroupLearning.unitId);
    GroupLearning.maxCompletedRound = completion.maxCompletedRound;
    GroupLearning.status = 'IN_PROGRESS';
    GroupLearning.hasStartedLearning = false;

    if (completion.isUnitComplete || GroupLearning.maxCompletedRound >= GroupLearning.rounds.length - 1) {
      GroupLearning.roundIndex = GroupLearning.rounds.length;
      GroupLearning.groupIndex = 0;
    } else if (GroupLearning.maxCompletedRound >= 0) {
      GroupLearning.roundIndex = GroupLearning.maxCompletedRound + 1;
      GroupLearning.groupIndex = 0;
    } else {
      GroupLearning.roundIndex = 0;
      GroupLearning.groupIndex = 0;
    }

    GroupLearning.unitStartTime = GroupLearning.unitStartTime || Date.now();
    GroupLearning.roundStartTime = Date.now();

    document.getElementById('groupUnitSelect').style.display = 'none';
    document.getElementById('groupActive').style.display = '';
    GroupNavigator.showOverview();
  }

  return { buildGroupMode, selectGroupUnit };
}
