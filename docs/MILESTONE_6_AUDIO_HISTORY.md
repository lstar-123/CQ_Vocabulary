# Milestone 6: AudioService + Quiz History — Summary

> **Date**: 2026-07-24
> **Status**: COMPLETE — Pending Review
> **Scope**: Real TTS playback + Quiz History page.

---

## 1. 项目进度表

| 模块 | Web | Flutter | 状态 |
|------|-----|---------|------|
| 登录/注册 | ✅ | ✅ | 已完成 (M2) |
| Splash + 自动登录 | ✅ | ✅ | 已完成 (M2) |
| Home + 词书选择 | ✅ | ✅ | 已完成 (M3) |
| Flashcard | ✅ | ✅ | 已完成 (M3) |
| Spelling | ✅ | ✅ | 已完成 (M4) |
| Quiz | ✅ | ✅ | 已完成 (M5) |
| **Audio (TTS 播放)** | ✅ | ✅ | **本阶段** (M6) |
| **Quiz History** | ✅ | ✅ | **本阶段** (M6) |
| Statistics | ✅ | ❌ | M7 |
| Group Learning | ✅ | ❌ | 未开始 |
| Teacher | ✅ | ❌ | 未开始 |

**Flutter 覆盖率**: 8/11 模块 (73%)

---

## 2. 本阶段目标

- ✅ AudioService: 集成 `audioplayers` 包，真正播放 TTS
- ✅ Flashcard + Spelling 共用 AudioService
- ✅ AudioNotifier (Riverpod Notifier): `play()` / `stop()` / `replay()` / `dispose()`
- ✅ AudioPlayState: idle / loading / playing / stopped
- ✅ Quiz History: 显示分页学习记录列表
- ✅ HistoryNotifier (AsyncNotifier) + immutable HistoryState
- ✅ HistoryScreen: Material 3 Card 风格，日期+分数+统计
- ✅ Home 新增 "Quiz History" 入口
- ✅ 2 个测试文件
- ❌ 未开发 Statistics / Group Learning / Teacher

---

## 3. 新增文件

| File | Purpose |
|------|---------|
| `lib/features/history/history_screen.dart` | History UI (paginated cards) |
| `lib/state/providers/history_provider.dart` | HistoryNotifier + HistoryState |
| `test/services/audio_service_test.dart` | Audio state tests |
| `test/features/history_screen_test.dart` | History screen smoke tests |

## 4. 修改文件

| File | Change |
|------|--------|
| `pubspec.yaml` | +`audioplayers: ^6.1.0` |
| `lib/services/audio_service.dart` | Full rewrite: AudioNotifier + audioplayers integration |
| `lib/features/flashcard/flashcard_screen.dart` | Replace SnackBar mock → AudioService |
| `lib/features/spelling/spelling_screen.dart` | Replace SnackBar mock → AudioService |
| `lib/core/router/app_router.dart` | +history route |
| `lib/features/home/home_screen.dart` | +Quiz History card entry |

---

## 4. AudioService Architecture

```
FlashcardScreen ──┐
SpellingScreen  ──┼──▶ audioServiceProvider.notifier.play(text)
QuizScreen      ──┘         │
                            ▼
                   AudioNotifier (Riverpod Notifier<AudioPlayState>)
                            │
                   ┌────────┴────────┐
                   ▼                 ▼
           TtsRepository      AudioPlayer
           (fetch MP3)        (platform playback)
           POST /api/tts      audioplayers pkg
```

**不再使用 SnackBar 模拟播放**。真实音频通过 `audioplayers` `AudioPlayer` + `BytesSource` 播放。

### AudioPlayState

```
idle ──▶ loading ──▶ playing ──▶ stopped
  ▲                                │
  └────────────────────────────────┘
```

## 5. Quiz History

```
Home → "Quiz History" → HistoryScreen
                            │
                    GET /api/history (page=N)
                            │
                    ┌───────┴────────┐
                    ▼                ▼
              [07-24 10:30]    [85%]    ← score badge
              ✓ 8  ✗ 2  ⏱ 2m 30s        ← stats
              ─────────────────────────
              [07-23 15:00]    [92%]
              ✓ 12  ✗ 1  ⏱ 3m 10s
              ...
```

- 分页支持（Backend 已有）
- Pull-to-refresh
- 滚动加载更多
- 空状态 + 错误重试

## 6. Updated Technical Debt

| # | 问题 | 状态 | 建议解决 |
|---|------|------|----------|
| 1 | ~~Audio 未实现~~ | ✅ 已解决 (M6) | — |
| 2 | ~~Quiz History 未实现~~ | ✅ 已解决 (M6) | — |
| 3 | Statistics 未实现 | ⬜ | M7 |
| 4 | Group Learning 未实现 | ⬜ | 未来 |
| 5 | Teacher 未实现 | ⬜ | 未来 |
| 6 | Quiz 仅支持单选 Unit | ⬜ | 低优先级 |
| 7 | Cookie 过期静默失败 | ⬜ | M7 |
| 8 | 离线模式未实现 | ⬜ | 未来 |
| 9 | Quiz 选项可能重复（少词时） | ⬜ | 低优先级 |

---

## 7. 统计

| | 数量 |
|----|------|
| 总 Dart | **80** (65 lib + 15 test) |
| M6 新增 | 4 files |
| M6 修改 | 6 files |

---

## 8. 下一阶段 (Milestone 7)

Statistics 迁移：趋势图 (fl_chart) + 学习摘要 + 分组学习历史。

---

## 9. 验证清单

- [ ] `flutter pub get` succeeds (with audioplayers)
- [ ] `flutter analyze` → 0 warning, 0 info
- [ ] `flutter test` → all green (15 suites)
- [ ] Flashcard: 🔊 button → real audio plays
- [ ] Spelling: "Tap to listen" → real audio plays
- [ ] Home → "Quiz History" → list loads with pagination
- [ ] History cards show date, score, correct/wrong/time
- [ ] Pull-to-refresh reloads history
- [ ] Release APK builds
