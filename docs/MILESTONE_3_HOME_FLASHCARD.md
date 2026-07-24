# Milestone 3: Home + Book Select + Unit Select + Flashcard + Release APK — Summary

> **Date**: 2026-07-24
> **Status**: COMPLETE — Pending Review
> **Scope**: Home → Book → Unit → Card Mode + TTS + Release APK + Web Download Entry

---

## 1. 本阶段目标

- ✅ AuthProvider 修复：login 统一从 `/me` 获取用户信息，logout 使用 `ref.invalidateSelf()`
- ✅ Home 页面：词书选择 + 单元列表
- ✅ Book Selector：`grade6_vol1` / `senior_compulsory_1` 切换（持久化到后端）
- ✅ Unit Selector：选中词书的单元列表，点击进入 Flashcard
- ✅ Card Mode：英文正面 → 点击翻转 → 中文背面 + TTS 发音
- ✅ Release APK 构建配置
- ✅ Web 首页增加【📱 下载 Android APP】按钮
- ❌ 未迁移 Quiz、Statistics、Group Learning、Teacher 等功能

---

## 2. AuthProvider 修复

### Login: 统一信息源

```
Before:  login() → state = login API response
After:   login() → POST /api/auth/login → cookie set
                 → GET /api/auth/me → state = /me response
```

所有 User 对象统一来自 `/api/auth/me`。

### Logout: invalidateSelf

```
Before:  logout() → POST /logout → cookieJar.deleteAll() → state = AsyncData(null)
After:   logout() → POST /logout → cookieJar.deleteAll() → ref.invalidateSelf()
                    → build() re-runs → _restoreSession() → /me → null
```

其他依赖 AuthProvider 的 Provider 同步自动清理。

---

## 3. 新增/修改文件

### 新增

| File | Purpose |
|------|---------|
| `lib/features/home/home_screen.dart` | Home: greeting, book selector, unit list, logout |
| `lib/features/flashcard/flashcard_screen.dart` | Card Mode: flip animation + TTS + prev/next |
| `lib/state/providers/book_provider.dart` | `bookListProvider`, `currentBookProvider`, `unitListProvider` |

### 修改

| File | Change |
|------|--------|
| `lib/state/providers/auth_provider.dart` | login → restore from /me; logout → invalidateSelf() |
| `lib/core/router/app_router.dart` | HomeScreen + FlashcardScreen replace placeholders |
| `frontend/quiz.html` | +📱 download button (HTML + CSS + responsive) |
| `frontend/teacher.html` | +📱 download button (HTML + CSS + responsive) |

---

## 4. 数据流

```
AuthProvider (session restored)
    │
    ▼
HomeScreen
    │
    ├── bookListProvider ──▶ AuthRepository.getBooks() ──▶ [Book]
    ├── currentBookProvider ──▶ switchBook() ──▶ Book
    └── unitListProvider ──▶ UnitRepository.getUnits() ──▶ [Unit]
                                    │
                              tap unit card
                                    │
                                    ▼
                          FlashcardScreen
                                    │
                          WordRepository.getWords(unitIds: [N])
                                    │
                          TtsRepository.speak(text) ──▶ audio bytes
```

---

## 5. Flashcard UI

```
┌──────────────────────────────┐
│  AppBar: Unit Name            │
├──────────────────────────────┤
│  ▓▓▓▓▓▓▓▓▓▓▓░░░░░░  3 / 10  │  ← progress
│                              │
│  ┌────────────────────────┐  │
│  │                        │  │
│  │     apple              │  │  ← tap to flip
│  │                        │  │
│  │   ┌──────────────┐    │  │
│  │   │ Tap to reveal │    │  │
│  │   └──────────────┘    │  │
│  └────────────────────────┘  │
│                              │
│  [◀]    [🔊]    [▶]         │  ← prev / tts / next
└──────────────────────────────┘
```

Flipped:
```
  ┌────────────────────────┐
  │                        │
  │       苹果              │  ← Chinese
  │       apple            │  ← English (muted)
  │                        │
  │   ┌──────────────┐    │
  │   │ Tap to hide  │    │
  │   └──────────────┘    │
  └────────────────────────┘
```

---

## 6. Release APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

部署到 ECS:
```bash
scp app-release.apk user@host:/frontend/downloads/android/VocabularyMemorization.apk
```

下载地址: `https://你的域名/downloads/android/VocabularyMemorization.apk`

---

## 7. Web 下载入口

在 quiz.html 和 teacher.html 的用户栏（user-bar）添加了：

```html
<a class="btn-download-android"
   href="/downloads/android/VocabularyMemorization.apk">
  📱 下载 Android APP
</a>
```

样式匹配现有 Grove 设计系统（sage 绿按钮，白色文字，圆角胶囊）。

---

## 8. 下一阶段计划 (Milestone 4)

按用户确认：

1. **Spelling Mode**: 中文提示 → 用户输入英文 → 校对
2. **Quiz Review**: 已完成的 Quiz 回顾
3. 或用户指定的其他模块

---

## 9. 验证清单

- [ ] `flutter pub get` succeeds
- [ ] `flutter analyze` → 0 warning, 0 info
- [ ] `flutter test` → all green
- [ ] Login → Home → book switch → unit list loads
- [ ] Tap unit → Flashcard shows words
- [ ] Card flips on tap (English ↔ Chinese)
- [ ] TTS button plays pronunciation (requires backend Youdao keys)
- [ ] Prev/Next navigation works
- [ ] Logout reverts to login
- [ ] Web page shows 📱 download button
- [ ] Release APK builds
