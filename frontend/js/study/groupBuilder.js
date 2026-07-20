// ==================== GROUP LEARNING BUILDER ====================

import { shuffleArray } from '../utils.js';

// ── Strategy Configuration ───────────────────────────────────────────────
// All magic numbers live here.  Adding a new strategy (CEFR, frequency,
// AI-recommended) means adding one entry — no business-logic changes.
export const GROUP_STRATEGIES = {
  default: {
    name: 'fixed_group',
    version: 2,              // v2: partition by unit list order (no shuffle)
    tiers: [2, 3, 5],
    partition: { min: 2, max: 12 },
    shuffleWords: false      // keep unit's original word order
  }
};

export const ACTIVE_STRATEGY = GROUP_STRATEGIES.default;

/**
 * Build rounds from words and a strategy definition.
 * Each round covers ALL words exactly once — zero duplicates, zero omissions.
 *
 * Flow: orderedWords → (shuffle once if strategy says so) → partition → groups
 *
 * @param {Array}  words    Word objects in textbook order
 * @param {object} strategy { name, version, tiers, partition, shuffleWords }
 * @returns {Array<{targetSize:number, groups:Array}>}
 */
export function buildRoundsFromWords(words, strategy) {
  const n = words.length;
  const tiers = strategy.tiers;
  const config = strategy.partition;

  // ── Shuffle once per build — all rounds share the same order ──
  const ordered = strategy.shuffleWords ? shuffleArray(words) : words;

  // ── Single tier (all words fit in smallest target) ──
  if (n <= tiers[0]) {
    const groups = buildGroups(ordered, n, config);
    _validateGroups(groups, n);
    return [{ targetSize: n, groups }];
  }

  // ── Two tiers ──
  if (n <= tiers[1]) {
    const r1 = buildGroups(ordered, tiers[0], config);
    const r2 = buildGroups(ordered, n, config);
    _validateGroups(r1, n);
    _validateGroups(r2, n);
    return [
      { targetSize: tiers[0], groups: r1 },
      { targetSize: n,        groups: r2 }
    ];
  }

  // ── Full three tiers ──
  const rounds = tiers.map(t => {
    const groups = buildGroups(ordered, t, config);
    _validateGroups(groups, n);
    return { targetSize: t, groups };
  });
  return rounds;
}

/**
 * Build balanced groups by consecutive partitioning.
 * O(n). All group sizes within [config.min, config.max].
 *
 * @param {Array}  words      Ordered word array (already shuffled if needed)
 * @param {number} targetSize Desired words per group
 * @param {object} config     { min: number, max: number }
 * @returns {Array<{groupIndex:number, words:Array}>}
 */
export function buildGroups(words, targetSize, config) {
  const n = words.length;
  let numGroups = Math.round(n / targetSize) || 1;
  let baseSize  = Math.floor(n / numGroups);
  let remainder = n % numGroups;

  // Ensure last group isn't too small
  const lastIdx  = numGroups - 1;
  const lastSize = baseSize + (lastIdx < remainder ? 1 : 0);
  if (lastSize < config.min && numGroups > 1) {
    numGroups--;
    baseSize  = Math.floor(n / numGroups);
    remainder = n % numGroups;
  }

  const groups = [];
  let start = 0;
  for (let i = 0; i < numGroups; i++) {
    const size = baseSize + (i < remainder ? 1 : 0);
    groups.push({ groupIndex: i + 1, words: words.slice(start, start + size) });
    start += size;
  }
  return groups;
}

/**
 * Development-time assertion: every word appears exactly once.
 * Throws on duplicate or missing words — catches builder bugs immediately.
 */
export function _validateGroups(groups, expectedCount) {
  const all = groups.flatMap(g => g.words);
  if (all.length !== expectedCount) {
    console.error('[Builder] Word count mismatch:', all.length, 'vs expected', expectedCount);
    throw new Error(`[Builder] Group word count ${all.length} != expected ${expectedCount}`);
  }
  const ids = all.map(w => w.id);
  const idSet = new Set(ids);
  if (idSet.size !== expectedCount) {
    const dupes = ids.filter((id, i) => ids.indexOf(id) !== i);
    console.error('[Builder] Duplicate word IDs detected:', [...new Set(dupes)]);
    throw new Error(`[Builder] Duplicate words: ${idSet.size} unique vs ${expectedCount} expected`);
  }
}

/** Calculate total number of rounds a unit would have based on word count. */
export function getTotalRoundsForUnit(wordCount) {
  const tiers = ACTIVE_STRATEGY.tiers;
  if (wordCount <= tiers[0]) return 1;
  if (wordCount <= tiers[1]) return 2;
  return tiers.length;
}
