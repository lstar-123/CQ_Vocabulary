// ==================== AUTH STATE ====================

export let currentUser = null;

// ── Future accessors (not yet adopted by callers) ─────────────────────

export function getCurrentUser() { return currentUser; }
export function setCurrentUser(user) { currentUser = user; }
export function clearCurrentUser() { currentUser = null; }
