// ==================== STUDY MODE ORCHESTRATION ====================
import { apiFetch } from '../api.js';
import { PlaybackController } from '../playback.js';
import { buildUnitChips, updateStudyToolbarInfo } from './unitFilter.js';
import { buildCardMode } from './cardMode.js';
import { buildListMode } from './listMode.js';
import { currentUser } from '../state/auth.js';

export function createStudyMode({ allUnits, allWordsGrouped, englishVisible, studyMode, buildGroupMode, exitGroupLearning }) {

  const LearningModes = {
    card: {
      enter() { buildUnitChips(allUnits, 'card'); updateStudyToolbarInfo(allUnits, allWordsGrouped); buildCardMode({ allWordsGrouped, allUnits }); },
      cleanup() { PlaybackController.destroy(); }
    },
    list: {
      enter() { buildUnitChips(allUnits, 'list'); buildListMode({ allWordsGrouped, englishVisible }); },
      cleanup() { PlaybackController.destroy(); }
    },
    group: {
      enter() { buildUnitChips(allUnits, 'group'); buildGroupMode(); },
      cleanup() { exitGroupLearning(); }
    }
  };

  async function switchStudyMode(mode) {
    if (studyMode.val !== mode) {
      const prev = LearningModes[studyMode.val];
      if (prev && prev.cleanup && await prev.cleanup() === false) return;
    }
    studyMode.val = mode;
    document.getElementById('btnCardMode').classList.toggle('active-sm', mode === 'card');
    document.getElementById('btnListMode').classList.toggle('active-sm', mode === 'list');
    document.getElementById('btnGroupMode').classList.toggle('active-sm', mode === 'group');
    document.getElementById('cardMode').style.display = mode === 'card' ? 'block' : 'none';
    document.getElementById('listMode').style.display = mode === 'list' ? 'block' : 'none';
    document.getElementById('groupMode').style.display = mode === 'group' ? 'block' : 'none';
    const handler = LearningModes[mode];
    if (handler) handler.enter();
  }

  async function buildStudyMode() {
    const book = currentUser.current_book;
    if (allWordsGrouped.length === 0) {
      const words = await apiFetch(`/api/words/all?book_schema=${book}`);
      allWordsGrouped.length = 0; allWordsGrouped.push(...words);
    }
    if (allUnits.length === 0) {
      try { const data = await apiFetch(`/api/units?book_schema=${book}`); allUnits.length = 0; allUnits.push(...data); } catch (e) {}
    }
    buildUnitChips(allUnits, studyMode.val);
    updateStudyToolbarInfo(allUnits, allWordsGrouped);
    const handler = LearningModes[studyMode.val];
    if (handler) handler.enter();
  }

  return { LearningModes, switchStudyMode, buildStudyMode };
}
