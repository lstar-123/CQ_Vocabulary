# Milestone 1: Flutter Project Infrastructure — Summary

> **Date**: 2026-07-24
> **Status**: COMPLETE — Pending Review
> **Flutter SDK Target**: >=3.16.0 (Dart 3.2+)

---

## 1. 本阶段目标

建立 Flutter 项目的完整基础设施层：
- ✅ Project scaffolding
- ✅ Theme system (Material 3, light/dark)
- ✅ Router (GoRouter, 11 routes defined)
- ✅ Network layer (Dio + PersistCookieJar + Interceptors)
- ✅ All 8 DTO model classes (from Milestone 0)
- ✅ All 9 Repository classes
- ✅ Cookie service (login session management)
- ✅ Contract tests (JSON parsing + pagination + unit_ids + error handling)

**未编写任何业务页面**（仅占位符）。

---

## 2. 架构图

```
┌──────────────────────────────────────────────────────────┐
│                      main.dart                           │
│              VocabularyMemorizationApp                    │
│         ProviderScope + MaterialApp.router                │
└──────────────────────┬───────────────────────────────────┘
                       │
         ┌─────────────┼─────────────┐
         │             │             │
    ┌────▼────┐  ┌────▼────┐  ┌─────▼─────┐
    │  Theme  │  │ Router  │  │ ApiClient │
    │ (M3)    │  │(GoRouter│  │  (Dio)    │
    │ light/  │  │ 11 routes│  │ +CookieJar│
    │ dark    │  │placeholdr│  │ +Intercept│
    └─────────┘  └─────────┘  └─────┬─────┘
                                    │
                          ┌─────────┼─────────┐
                          │         │         │
                    ┌─────▼────┐ ┌──▼──┐ ┌───▼────┐
                    │ Intercept│ │Models│ │  Repos │
                    │ Auth     │ │  8   │ │   9    │
                    │ Logging  │ │DTOs  │ │ repos  │
                    │ Error    │ │      │ │        │
                    └──────────┘ └─────┘ └───┬────┘
                                             │
                                    ┌────────▼────────┐
                                    │  Flask Backend  │
                                    │  /api/*         │
                                    │  Session Cookie │
                                    └─────────────────┘
```

---

## 3. 新增目录

```
flutter_app/
├── lib/
│   ├── core/
│   │   ├── api/                    # ← NEW
│   │   │   ├── api_client.dart
│   │   │   └── api_constants.dart
│   │   ├── network/
│   │   │   └── interceptors/       # ← NEW
│   │   │       ├── app_exception.dart
│   │   │       ├── auth_interceptor.dart
│   │   │       ├── error_interceptor.dart
│   │   │       └── logging_interceptor.dart
│   │   ├── router/                 # ← NEW
│   │   │   └── app_router.dart
│   │   ├── theme/                  # ← NEW
│   │   │   ├── app_colors.dart
│   │   │   ├── app_spacing.dart
│   │   │   ├── app_theme.dart
│   │   │   └── app_typography.dart
│   │   └── constants/              # ← NEW
│   │       └── app_constants.dart
│   ├── models/                     # ← NEW (8 files)
│   │   ├── book.dart
│   │   ├── group_memory.dart
│   │   ├── pagination.dart
│   │   ├── phonics.dart
│   │   ├── quiz_session.dart
│   │   ├── statistics.dart
│   │   ├── unit.dart
│   │   ├── user.dart
│   │   └── word.dart
│   ├── repositories/               # ← NEW (9 files)
│   │   ├── auth_repository.dart
│   │   ├── group_learning_repository.dart
│   │   ├── history_repository.dart
│   │   ├── quiz_repository.dart
│   │   ├── stats_repository.dart
│   │   ├── teacher_repository.dart
│   │   ├── tts_repository.dart
│   │   ├── unit_repository.dart
│   │   └── word_repository.dart
│   ├── services/                   # ← NEW
│   │   └── cookie_service.dart
│   ├── state/providers/            # ← placeholder
│   ├── widgets/common/             # ← placeholder
│   └── features/                   # ← placeholder (7 feature dirs)
│       ├── login/
│       ├── home/
│       ├── study/
│       ├── flashcard/
│       ├── spelling/
│       ├── group/
│       ├── stats/
│       └── profile/
├── test/                           # ← NEW
│   ├── models/
│   │   ├── user_test.dart
│   │   ├── pagination_test.dart
│   │   ├── quiz_session_test.dart
│   │   └── group_memory_test.dart
│   ├── network/
│   │   └── app_exception_test.dart
│   └── repositories/
│       └── repository_contract_test.dart
├── pubspec.yaml                    # ← NEW
└── analysis_options.yaml           # ← NEW
```

---

## 4. 新增文件统计

| 类别 | 文件数 | 说明 |
|------|--------|------|
| Project Config | 2 | pubspec.yaml, analysis_options.yaml |
| Core / API | 2 | api_client.dart, api_constants.dart |
| Core / Network | 4 | 3 interceptors + app_exception.dart |
| Core / Theme | 4 | colors, typography, spacing, theme |
| Core / Router | 1 | app_router.dart |
| Core / Constants | 1 | app_constants.dart |
| Entry | 1 | main.dart |
| Models | 9 | user, book, unit, word, phonics, quiz_session, group_memory, statistics, pagination |
| Repositories | 9 | auth, unit, word, quiz, history, stats, group_learning, teacher, tts |
| Services | 1 | cookie_service.dart |
| Tests | 6 | 4 model tests + 1 exception test + 1 contract test |
| **Total** | **40** | |

