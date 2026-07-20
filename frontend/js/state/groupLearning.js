// ---- State — four-layer separation ---------------------------------------

// Layer 1 — Progress (persisted to DB): position + session metadata
// Layer 2 — Runtime  (regenerated from words on every page load)
// Layer 3 — UI       (transient, never persisted)
// Layer 4 — Session  (attempt tracking, timestamps)

export const GroupLearning = {
  // ── Progress (persisted) ────────────────────────────────────────────
  unitId: null,
  bookSchema: null,
  roundIndex: 0,
  groupIndex: 0,
  status: 'IN_PROGRESS',    // IN_PROGRESS | COMPLETED | ABANDONED
  maxCompletedRound: -1,    // highest round index ever COMPLETED (permanent watermark)

  // ── Runtime (derived from words — regenerated on load) ──────────────
  unitName: null,
  words: [],
  rounds: [],

  // ── UI (transient) ──────────────────────────────────────────────────
  mode: 'select',
  spellingResults: [],
  wrongWordIndices: new Set(),   // indices of words failed in last spelling
  allErrorWords: [],             // [{english, chinese}] accumulated across unit session
  hasStartedLearning: false,     // true only after user clicks "开始记忆" (enterRound)
  isRelearning: false,           // true when re-learning a completed round
  relearnRoundIndex: 0,          // which round is being re-learned

  // ── Timing (UI session — never persisted) ───────────────────────────
  unitStartTime: null,     // set when unit learning begins
  roundStartTime: null,    // set when entering a round
  groupStartTime: null,    // set when entering a group (learning phase)

  // ── Computed ────────────────────────────────────────────────────────
  get activeRoundIndex() {
    return this.isRelearning ? this.relearnRoundIndex : this.roundIndex;
  },
  get currentRound() { return this.rounds[this.activeRoundIndex]; },
  get currentGroup() { return this.currentRound?.groups[this.groupIndex]; },
  get totalGroups()  { return this.currentRound?.groups.length ?? 0; },
  get isLastGroup()  { return this.groupIndex >= this.totalGroups - 1; },
  get isLastRound()  { return this.activeRoundIndex >= this.rounds.length - 1; },

  // ── Reset ───────────────────────────────────────────────────────────
  reset() {
    this.unitId = null; this.bookSchema = null;
    this.roundIndex = 0; this.groupIndex = 0;
    this.status = 'IN_PROGRESS';
    this.maxCompletedRound = -1;
    this.unitName = null; this.words = []; this.rounds = [];
    this.mode = 'select'; this.spellingResults = [];
    this.wrongWordIndices = new Set();
    this.allErrorWords = [];
    this.hasStartedLearning = false;
    this.isRelearning = false; this.relearnRoundIndex = 0;
    this.unitStartTime = null; this.roundStartTime = null; this.groupStartTime = null;
  }
};

