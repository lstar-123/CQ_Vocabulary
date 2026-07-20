// ═══════════════════════════════════════════════════════════════════════════
// HISTORY — the ONLY database write in the entire group-learning flow.
// Called exclusively on completion events (group / round / unit).
// NEVER called from render, show, build, enter, start, restore, or resume.
// ═══════════════════════════════════════════════════════════════════════════

import { apiFetch } from '../api.js';
import { GroupLearning } from '../state/groupLearning.js';
import { currentUser } from '../state/auth.js';

export async function insertGroupHistory(eventType, extra = {}) {
  try {
    const duration = GroupLearning.roundStartTime
      ? Math.floor((Date.now() - GroupLearning.roundStartTime) / 1000) : null;
    const errorWords = GroupLearning.allErrorWords.length > 0
      ? GroupLearning.allErrorWords : null;
    await apiFetch('/api/group-learning/history', {
      method: 'POST',
      body: JSON.stringify({
        unit_id: GroupLearning.unitId,
        book_schema: GroupLearning.bookSchema,
        event_type: eventType,
        round_index: GroupLearning.activeRoundIndex,
        group_index: eventType === 'group_complete' ? GroupLearning.groupIndex : undefined,
        group_size: eventType === 'group_complete'
          ? (GroupLearning.currentGroup?.words.length ?? 0) : undefined,
        duration_seconds: duration,
        error_count: GroupLearning.allErrorWords.length,
        error_words: errorWords,
        finished_at: new Date().toISOString()
      })
    });
  } catch (e) { /* silent */ }
}

/**
 * Fetch completion status for a single unit from the history API.
 * Returns { maxCompletedRound, isUnitComplete } computed from immutable
 * history records.  Used for the overview screen only — NEVER for
 * position tracking.
 */
export async function fetchUnitCompletion(unitId) {
  try {
    const data = await apiFetch(
      `/api/group-learning/history?book_schema=${currentUser.current_book}&unit_id=${unitId}`
    );
    const maxComp = data.unit_max_completed_round?.[String(unitId)] ?? -1;
    const complete = data.unit_complete?.includes(unitId) ?? false;
    return { maxCompletedRound: maxComp, isUnitComplete: complete };
  } catch (e) { return { maxCompletedRound: -1, isUnitComplete: false }; }
}

export async function fetchAllUnitsCompletion() {
  try {
    const data = await apiFetch(
      `/api/group-learning/history?book_schema=${currentUser.current_book}`
    );
    return {
      unitMaxRound: data.unit_max_completed_round || {},
      unitComplete: new Set(data.unit_complete || [])
    };
  } catch (e) { return { unitMaxRound: {}, unitComplete: new Set() }; }
}
