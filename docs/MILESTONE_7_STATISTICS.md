# Milestone 7: Statistics Dashboard — Summary

> **Date**: 2026-07-24
> **Status**: COMPLETE — Pending Review
> **Design**: Mobile-first, Material 3, Google Fit / Duolingo style

---

## 1. 项目进度表

| 模块 | Web | Flutter | 状态 |
|------|-----|---------|------|
| 登录/注册 | ✅ | ✅ | M2 |
| Home + 词书 | ✅ | ✅ | M3 |
| Flashcard | ✅ | ✅ | M3 |
| Spelling | ✅ | ✅ | M4 |
| Quiz | ✅ | ✅ | M5 |
| Audio (TTS) | ✅ | ✅ | M6 |
| Quiz History | ✅ | ✅ | M6 |
| **Statistics** | ✅ | ✅ | **M7** |
| Group Learning | ✅ | ❌ | 未开始 |
| Teacher | ✅ | ❌ | 未开始 |

**Flutter 覆盖率**: 8/10 (80%)

---

## 2. 本阶段目标

- ✅ StatisticsNotifier: 聚合 3 个后端 API → 单一 StatisticsState
- ✅ StatisticsState: immutable, computed properties (weeklyActivity, recentTrend, estimatedStreak)
- ✅ SummaryHeader: Hero card with gradient + 3 key metrics
- ✅ AccuracyChart: fl_chart line chart, last 7 days, gradient fill
- ✅ WeeklyChart: fl_chart bar chart, 7 days word counts
- ✅ DistributionDonut: fl_chart pie chart, Quiz vs Group Study breakdown
- ✅ RecentQuizzes: 5 recent quiz cards with scores
- ✅ Pull-to-refresh
- ✅ Empty state (📚 illustration)
- ✅ Error state (retry card, not SnackBar)
- ✅ Home: Statistics + History entry cards side-by-side
- ✅ 2 测试文件
- ❌ 未新增 Backend API

---

## 3. 新增文件

| File | Purpose |
|------|---------|
| `lib/state/providers/statistics_provider.dart` | StatisticsNotifier + StatisticsState |
| `lib/features/stats/stats_screen.dart` | Main dashboard layout |
| `lib/features/stats/widgets/summary_header.dart` | Hero summary card |
| `lib/features/stats/widgets/accuracy_chart.dart` | Line chart (fl_chart) |
| `lib/features/stats/widgets/weekly_chart.dart` | Bar chart (fl_chart) |
| `lib/features/stats/widgets/distribution_donut.dart` | Donut chart (fl_chart) |
| `lib/features/stats/widgets/recent_quizzes.dart` | Recent quiz card list |
| `test/state/statistics_provider_test.dart` | State + computed properties tests |
| `test/features/stats_screen_test.dart` | Screen smoke tests |

## 4. 修改文件

| File | Change |
|------|--------|
| `lib/core/router/app_router.dart` | Stats placeholder → real StatsScreen |
| `lib/features/home/home_screen.dart` | +Statistics + History entry cards (side by side) |

---

## 5. Dashboard Layout

```
┌─────────────────────────────────┐
│  Statistics              [↻]   │  ← AppBar
├─────────────────────────────────┤
│  ┌─ Summary Hero Card ────────┐ │
│  │  📊 Study Summary          │ │
│  │                            │ │
│  │  📖 1,250    📝 52    📈 85%│ │
│  │   Words      Quizzes  Avg  │ │
│  └────────────────────────────┘ │
│                                 │
│  Accuracy Trend                 │
│  ┌────────────────────────────┐ │
│  │  ╱╲    ╱╲                 │ │
│  │ ╱  ╲╱╱  ╲    ╱╲         │ │
│  │╱        ╲╲╱╱  ╲╱        │ │  ← Line chart
│  └────────────────────────────┘ │
│                                 │
│  Weekly Activity                │
│  ┌────────────────────────────┐ │
│  │ ██                        │ │
│  │ ██ ██    ██               │ │
│  │ ██ ██ ██ ██ ██    ██     │ │  ← Bar chart
│  │ Mo Tu We Th Fr Sa Su      │ │
│  └────────────────────────────┘ │
│                                 │
│  Learning Distribution          │
│  ┌────────────────────────────┐ │
│  │  ◉ Quiz      52 sessions  │ │
│  │  ◉ Group     18 sessions  │ │  ← Donut chart
│  │  ◉ Units     12 done      │ │
│  └────────────────────────────┘ │
│                                 │
│  Recent Quizzes        See All │
│  ┌────────────────────────────┐ │
│  │ 85% Unit 1,2  ✓ 8/10     │ │
│  │ 92% Unit 3    ✓ 12/13    │ │  ← Cards
│  │ 78% Unit 1    ✓ 7/9      │ │
│  └────────────────────────────┘ │
└─────────────────────────────────┘
```

---

## 6. Data Flow

```
StatsScreen
    │  watch(statisticsNotifierProvider)
    ▼
StatisticsNotifier.build()
    │  Future.wait([
    │    StatsRepository.getSummary(),
    │    StatsRepository.getTrend(),
    │    StatsRepository.getGroupHistory(),
    │  ])
    ▼
StatisticsState (immutable)
    ├── summary: StudySummary
    ├── trend: List<ScoreTrend>
    ├── recentRecords: List<LearningRecord>
    ├── recentTrend → computed (last 7)
    ├── weeklyActivity → computed (WeekDay[])
    └── estimatedStreak → computed
```

**UI 层零计算** — 所有 computed properties 在 `StatisticsState` 中。

---

## 7. Updated Technical Debt

| # | 问题 | 状态 |
|---|------|------|
| ~~Statistics 未实现~~ | ✅ M7 |
| Group Learning | ⬜ 未来 |
| Teacher | ⬜ 未来 |
| Cookie 过期静默失败 | ⬜ 低优先级 |
| 离线模式 | ⬜ 未来 |
| Quiz 选项重复（少词时） | ⬜ 低优先级 |

---

## 8. 统计

| | 数量 |
|----|------|
| 总 Dart | **89** (72 lib + 17 test) |
| M7 新增 | 9 files |
| M7 修改 | 2 files |

---

## 9. 下一阶段

Group Learning 迁移，或用户指定的其它模块。

---

## 10. 验证清单

- [ ] `flutter analyze` → 0 warning, 0 info
- [ ] `flutter test` → all green (17 suites)
- [ ] Home → "Statistics" card → Dashboard opens
- [ ] SummaryHero shows Words / Quizzes / Avg Score
- [ ] AccuracyChart renders line with gradient fill
- [ ] WeeklyChart shows 7-day bar chart
- [ ] DistributionDonut shows Quiz vs Group split
- [ ] RecentQuizzes shows up to 5 recent sessions
- [ ] Pull-to-refresh reloads all data
- [ ] Empty state (no data) shows 📚 illustration
- [ ] Error state shows retry card (not SnackBar)
- [ ] Dark mode renders correctly
- [ ] Release APK builds
