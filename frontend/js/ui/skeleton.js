// ==================== SKELETON LOADERS ====================
// Pure HTML string builders — no values, no events.
// Shapes mimic the real components they replace while loading.

/** Mimics a `.unit-option` row. */
export function skeletonUnitOption() {
  return `
    <div class="unit-option" aria-hidden="true">
      <div class="skeleton skeleton-check"></div>
      <div class="skeleton skeleton-unit-icon"></div>
      <div class="unit-info">
        <div class="skeleton skeleton-line" style="width:55%;height:15px;"></div>
        <div class="skeleton skeleton-line" style="width:30%;height:12px;margin-top:8px;"></div>
      </div>
    </div>`;
}

/** Mimics a `.stats-summary-card`. */
export function skeletonStatsCard() {
  return `
    <div class="stats-summary-card" aria-hidden="true">
      <div class="skeleton skeleton-block" style="width:56px;height:32px;margin:0 auto;"></div>
      <div class="skeleton skeleton-line" style="width:70%;height:12px;margin:10px auto 0;"></div>
    </div>`;
}

/** Mimics a `.history-item` row. */
export function skeletonHistoryRow() {
  return `
    <div class="history-item" aria-hidden="true">
      <div class="hi-card-header">
        <div class="skeleton skeleton-line" style="width:45%;height:16px;"></div>
        <div class="skeleton skeleton-block" style="width:64px;height:28px;border-radius:999px;"></div>
      </div>
      <div class="hi-card-stats">
        <div class="skeleton skeleton-block" style="height:52px;"></div>
        <div class="skeleton skeleton-block" style="height:52px;"></div>
        <div class="skeleton skeleton-block" style="height:52px;"></div>
      </div>
      <div class="skeleton skeleton-line" style="width:35%;height:11px;"></div>
    </div>`;
}
