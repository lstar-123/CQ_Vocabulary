# Milestone 4: Spelling Mode — Summary

> **Date**: 2026-07-24
> **Status**: COMPLETE — Pending Review
> **Scope**: Spelling Mode ONLY. No Quiz, Stats, Group Learning, Teacher.

---

## 1. 本阶段目标

- ✅ Spelling Screen: 中文提示 + 发音 → 输入英文 → 校对
- ✅ Shared AudioService (Flashcard + Spelling 共用)
- ✅ SpellingChecker: trim + lowercase 比较（Domain 层）
- ✅ SpellingNotifier (AsyncNotifier): 全部状态进入 Provider
- ✅ 自动 Focus、Enter=Submit、自动清空
- ✅ Submit / Skip / Replay / Prev / Next
- ✅ Correct ✅ / Wrong ❌ + 正确答案反馈
- ✅ CI: flutter analyze + flutter test + flutter build apk
- ❌ 未开发 Quiz / Stats / Group Learning / Teacher / 新 Backend API

---

## 2. 新增文件

| File | Purpose |
|------|---------|
| `lib/services/audio_service.dart` | Shared TTS service (wraps TtsRepository) |
| `lib/domain/models/spelling.dart` | `SpellingResult` + `SpellingChecker` |
| `lib/state/providers/spelling_provider.dart` | `SpellingNotifier` + `SpellingState` |
| `lib/features/spelling/spelling_screen.dart` | Full UI: prompt card + input + result banner + controls |
| `test/state/spelling_provider_test.dart` | SpellingChecker logic + SpellingState |
| `test/features/spelling_screen_test.dart` | Screen smoke tests |

## 3. 修改文件

| File | Change |
|------|--------|
| `lib/core/router/app_router.dart` | +spelling route, +SpellingParams |
| `lib/features/home/home_screen.dart` | +spelling icon button on each unit tile |

## 4. 架构

```
SpellingScreen (UI)
    │  watch(spellingNotifierProvider)
    ▼
SpellingNotifier (AsyncNotifier<SpellingState>)
    │
    ├── WordRepository.getWords()  ──▶ load words
    ├── AudioService.fetchAudio()  ──▶ TTS
    └── SpellingChecker.check()    ──▶ comparison (Domain layer)
    │
    ▼
SpellingState (immutable)
    words, currentIndex, results, currentInput, isPlaying, showResult
```

**UI 层不保存任何业务状态**，全部在 Provider 中。

## 5. SpellingChecker

```dart
abstract final class SpellingChecker {
  static bool check(String userAnswer, String correctAnswer) {
    return userAnswer.trim().toLowerCase() ==
           correctAnswer.trim().toLowerCase();
  }
}
```

UI 不负责字符串比较 — 调用 `SpellingChecker.check()`。

## 6. UI Flow

```
┌──────────────────────────────────────┐
│  AppBar: Unit Name                    │
├──────────────────────────────────────┤
│  ▓▓▓▓▓▓▓▓▓░░░░░░   3 / 10   ✓ 2     │  ← progress
│                                      │
│  ┌────────────────────────────────┐  │
│  │    ┌──────────────────┐       │  │
│  │    │  🔊 Tap to listen │       │  │
│  │    └──────────────────┘       │  │
│  │                                │  │
│  │          苹果                   │  │  ← Chinese prompt
│  │                                │  │
│  └────────────────────────────────┘  │
│                                      │
│  ┌─ Result (after submit) ─────────┐ │
│  │ ✅ Correct                      │ │
│  │ — or —                          │ │
│  │ ❌ Wrong                        │ │
│  │ Answer: apple                   │ │
│  └─────────────────────────────────┘ │
│                                      │
│  [___________Type English_________]  │  ← auto-focus
│                                      │
│  [  Skip  ]      [  Submit  ]       │  ← submit mode
│  [  Prev  ] [🔊] [  Next   ]        │  ← result mode
└──────────────────────────────────────┘
```

## 7. 输入体验

| 行为 | 实现 |
|------|------|
| 自动 Focus | `autofocus: true` + `_inputFocus.requestFocus()` |
| Enter = Submit | `onSubmitted: (_) => _submit()` |
| 下一题自动清空 | `_textCtrl.clear()` in `_next()` |
| 大小写不敏感 | `SpellingChecker.check()` trim + toLowerCase |

## 8. 统计

| | 数量 |
|----|------|
| 总 Dart | **71** (60 lib + 11 test) |
| M4 新增 | 6 files |
| M4 修改 | 2 files |

## 9. 下一阶段 (Milestone 5)

Quiz 迁移：答题模式 + 提交 + 结果页面。

---

## 10. 验证清单

- [ ] `flutter analyze` → 0 warning, 0 info
- [ ] `flutter test` → all green
- [ ] Home → unit card → ✏️ icon → Spelling Screen
- [ ] Chinese word displays + 🔊 tap plays audio
- [ ] Type answer → Submit → correct/incorrect feedback
- [ ] Skip → shows answer
- [ ] Prev / Next navigation works
- [ ] Case-insensitive matching
- [ ] Auto-focus on next word
- [ ] Release APK builds
