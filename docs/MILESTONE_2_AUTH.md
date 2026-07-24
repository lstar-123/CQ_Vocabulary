# Milestone 2: Authentication — Summary

> **Date**: 2026-07-24
> **Status**: COMPLETE — Pending Review
> **Scope**: Splash → Cookie Restore → AuthProvider → Route Guard → Login → Logout

---

## 1. 本阶段目标

- ✅ Splash screen with session restore
- ✅ Cookie-based session persistence (PersistCookieJar)
- ✅ AuthProvider (Riverpod `AsyncNotifier`)
- ✅ Route Guard (GoRouter `redirect`)
- ✅ Login screen (Student + Teacher tabs)
- ✅ Logout (cookie clearing + state reset)
- ✅ CI pipeline (GitHub Actions)
- ❌ No other business modules (deferred)

---

## 2. Auth Flow Architecture

```
App Launch
    │
    ▼
┌──────────┐    session cookie     ┌──────────────┐
│  Splash  │───▶ AuthRepository ──▶│ Flask /api/  │
│  Screen  │    .me()              │ auth/me      │
└────┬─────┘                       └──────────────┘
     │
     │ User found?          No session?
     │ YES                        │ NO
     ▼                            ▼
┌──────────┐              ┌──────────────┐
│  Home    │◀──redirect───│   Login      │
│  (/)     │              │   Screen     │
└────┬─────┘              └──────┬───────┘
     │                           │
     │ Logout                    │ Login success
     ▼                           ▼
  AuthNotifier              AuthNotifier
  .logout()                 .login()
     │                           │
     │ Clears:                   │ Sets:
     │ • Server session          │ • AsyncData(User)
     │ • CookieJar (deleteAll)   │
     │ • Riverpod state → null   │
     ▼                           ▼
┌──────────────┐          ┌──────────┐
│  Login       │◀──redir──│  Home    │
│  Screen      │          │  (/)     │
└──────────────┘          └──────────┘
```

**Router Guard (GoRouter `redirect`):**

| State | On Splash | On Login | On Protected |
|-------|-----------|----------|--------------|
| AsyncLoading | Stay | → Splash | → Splash |
| AsyncData(null) | → Login | Stay | → Login |
| AsyncData(User) | → Home | → Home | Stay |
| AsyncError | → Login | Stay | → Login |

---

## 3. 新增/修改文件

### 新增

| File | Purpose |
|------|---------|
| `lib/state/providers/auth_provider.dart` | `AuthNotifier` (AsyncNotifier) + 3 derived providers |
| `lib/features/splash/splash_screen.dart` | Branded splash with loading indicator |
| `lib/features/login/login_screen.dart` | Student/Teacher login with tabs, form validation, error display |
| `.github/workflows/ci.yml` | CI: flutter pub get → analyze → test → build debug APK |
| `test/state/auth_provider_test.dart` | AuthNotifier state transitions + derived provider tests |
| `test/features/login_screen_test.dart` | Login screen rendering + form validation smoke tests |

### 修改

| File | Change |
|------|--------|
| `lib/main.dart` | `ConsumerStatefulWidget` → creates GoRouter once in `initState` |
| `lib/core/router/app_router.dart` | Added redirect guard, SplashScreen, LoginScreen; removed old placeholders for those paths |

### 未修改

- 所有 Domain Models (9)
- 所有 Mappers (9)
- 所有 Repositories (9) — AuthRepository already had `.logout()` with cookie clearing
- Theme 系统 (4)
- ApiClient + Interceptors (5)
- ApiPaths (1)

---

## 4. AuthProvider 设计

```dart
// State: AsyncValue<User?>
final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, User?>(AuthNotifier.new);

// Derived: convenient synchronous access
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authNotifierProvider).valueOrNull;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

final isTeacherProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider)?.isTeacher ?? false;
});
```

**Public API:**
- `login(username, password)` — student login
- `teacherLogin(username, password)` — teacher login
- `register(username, password, bookSchema?)` — student register + auto-login
- `logout()` — clear everything

**State lifecycle:**
```
build() → _restoreSession() → AsyncData<User?> (null or user)
login() → AsyncLoading → AsyncData<User>
logout() → AsyncData(null)
```

---

## 5. Logout 完整性检查

| Layer | Action |
|-------|--------|
| Server | `POST /api/auth/logout` — invalidates Flask session |
| CookieJar | `ApiClient().cookieJar.deleteAll()` — removes PersistCookieJar |
| Riverpod | `state = AsyncData(null)` — clears user from state |
| GoRouter | redirect detects `null` → navigates to `/login` |

---

## 6. CI Pipeline

```yaml
Triggers: push/PR to main/master (flutter_app/**), workflow_dispatch

Jobs:
  1. analyze-and-test:
     - flutter pub get
     - flutter analyze --no-fatal-infos --no-fatal-warnings
     - flutter test --reporter expanded

  2. build-debug-apk (on analyze-and-test success):
     - flutter build apk --debug
     - upload artifact (7-day retention)
```

---

## 7. 下一阶段计划 (Milestone 3)

按用户确认的范围：

**Milestone 3: Home + Card Mode (Flashcard)**

1. Home 页面：单元列表 + 选择学习单元
2. Card Mode：单词卡片（正面英文/背面中文+发音）
3. TTS 集成：点击播放发音
4. Release APK：正式编译签名
5. Web 首页：添加【下载 Android APP】按钮

**延后**: 拼写、分组学习、统计、教师管理。

---

## 8. 验证清单

- [ ] `flutter pub get` succeeds
- [ ] `flutter analyze` → 0 warning, 0 info
- [ ] `flutter test` → all green
- [ ] APK builds successfully
- [ ] Splash → Cookie Restore (test with valid session)
- [ ] Login → Home redirect
- [ ] Logout → Login redirect
- [ ] Direct URL to `/` → redirect to `/login` (when not authenticated)
- [ ] Teacher login tab works
