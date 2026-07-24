# Milestone 5: Quiz Module — Summary

> **Date**: 2026-07-24
> **Status**: COMPLETE — Pending Review
> **Scope**: Quiz ONLY. No Statistics, Group Learning, Teacher.

---

## 1. 项目进度表

| 模块 | Web | Flutter | 状态 |
|------|-----|---------|------|
| 登录/注册 | ✅ | ✅ | **已完成** (M2) |
| Splash + 自动登录 | ✅ | ✅ | **已完成** (M2) |
| Home + 词书选择 | ✅ | ✅ | **已完成** (M3) |
| Flashcard (卡片记忆) | ✅ | ✅ | **已完成** (M3) |
| Spelling (拼写练习) | ✅ | ✅ | **已完成** (M4) |
| **Quiz (测验)** | ✅ | ✅ | **本阶段完成** (M5) |
| Statistics (统计) | ✅ | ❌ | 未开始 |
| Group Learning (分组学习) | ✅ | ❌ | 未开始 |
| Teacher (教师管理) | ✅ | ❌ | 未开始 |
| Profile (个人信息) | ⚠️ | ❌ | 未开始 |
| APK Download | ✅ | N/A | **已完成** (M3) |

**Flutter 覆盖率**: 6/11 模块 (55%)

---

## 2. 本阶段目标

- ✅ Quiz 题型：英文 → 4 个中文选项
- ✅ QuizQuestionGenerator（Domain 层）：随机生成选项
- ✅ QuizNotifier（AsyncNotifier）：完整生命周期管理
- ✅ QuizState：immutable copyWith
- ✅ Quiz Screen：题目阶段 + 结果阶段
- ✅ 自动下一题（600ms 反馈延迟）
- ✅ 结果展示：分数环 + Correct/Wrong/Accuracy 统计卡
- ✅ Submit to Backend (POST /api/quiz/submit)
- ✅ Restart + Back Home
- ✅ 2 个测试文件
- ❌ 未开发 Statistics / Group Learning / Teacher

---

## 3. 新增文件

| File | Purpose |
|------|---------|
| `lib/domain/models/quiz_question.dart` | `QuizQuestion` + `QuizQuestionGenerator` |
| `lib/state/providers/quiz_provider.dart` | `QuizNotifier` + `QuizState` |
| `lib/features/quiz/quiz_screen.dart` | Quiz Screen (question + result phases) |
| `test/state/quiz_provider_test.dart` | Generator logic + state tests |
| `test/features/quiz_screen_test.dart` | Screen smoke tests |

## 4. 修改文件

| File | Change |
|------|--------|
| `lib/core/router/app_router.dart` | +quiz route + QuizParams |
| `lib/features/home/home_screen.dart` | +quiz icon on unit cards |

---

## 5. Quiz Architecture

```
QuizScreen
    │  watch(quizNotifierProvider)
    ▼
QuizNotifier (AsyncNotifier<QuizState>)
    │
    ├── WordRepository.getWords() ──▶ fetch words
    ├── QuizQuestionGenerator.generate() ──▶ create questions+options
    ├── QuizRepository.submitQuiz() ──▶ POST /api/quiz/submit
    │
    ▼
QuizState
    questions, currentIndex, selectedIndex,
    answers, isSubmitted, result, isSubmitting
```

**UI 不负责任何业务逻辑**：
- 选项生成 → `QuizQuestionGenerator.generate()` (Domain)
- 正确性判断 → `QuizQuestion.isCorrect(index)` (Domain)
- 提交 → `QuizNotifier.submit()` → `QuizRepository` → Backend

---

## 6. Quiz Flow

```
Home → Unit Card → 📝 icon → Quiz Screen
                                │
                    Load words → Generate questions
                                │
                    ┌───────────┴───────────┐
                    ▼                       ▼
              [English word]          Progress N/M
                    │
                    ▼
        ┌─────────────────────────┐
        │  苹果  │  香蕉  │  橙子  │  葡萄  │
        └─────────────────────────┘
                    │
              Tap an option
                    │
          ┌─────────┴─────────┐
          ▼ (600ms)           ▼
    Correct (green)      Wrong (red)
          │                    │
          ▼                    ▼
      Auto-next           Auto-next
          │
    ...after last question...
          │
          ▼
    ┌──────────────┐
    │  Score: 85%  │
    │  ✓ 8  ✗ 2   │
    │              │
    │ [Save]       │ → POST /api/quiz/submit
    │ [Restart]    │
    │ [Back Home]  │
    └──────────────┘
```

---

## 7. QuizQuestionGenerator

```dart
// Domain layer — client-side question generation.
// For each word:
//   1 correct Chinese + 3 random distractors from pool
//   4 options shuffled
//   correctIndex tracked
QuizQuestionGenerator.generate(words, shuffle: true)
```

**测试覆盖**：
- 每词一题
- 每题 4 个选项
- correctIndex 始终指向正解
- shuffle 有效
- 少于 4 个唯一中文词时不会崩溃

---

## 8. Known Technical Debt

| # | 问题 | 原因 | 建议解决 Milestone |
|---|------|------|-------------------|
| 1 | **Quiz History 页面未实现** | HistoryRepository 已就绪，UI 未构建单独的回顾页面 | M7+ (或独立 History Milestone) |
| 2 | **Quiz 仅支持单选 Unit** | 当前 Unit 选择只传单个 unitId。后端支持多 unit 逗号分隔 | 可改 QuizParams 支持多选，低风险 |
| 3 | **Audio 播放未集成 audioplayers** | 当前 TTS 仅 fetch bytes，用 SnackBar 反馈。需引入 just_audio 或 audioplayers 包实现实际播放 | M6 前（影响 Flashcard + Spelling + Quiz 三模块） |
| 4 | **Quiz 选项可能重复** | 当单词池中文词少于 4 个不同值时，选项可能有重复。Web 版同样有这个问题 | 如需修复，Domain 层逐出已选 distractor |
| 5 | **离线模式未实现** | 所有 Repository 直连 Remote，未预留 Local fallback | 后续 Milestone（离线优先架构） |
| 6 | **Cookie 过期静默失败** | Session 过期后 API 返回 401，AuthInterceptor 捕获但未自动弹出重新登录 | M6 前完善 AuthInterceptor |
| 7 | **Flutter 未实现教师端** | 优先级低于学生端核心学习流程 | 学习流程全完成后 |

---

## 9. 统计

| | 数量 |
|----|------|
| 总 Dart | **76** (63 lib + 13 test) |
| M5 新增 | 5 files |
| M5 修改 | 2 files |

---

## 10. 下一阶段 (Milestone 6)

Statistics 迁移：统计图表（趋势图 + 摘要 + 分组学习历史）。

---

## 11. 验证清单

- [ ] `flutter analyze` → 0 warning, 0 info
- [ ] `flutter test` → all green (13 suites)
- [ ] Home → unit card → 📝 icon → Quiz Screen
- [ ] English word displays + 4 Chinese options
- [ ] Tap correct → green highlight → auto-advance
- [ ] Tap wrong → red highlight + correct answer shown → auto-advance
- [ ] After last question → result screen with score circle
- [ ] Save button → submits to backend
- [ ] Restart → new quiz with re-shuffled questions
- [ ] Back Home → returns to unit list
- [ ] Release APK builds