---

## 5. 修改文件

无 — 全新项目。

---

## 6. API 使用情况

29 个 API 路径全部在 `ApiPaths` 中定义，9 个 Repository 各自引用：

| Repository | 使用的 API |
|---|---|
| AuthRepository | register, login, teacherLogin, logout, switchBook, listBooks, me |
| UnitRepository | units |
| WordRepository | words, wordsAll, wordsPhonics |
| QuizRepository | quizSubmit |
| HistoryRepository | history, historyDetail(sessionId) |
| StatsRepository | statsTrend, statsSummary, statsGroupHistory |
| GroupLearningRepository | groupLearningHistory (POST + GET) |
| TeacherRepository | teacherStudents, teacherStudentDetail, teacherStudentSessions, teacherStudentSessionDetail, teacherBooks, teacherWords, teacherWordDetail |
| TtsRepository | tts |

---

## 7. 数据流

```
                   User Action
                       │
                       ▼
              ┌─────────────────┐
              │  Riverpod State │  ← (Milestone 2+)
              │  (AsyncNotifier)│
              └────────┬────────┘
                       │ call
                       ▼
              ┌─────────────────┐
              │   Repository    │  ← Mars 1 ✅
              │  • unit_ids conv│
              │  • pagination   │
              │  • JSON ↔ DTO  │
              └────────┬────────┘
                       │ Dio request
                       ▼
              ┌─────────────────┐
              │   ApiClient     │  ← Mars 1 ✅
              │  • /api prefix  │
              │  • CookieJar    │
              │  • Interceptors │
              └────────┬────────┘
                       │ HTTP
                       ▼
              ┌─────────────────┐
              │ Flask Backend   │
              │ /api/*          │
              └─────────────────┘
```

**关键转换 (Repository 层)**：
- `unit_ids`: `List<int> [1,2,3]` → query param `"1,2,3"` → response parse → `List<int>`
- Pagination: `{"items": [...]}` 和 `{"words": [...]}` → 统一 `PaginatedResponse<T>`
- JSON keys: `snake_case` ↔ `camelCase` (via manual `fromJson`/`toJson`)

---

## 8. 是否需要 Backend 修改

**否。** 所有差异（分页字段名、unit_ids 格式）均在 Flutter Repository 层适配。

---

## 9. Contract Test 覆盖

| 测试 | 验证内容 |
|------|----------|
| `user_test.dart` | UserBrief/TeacherBrief/StudentInfo fromJson+toJson+roundtrip； RegisterRequest 可选字段省略 |
| `pagination_test.dart` | fromHistoryJson ("items") / fromTeacherWordsJson ("words") 双向归一化； total_pages 自动计算； map() 保持元数据 |
| `quiz_session_test.dart` | QuizSessionBrief/Detail fromJson；QuizSubmitRequest toJson 可选字段省略；QuizSubmitResponse fromJson |
| `group_memory_test.dart` | GroupMemoryRecord fromJson (group/round/unit 三种 event_type)；GroupHistoryRequest toJson 条件字段；GroupHistoryFull 信封解析 |
| `app_exception_test.dart` | 9 种异常默认消息；自定义消息；sealed class 穷尽 switch |
| `repository_contract_test.dart` | 29 个 ApiPaths 完整性；unit_ids 双向转换 roundtrip；Backend error JSON 格式验证；分页归一化一致性 |

---

## 10. 关键设计决策

| 决策 | 选择 | 理由 |
|------|------|------|
| JSON 序列化 | 手动 `fromJson`/`toJson` | 无需 build_runner，编译快，可读性强 |
| 状态管理 | Riverpod | 用户要求，禁止 Bloc/GetX/Provider |
| Cookie 管理 | PersistCookieJar | 持久化 Session Cookie，App 重启不丢失 |
| /api 前缀 | ApiClient BaseOptions.baseUrl | Repository 只写相对路径，统一管理 |
| 分页差异 | PaginationBuilder.fromHistoryJson / fromTeacherWordsJson | UI 层不感知后端差异 |
| 异常体系 | Sealed class AppException | 穷尽 pattern matching，类型安全 |
| Theme | Material 3 + Inter 字体 | Apple HIG / Notion / Linear 风格 |

---

## 11. 下一阶段计划 (Milestone 2)

确认本阶段后：

1. **登录页面**: LoginScreen with form validation, error handling
2. **注册页面**: RegisterScreen with book_schema selector
3. **Auth State**: Riverpod auth provider + session persistence
4. **路由守卫**: Auth redirect (GoRouter redirect)
5. **主页面骨架**: Bottom navigation (Home/Study/Stats/Profile)
6. **通用 UI 组件**: Button, Card, Dialog, SnackBar, Loading, Error, Skeleton

---

## 12. 本地运行

```bash
cd flutter_app
flutter pub get
flutter test                    # 运行所有 Contract Tests
flutter analyze                  # 零 Warning
flutter build apk --debug        # 验证编译
```
