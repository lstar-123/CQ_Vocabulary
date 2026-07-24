# Milestone 8: Group Learning — Summary

> **Date**: 2026-07-24
> **Status**: COMPLETE — Pending Review
> **Design**: Anki/Mochi-inspired, linear flow, card animations

---

## 1. 项目进度表

| 模块 | Web | Flutter | 状态 |
|------|-----|---------|------|
| 登录/Home/Flashcard | ✅ | ✅ | M2-M3 |
| Spelling/Quiz | ✅ | ✅ | M4-M5 |
| Audio/History | ✅ | ✅ | M6 |
| Statistics | ✅ | ✅ | M7 |
| **Group Learning** | ✅ | ✅ | **M8** |
| Teacher | ✅ | ❌ | 未开始 |

**Flutter 覆盖率**: 9/10 (90%)

---

## 2. 本阶段目标

- ✅ GroupLearningNotifier (AsyncNotifier) — 全流程状态机
- ✅ GroupLearningState (immutable) — 5 个 Phase
- ✅ Memory Phase — Anki 卡片翻转 + Remember/Forgot
- ✅ Spelling Phase — 拼写校对（复用 SpellingChecker）
- ✅ Wrong Review — 错词队列重新测试
- ✅ Summary — Hero 卡片展示 Groups/Words/Correct/Time
- ✅ Progress Bar — 实时 Group N/M + remembered/total
- ✅ 线性流程 — 减少跳转，自动推进
- ✅ Unit card 新增 Group Study 入口
- ✅ 2 个测试文件
- ❌ 未新增 Backend API

---

## 3. Phase 状态机

```
loading ──▶ memory ──▶ spelling ──▶ [wrongReview] ──▶ summary
              │           │              │
              ▼           ▼              ▼
         Remembered   Submit answer   Got it / Still Wrong
         Forgot       Auto-advance    Auto-advance
```

**Linear flow** — no branching:
1. `memory`: card flip → mark Remembered/Forgot → auto-advance
2. `spelling`: Chinese prompt → type English → Next
3. `wrongReview` (if any wrong): re-test → mark Got it/Still Wrong
4. `summary`: stats card → Done → Home

---

## 4. 新增文件

| File | Purpose |
|------|---------|
| `lib/state/providers/group_learning_provider.dart` | GroupLearningNotifier + State |
| `lib/features/group/group_screen.dart` | Full screen: 5 phase widgets |
| `test/state/group_learning_provider_test.dart` | State + provider tests |
| `test/features/group_screen_test.dart` | Screen smoke tests |

## 5. 修改文件

| File | Change |
|------|--------|
| `lib/core/router/app_router.dart` | +group route |
| `lib/features/home/home_screen.dart` | +Group Study icon on unit cards |

---

## 6. Memory Phase UX (Anki-inspired)

```
┌────────────────────────────────┐
│  Group 1 / 5           ✓ 3/20  │  ← progress
│  ████████░░░░                  │
├────────────────────────────────┤
│                                │
│          apple                 │  ← English (front)
│                                │
│      ┌──────────────┐         │
│      │ Tap to reveal │         │
│      └──────────────┘         │
│                                │
│           ⬇ tap                │
│                                │
│          🔊                    │
│          苹果                   │  ← Chinese (back)
│          apple                 │
│                                │
│   [Forgot]    [Remembered]    │
└────────────────────────────────┘
```

---

## 7. HomeScreen Unit Card

```
┌──────────────────────────────────────┐
│ 📖 Unit 1                            │
│    20 words    🧩  📝  ✏️  [>]      │
│               Group Quiz Spell       │
└──────────────────────────────────────┘
```

---

## 8. Updated Technical Debt

| # | 问题 | 状态 |
|---|------|------|
| ~~Statistics 未实现~~ | ✅ M7 |
| ~~Group Learning 未实现~~ | ✅ M8 |
| Teacher | ⬜ 未来 |
| Cookie 过期静默 | ⬜ 低优 |
| 离线模式 | ⬜ 未来 |

---

## 9. 统计

| | 数量 |
|----|------|
| 总 Dart | **93** (74 lib + 19 test) |
| M8 新增 | 4 files |
| M8 修改 | 2 files |

---

## 10. 验证清单

- [ ] `flutter analyze` → 0 warning, 0 info
- [ ] `flutter test` → all green (19 suites)
- [ ] Home → unit card → 🧩 icon → Group Learning
- [ ] Memory: card flips on tap → Remembered/Forgot buttons
- [ ] Spelling: Chinese prompt → type English → Correct/Wrong feedback
- [ ] Wrong Review: red banner → re-test wrong words
- [ ] Summary: score circle + stats cards → Done
- [ ] Progress bar updates across all phases
- [ ] Close (X) exits and resets properly
- [ ] Dark mode renders correctly
- [ ] Release APK builds
