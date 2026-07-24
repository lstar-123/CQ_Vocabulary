# VocabularyMemorization v1.0.0 — Release Notes

---

## Overview

VocabularyMemorization is an English vocabulary learning app. This is the first
Flutter Android release, compatible with the existing Flask backend.

**Version**: v1.0.0
**Platforms**: Android (APK + AAB), Web (existing HTML)
**Backend**: Flask + PostgreSQL + Redis (unchanged)

---

## Features

| Module | Description |
|--------|-------------|
| Splash + Auto Login | Cookie-based session restore |
| Login / Register | Student + Teacher login |
| Home | Book selector, unit list, mode picker |
| Flashcard | Card flip (English ↔ Chinese) + TTS audio |
| Spelling | Chinese prompt → type English → check |
| Quiz | Multiple choice, auto-advance, score results |
| Quiz History | Paginated history with stats |
| Statistics | Dashboard with charts (accuracy line, weekly bar, distribution donut) |
| Group Learning | Multi-phase: memory cards → spelling → wrong review → summary |

---

## Architecture

```
Flutter App
├── features/           (8 feature modules)
├── domain/
│   ├── models/         (9 clean domain models)
│   └── mappers/        (9 DTO→Domain mappers)
├── models/             (9 DTOs, JSON serialization)
├── repositories/       (9 repositories)
├── state/providers/    (7 Riverpod providers)
├── core/
│   ├── api/            (ApiClient + ApiPaths, 29 endpoints)
│   ├── network/        (Dio interceptors: auth, error, logging)
│   ├── router/         (GoRouter, 9 routes)
│   └── theme/          (Material 3, light/dark)
├── services/           (AudioService)
└── widgets/            (shared components)
```

**Dependencies**: Riverpod, Dio, GoRouter, fl_chart, audioplayers, Google Fonts

---

## Building

```bash
cd flutter_app
flutter pub get
flutter analyze          # 0 warnings
flutter test             # 19 suites, all green
flutter build apk --release   # → build/app/outputs/flutter-apk/app-release.apk
flutter build appbundle       # → build/app/outputs/bundle/release/app-release.aab
```

---

## Deployment

1. Copy APK to ECS:
```bash
scp app-release.apk user@host:/frontend/downloads/VocabularyMemorization.apk
```

2. Verify download URL: `https://your-domain.com/downloads/VocabularyMemorization.apk`

3. Web frontend shows 📱 download button (with OS detection).

---

## API (29 endpoints)

All endpoints documented in `docs/MILESTONE_0_API_CONTRACT.md`.

| Module | Endpoints |
|--------|-----------|
| Auth | register, login, teacher/login, logout, book, books, me |
| Units | units |
| Words | words, words/all, words/phonics |
| Quiz | submit |
| History | history, history/<id> |
| Stats | trend, summary, group-history |
| Group Learning | history (GET + POST) |
| Teacher | students, students/<id>, books, words (CRUD) |
| TTS | tts |

---

## Known Technical Debt (v1.0.0)

| # | Item | Priority | Target |
|---|------|----------|--------|
| 1 | Cookie expiry silent failure | Low | v1.1 |
| 2 | Offline mode | Medium | v1.2 |
| 3 | Teacher module (Flutter) | Low | v2.0 |
| 4 | Quiz option dedup (low word count) | Low | v1.1 |
| 5 | Deep link support | Low | v1.1 |
| 6 | Push notifications (daily reminder) | Medium | v1.2 |

---

## File Statistics

| | Count |
|----|-------|
| Dart source files | 93 |
| Test files | 19 test suites |
| Domain models | 9 |
| Mappers | 9 |
| Repositories | 9 |
| Features | 8 |
| CI workflows | 1 |
| Docs | 9 milestone docs + this one |
