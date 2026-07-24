# Milestone 0: API Contract Layer

> **Status**: DRAFT — Pending Review
> **Date**: 2026-07-24
> **Tech Stack**: Flask + SQLAlchemy → Flutter + Riverpod + Dio

---

## 1. 本阶段目标

- 完整扫描 Backend 所有 API、Data Model、Auth 机制
- 建立 API Contract 文档（Method、Path、Request、Response、Error Code）
- 整理所有 DTO 映射（Model ↔ JSON）
- 识别可复用结构（BaseResponse、Pagination）
- 设计 Flutter Repository 层
- 标记建议新增的 API

---

## 2. Backend 架构总览

```
Backend (Flask)
├── config.py          — 配置（SECRET_KEY, DATABASE_URL, WORDS_DATABASE_URL）
├── decorators.py      — 装饰器（@api_login_required, @teacher_required）
├── models.py          — SQLAlchemy 数据模型（双数据库绑定）
├── phonics.py         — 自然拼读数据访问层
├── routes/
│   ├── auth.py            — /api/auth/*
│   ├── units.py           — /api/units/*
│   ├── words.py           — /api/words/*
│   ├── quiz.py            — /api/quiz/*
│   ├── history.py         — /api/history/*
│   ├── stats.py           — /api/stats/*
│   ├── teacher.py         — /api/teacher/*
│   ├── tts.py             — /api/tts/*
│   └── group_learning.py  — /api/group-learning/*
└── scripts/           — 数据库迁移、数据导入、测试脚本
```

### 数据库结构

| 数据库 | Schema | 表 | 用途 |
|--------|--------|-----|------|
| vocab_quiz | public | users | 学生用户 |
| vocab_quiz | public | teachers | 教师用户 |
| vocab_quiz | public | quiz_sessions | 测验记录 |
| vocab_quiz | public | quiz_answers | 测验答案 |
| vocab_quiz | public | group_memory_history | 分组学习历史 |
| vocab_quiz_words | grade6_vol1 | units | 六年级上册 — 单元 |
| vocab_quiz_words | grade6_vol1 | words | 六年级上册 — 单词 |
| vocab_quiz_words | senior_compulsory_1 | units | 高中必修一 — 单元 |
| vocab_quiz_words | senior_compulsory_1 | words | 高中必修一 — 单词 |

### 认证机制

| 项目 | 值 |
|------|-----|
| 认证方式 | Flask-Login（Session Cookie） |
| 用户类型 | Student (`student:<id>`), Teacher (`teacher:<id>`) |
| Decorator | `@api_login_required` → 401 JSON |
| Decorator | `@teacher_required` → 401 / 403 JSON |

### BOOK_SCHEMAS

```
grade6_vol1        → "六年级上册"
senior_compulsory_1 → "高中必修一"
```

---

## 3. API Inventory（完整清单）

### 3.1 Auth — `/api/auth`

| # | Method | Path | Auth | Description |
|---|--------|------|------|-------------|
| A1 | POST | `/api/auth/register` | No | 学生注册 |
| A2 | POST | `/api/auth/login` | No | 学生登录 |
| A3 | POST | `/api/auth/teacher/login` | No | 教师登录 |
| A4 | POST | `/api/auth/logout` | Student | 登出 |
| A5 | PUT | `/api/auth/book` | Student | 切换词书 |
| A6 | GET | `/api/auth/books` | Student | 获取可用词书列表 |
| A7 | GET | `/api/auth/me` | No | 获取当前用户信息 |

#### A1 — POST /api/auth/register

```
Request:
{
  "username": "string (2-50 chars, required)",
  "password": "string (≥3 chars, required)",
  "book_schema": "string (optional, must be in BOOK_SCHEMAS)"
}

Response 201:
{
  "id": 1,
  "username": "alice",
  "role": "student",
  "current_book": "grade6_vol1"   // null if not set
}

Error 400: {"error": "用户名和密码不能为空"}
Error 400: {"error": "用户名需要2-50个字符"}
Error 400: {"error": "密码至少需要3个字符"}
Error 400: {"error": "无效的词书，可选值：grade6_vol1, senior_compulsory_1"}
Error 409: {"error": "用户名已存在"}
```

#### A2 — POST /api/auth/login

```
Request:
{
  "username": "string (required)",
  "password": "string (required)"
}

Response 200:
{
  "id": 1,
  "username": "alice",
  "role": "student",
  "current_book": "grade6_vol1"   // null if not set
}

Error 400: {"error": "请求数据无效"}
Error 401: {"error": "用户名或密码错误"}
```

#### A3 — POST /api/auth/teacher/login

```
Request:
{
  "username": "string (required)",
  "password": "string (required)"
}

Response 200:
{
  "id": 1,
  "username": "admin",
  "role": "teacher"
}

Error 401: {"error": "用户名或密码错误"}
```

#### A4 — POST /api/auth/logout

```
Request: (empty)
Response 200: {"ok": true}
Error 401: {"error": "请先登录"}
```

#### A5 — PUT /api/auth/book

```
Request:
{
  "book_schema": "string (must be in BOOK_SCHEMAS)"
}

Response 200:
{
  "current_book": "senior_compulsory_1",
  "book_name": "高中必修一"
}

Error 400: {"error": "无效的词书，可选值：grade6_vol1, senior_compulsory_1"}
```

#### A6 — GET /api/auth/books

```
Query: (none)

Response 200:
[
  {"schema": "grade6_vol1", "name": "六年级上册"},
  {"schema": "senior_compulsory_1", "name": "高中必修一"}
]
```

#### A7 — GET /api/auth/me

```
Response 200 (authenticated student):
{
  "id": 1,
  "username": "alice",
  "role": "student",
  "current_book": "grade6_vol1"
}

Response 200 (authenticated teacher):
{
  "id": 1,
  "username": "admin",
  "role": "teacher"
}

Response 200 (not authenticated):
{"user": null}
```

---

### 3.2 Units — `/api/units`

| # | Method | Path | Auth | Description |
|---|--------|------|------|-------------|
| U1 | GET | `/api/units` | Student | 获取所有单元（含单词数） |

#### U1 — GET /api/units

```
Query:
  book_schema  string  optional  (default: current_user.current_book)

Response 200:
[
  {"id": 1, "name": "Unit 1", "word_count": 15},
  {"id": 2, "name": "Unit 2", "word_count": 12},
  ...
]
```

---

### 3.3 Words — `/api/words`

| # | Method | Path | Auth | Description |
|---|--------|------|------|-------------|
| W1 | GET | `/api/words` | Student | 获取单词列表 |
| W2 | GET | `/api/words/all` | Student | 获取所有单词（按单元分组） |
| W3 | GET | `/api/words/phonics` | Student | 获取单词自然拼读数据 |

#### W1 — GET /api/words

```
Query:
  book_schema  string  optional  (default: current_user.current_book)
  unit_ids     string  optional  (comma-separated IDs, e.g. "1,2,3")
  random       string  optional  ("1" for shuffled order)

Response 200:
[
  {
    "id": 1,
    "unit_id": 1,
    "unit_name": "Unit 1",
    "english": "apple",
    "chinese": "苹果"
  },
  ...
]

Error 400: {"error": "unit_ids 格式错误"}
```

#### W2 — GET /api/words/all

```
Query:
  book_schema  string  optional  (default: current_user.current_book)

Response 200:
[
  {
    "unit_id": 1,
    "unit_name": "Unit 1",
    "order_num": 1,
    "words": [
      {"id": 1, "english": "apple", "chinese": "苹果"},
      ...
    ]
  },
  ...
]
```

#### W3 — GET /api/words/phonics

```
Query:
  word         string  required  (English word text)
  book_schema  string  optional

Response 200:
{
  "word": "knowledge",
  "ipa": "/ˈnɒlɪdʒ/",
  "arpabet": "N AA1 L AH0 JH",
  "syllables": [
    {
      "text": "know",
      "stress": 1,
      "segments": [
        {"text": "k", "silent": true,  "rule": "silent-k"},
        {"text": "n", "silent": false, "rule": "consonant-n"},
        ...
      ]
    },
    ...
  ]
}

Error 400: {"error": "word is required"}
Error 404: {"error": "word not found"}
Error 404: {"error": "phonics data not available"}
```

---

### 3.4 Quiz — `/api/quiz`

| # | Method | Path | Auth | Description |
|---|--------|------|------|-------------|
| Q1 | POST | `/api/quiz/submit` | Student | 提交测验 |

#### Q1 — POST /api/quiz/submit

```
Request:
{
  "unit_ids": [1, 2],              // array<int>, optional
  "answers": [
    {
      "word_id": 1,
      "user_answer": "苹果",
      "is_correct": true
    },
    ...
  ],
  "duration_seconds": 120,          // int, optional
  "book_schema": "grade6_vol1"     // string, optional
}

Response 200:
{
  "session_id": 42,
  "total_count": 10,
  "correct_count": 8,
  "score_pct": 80.0
}

Error 400: {"error": "答案不能为空"}
```

---

### 3.5 History — `/api/history`

| # | Method | Path | Auth | Description |
|---|--------|------|------|-------------|
| H1 | GET | `/api/history` | Student | 测验历史（分页） |
| H2 | GET | `/api/history/<session_id>` | Student | 测验详情（含答案） |

#### H1 — GET /api/history

```
Query:
  unit_id      int     optional
  page         int     optional  (default: 1)
  per_page     int     optional  (default: 10)
  book_schema  string  optional

Response 200:
{
  "items": [
    {
      "id": 42,
      "unit_ids": "1,2",
      "total_count": 10,
      "correct_count": 8,
      "score_pct": 80.0,
      "duration_seconds": 120,
      "book_schema": "grade6_vol1",
      "completed_at": "2026-07-24T10:30:00"
    },
    ...
  ],
  "total": 50,
  "page": 1,
  "per_page": 10,
  "total_pages": 5
}
```

#### H2 — GET /api/history/<session_id>

```
Response 200:
{
  "id": 42,
  "unit_ids": "1,2",
  "total_count": 10,
  "correct_count": 8,
  "score_pct": 80.0,
  "duration_seconds": 120,
  "book_schema": "grade6_vol1",
  "completed_at": "2026-07-24T10:30:00",
  "answers": [
    {
      "word_id": 1,
      "chinese": "苹果",
      "english": "apple",
      "user_answer": "苹果",
      "is_correct": true
    },
    ...
  ]
}

Error 404: {"error": "记录不存在"}
```

---

### 3.6 Stats — `/api/stats`

| # | Method | Path | Auth | Description |
|---|--------|------|------|-------------|
| S1 | GET | `/api/stats/trend` | Student | 学习成绩趋势 |
| S2 | GET | `/api/stats/summary` | Student | 学习统计摘要 |
| S3 | GET | `/api/stats/group-history` | Student | 分组学习历史 |

#### S1 — GET /api/stats/trend

```
Query:
  book_schema  string  optional

Response 200:
[
  {
    "date": "07-24 10:30",
    "score_pct": 80.0,
    "total_count": 10,
    "correct_count": 8,
    "unit_ids": "1,2",
    "unit_names": ["Unit 1", "Unit 2"],
    "unit_scores": {              // 仅多单元测验时出现
      "1": {"total": 5, "correct": 4, "score_pct": 80.0},
      "2": {"total": 5, "correct": 4, "score_pct": 80.0}
    }
  },
  ...
]
```

#### S2 — GET /api/stats/summary

```
Query:
  book_schema  string  optional

Response 200:
{
  "total_quizzes": 50,
  "avg_score": 85.3,
  "best_score": 100.0,
  "total_words_tested": 500,
  "total_correct": 425,
  "total_units_studied": 3,      // group learning completed units
  "total_group_sessions": 45      // total group_memory_history records
}
```

#### S3 — GET /api/stats/group-history

```
Query:
  book_schema  string  optional

Response 200:
[
  {
    "id": 1,
    "unit_id": 1,
    "unit_name": "Unit 1",
    "event_type": "unit_complete",
    "round_index": 0,
    "group_index": null,
    "group_size": null,
    "label": "🏆 Unit 完成",
    "duration_seconds": 300,
    "error_count": 0,
    "error_words": [],
    "finished_at": "2026-07-24T10:30:00"
  },
  {
    "id": 2,
    "unit_id": 1,
    "unit_name": "Unit 1",
    "event_type": "round_complete",
    "round_index": 0,
    "group_index": null,
    "group_size": null,
    "label": "第1轮 完成",
    "duration_seconds": 120,
    "error_count": 2,
    "error_words": [{"english": "apple", "chinese": "苹果"}],
    "finished_at": "2026-07-24T10:25:00"
  },
  ...
]
```

---

### 3.7 Group Learning — `/api/group-learning`

| # | Method | Path | Auth | Description |
|---|--------|------|------|-------------|
| G1 | POST | `/api/group-learning/history` | Student | 写入一条学习记录 |
| G2 | GET | `/api/group-learning/history` | Student | 读取学习历史 |

#### G1 — POST /api/group-learning/history

```
Request:
{
  "unit_id": 1,                    // int, required
  "book_schema": "grade6_vol1",   // string, optional
  "event_type": "group_complete",  // string, required: group_complete|round_complete|unit_complete
  "round_index": 0,                // int, default: 0
  "group_index": 0,                // int, optional (null for round/unit)
  "group_size": 5,                 // int, optional (null for round/unit)
  "duration_seconds": 60,          // int, optional
  "error_count": 0,                // int, default: 0
  "error_words": [                 // array, optional
    {"english": "apple", "chinese": "苹果"}
  ],
  "finished_at": "2026-07-24T10:30:00"  // ISO datetime, optional
}

Response 201:
{
  "id": 1,
  "event_type": "group_complete",
  "unit_id": 1,
  "round_index": 0
}

Error 400: {"error": "unit_id is required"}
Error 400: {"error": "event_type must be one of ['group_complete', 'round_complete', 'unit_complete']"}
```

#### G2 — GET /api/group-learning/history

```
Query:
  book_schema  string  optional
  unit_id      int     optional

Response 200:
{
  "records": [
    {
      "id": 1,
      "unit_id": 1,
      "event_type": "group_complete",
      "round_index": 0,
      "group_index": 0,
      "group_size": 5,
      "duration_seconds": 60,
      "error_count": 0,
      "error_words": [],
      "finished_at": "2026-07-24T10:30:00"
    },
    ...
  ],
  "unit_max_completed_round": {    // unit_id -> max completed round index
    "1": 2,
    "2": 1
  },
  "unit_complete": [1, 2]          // array of unit_ids that are fully complete
}
```

---

### 3.8 Teacher — `/api/teacher`

| # | Method | Path | Auth | Description |
|---|--------|------|------|-------------|
| T1 | GET | `/api/teacher/students` | Teacher | 学生列表（含统计） |
| T2 | GET | `/api/teacher/students/<id>` | Teacher | 学生详情 |
| T3 | GET | `/api/teacher/students/<id>/sessions` | Teacher | 学生测验记录 |
| T4 | GET | `/api/teacher/students/<id>/sessions/<sid>` | Teacher | 学生测验详情 |
| T5 | GET | `/api/teacher/books` | Teacher | 可用词书列表 |
| T6 | GET | `/api/teacher/words` | Teacher | 单词管理（分页） |
| T7 | POST | `/api/teacher/words` | Teacher | 新增单词 |
| T8 | PUT | `/api/teacher/words/<id>` | Teacher | 编辑单词 |
| T9 | DELETE | `/api/teacher/words/<id>` | Teacher | 删除单词 |

#### T1 — GET /api/teacher/students

```
Response 200:
[
  {
    "id": 1,
    "username": "alice",
    "created_at": "2026-07-01T10:00:00",
    "total_quizzes": 25,
    "avg_score": 85.3,
    "best_score": 100.0,
    "total_words_tested": 250
  },
  ...
]
```

#### T2 — GET /api/teacher/students/<student_id>

```
Response 200:
{
  "id": 1,
  "username": "alice",
  "created_at": "2026-07-01T10:00:00",
  "total_quizzes": 25,
  "avg_score": 85.3,
  "best_score": 100.0,
  "total_words_tested": 250
}

Error 404: {"error": "学生不存在"}
```

#### T3 — GET /api/teacher/students/<student_id>/sessions

```
Response 200:
[
  {
    "id": 42,
    "unit_ids": "1,2",
    "unit_names": ["Unit 1", "Unit 2"],
    "total_count": 10,
    "correct_count": 8,
    "score_pct": 80.0,
    "book_schema": "grade6_vol1",
    "completed_at": "2026-07-24T10:30:00"
  },
  ...
]
```

#### T4 — GET /api/teacher/students/<student_id>/sessions/<session_id>

```
Response 200: (same structure as H2)

Error 404: {"error": "学生不存在"}
Error 404: {"error": "记录不存在"}
```

#### T5 — GET /api/teacher/books

```
Response 200: (same as A6)
[
  {"schema": "grade6_vol1", "name": "六年级上册"},
  {"schema": "senior_compulsory_1", "name": "高中必修一"}
]
```

#### T6 — GET /api/teacher/words

```
Query:
  unit_id      int     optional
  page         int     optional (default: 1)
  per_page     int     optional (default: 50)
  book_schema  string  optional (default: 'grade6_vol1')

Response 200:
{
  "words": [
    {
      "id": 1,
      "unit_id": 1,
      "unit_name": "Unit 1",
      "english": "apple",
      "chinese": "苹果"
    },
    ...
  ],
  "total": 150,
  "page": 1,
  "per_page": 50
}
```

#### T7 — POST /api/teacher/words

```
Request:
{
  "unit_id": 1,
  "english": "orange",
  "chinese": "橙子",
  "book_schema": "grade6_vol1"     // optional, default: 'grade6_vol1'
}

Response 201:
{
  "id": 200,
  "unit_id": 1,
  "unit_name": "Unit 1",
  "english": "orange",
  "chinese": "橙子"
}

Error 400: {"error": "单元、英文和中文不能为空"}
Error 404: {"error": "单元不存在"}
```

#### T8 — PUT /api/teacher/words/<word_id>

```
Request (all fields optional):
{
  "unit_id": 2,
  "english": "banana",
  "chinese": "香蕉",
  "book_schema": "grade6_vol1"
}

Response 200:
{
  "id": 200,
  "unit_id": 2,
  "unit_name": "Unit 2",
  "english": "banana",
  "chinese": "香蕉"
}

Error 400: {"error": "英文不能为空"}
Error 400: {"error": "中文不能为空"}
Error 404: {"error": "词汇不存在"}
Error 404: {"error": "单元不存在"}
```

#### T9 — DELETE /api/teacher/words/<word_id>

```
Query:
  book_schema  string  optional (default: 'grade6_vol1')

Response 200: {"ok": true}
Error 404: {"error": "词汇不存在"}
```

---

### 3.9 TTS — `/api/tts`

| # | Method | Path | Auth | Description |
|---|--------|------|------|-------------|
| TTS1 | GET | `/api/tts` | Student | 有道 TTS 代理 |

#### TTS1 — GET /api/tts

```
Query:
  text  string  required  (word/text to speak)
  lang  string  optional  (default: 'en')

Response 200: audio/mp3 binary
Error 400: "missing text"
Error 500: "tts not configured"
Error 502: "tts upstream error {code}"
Error 502: "tts request failed: {err}"
```

---

## 4. Data Models（DTO Mapping）

### 4.1 User

| DB Column | Type | DTO Key | Nullable | Notes |
|-----------|------|---------|----------|-------|
| id | Integer | id | no | PK |
| username | String(50) | username | no | unique |
| password_hash | String(255) | — | no | never exposed |
| current_book | String(50) | current_book | yes | null = not set |
| created_at | DateTime | — | no | not exposed in API (except teacher view) |

**API DTOs:**

```dart
// UserBrief — used in auth responses, /me
class UserBrief {
  final int id;
  final String username;
  final String role;           // "student" | "teacher"
  final String? currentBook;   // null for teacher
}

// StudentInfo — used in teacher views
class StudentInfo {
  final int id;
  final String username;
  final String createdAt;
  final int totalQuizzes;
  final double avgScore;
  final double bestScore;
  final int totalWordsTested;
}
```

### 4.2 Book

No DB model — defined as runtime map.

```dart
class BookInfo {
  final String schema;   // "grade6_vol1"
  final String name;     // "六年级上册"
}
```

### 4.3 Unit

| DB Column | Type | DTO Key | Nullable |
|-----------|------|---------|----------|
| id | Integer | id | no |
| name | String(50) | name | no |
| order_num | Integer | — | not in API (but used for ordering) |

```dart
class UnitBrief {
  final int id;
  final String name;
  final int wordCount;
}

class UnitWithWords {
  final int unitId;
  final String unitName;
  final int orderNum;
  final List<WordBrief> words;
}
```

### 4.4 Word

| DB Column | Type | DTO Key | Nullable |
|-----------|------|---------|----------|
| id | Integer | id | no |
| unit_id | Integer | unit_id | no |
| english | String(255) | english | no |
| chinese | String(255) | chinese | no |
| phonics_data | JSON | — | yes (separate endpoint) |
| phonics_version | Integer | — | not exposed |
| generated_by | String(100) | — | not exposed |
| generated_at | DateTime | — | not exposed |
| reviewed | Boolean | — | not exposed |

```dart
class WordBrief {
  final int id;
  final int unitId;
  final String unitName;
  final String english;
  final String chinese;
}
```

### 4.5 Phonics

```dart
class PhonicsSegment {
  final String text;
  final bool silent;
  final String rule;
}

class PhonicsSyllable {
  final String text;
  final int stress;
  final List<PhonicsSegment> segments;
}

class PhonicsData {
  final String word;
  final String ipa;
  final String arpabet;
  final List<PhonicsSyllable> syllables;
}
```

### 4.6 QuizSession

| DB Column | Type | DTO Key | Nullable |
|-----------|------|---------|----------|
| id | Integer | id | no |
| user_id | Integer | — | not exposed |
| unit_ids | String | unit_ids | no (comma-separated string) |
| total_count | Integer | total_count | no |
| correct_count | Integer | correct_count | no |
| score_pct | Numeric(5,2) | score_pct | no |
| duration_seconds | Integer | duration_seconds | yes |
| book_schema | String(50) | book_schema | yes |
| completed_at | DateTime | completed_at | no |

```dart
class QuizSessionBrief {
  final int id;
  final String unitIds;       // comma-separated "1,2,3"
  final int totalCount;
  final int correctCount;
  final double scorePct;
  final int? durationSeconds;
  final String? bookSchema;
  final String? completedAt;  // ISO 8601
}

class QuizSessionDetail extends QuizSessionBrief {
  final List<QuizAnswerItem> answers;
}

class QuizAnswerItem {
  final int wordId;
  final String chinese;
  final String english;
  final String userAnswer;
  final bool isCorrect;
}

// For quiz submission
class QuizSubmitRequest {
  final List<int> unitIds;
  final List<AnswerSubmit> answers;
  final int? durationSeconds;
  final String? bookSchema;
}

class AnswerSubmit {
  final int wordId;
  final String userAnswer;
  final bool isCorrect;
}

class QuizSubmitResponse {
  final int sessionId;
  final int totalCount;
  final int correctCount;
  final double scorePct;
}
```

### 4.7 GroupMemoryHistory

| DB Column | Type | DTO Key | Nullable |
|-----------|------|---------|----------|
| id | Integer | id | no |
| user_id | Integer | — | not exposed |
| unit_id | Integer | unit_id | no |
| book_schema | String(50) | — | not in each record (param-based) |
| event_type | String(20) | event_type | no |
| round_index | Integer | round_index | no (default 0) |
| group_index | Integer | group_index | yes |
| group_size | Integer | group_size | yes |
| duration_seconds | Integer | duration_seconds | yes |
| error_count | Integer | error_count | yes (default 0) |
| error_words | JSON | error_words | yes |
| finished_at | DateTime | finished_at | no |

```dart
class GroupMemoryRecord {
  final int id;
  final int unitId;
  final String eventType;      // "group_complete" | "round_complete" | "unit_complete"
  final int roundIndex;
  final int? groupIndex;
  final int? groupSize;
  final int? durationSeconds;
  final int errorCount;
  final List<ErrorWord> errorWords;
  final String finishedAt;     // ISO 8601
}

class ErrorWord {
  final String english;
  final String chinese;
}

class GroupHistoryRequest {
  final int unitId;
  final String? bookSchema;
  final String eventType;
  final int roundIndex;
  final int? groupIndex;
  final int? groupSize;
  final int? durationSeconds;
  final int errorCount;
  final List<ErrorWord>? errorWords;
  final String? finishedAt;
}

class GroupHistoryResponse {
  final int id;
  final String eventType;
  final int unitId;
  final int roundIndex;
}

class GroupHistoryFull {
  final List<GroupMemoryRecord> records;
  final Map<int, int> unitMaxCompletedRound;  // unit_id → max round
  final List<int> unitComplete;
}
```

### 4.8 Statistics DTOs

```dart
class TrendPoint {
  final String date;             // "MM-dd HH:mm"
  final double scorePct;
  final int totalCount;
  final int correctCount;
  final String unitIds;
  final List<String> unitNames;
  final Map<String, UnitScore>? unitScores;  // only for multi-unit quizzes
}

class UnitScore {
  final int total;
  final int correct;
  final double scorePct;
}

class StatsSummary {
  final int totalQuizzes;
  final double avgScore;
  final double bestScore;
  final int totalWordsTested;
  final int totalCorrect;
  final int totalUnitsStudied;
  final int totalGroupSessions;
}
```

### 4.9 Pagination

```dart
class PaginatedResponse<T> {
  final List<T> items;         // NOTE: teacher/words uses "words" not "items"
  final int total;
  final int page;
  final int perPage;
  final int totalPages;        // calculated on backend
}
```

> ⚠️ **不一致**: `/api/history` 用 `items`，`/api/teacher/words` 用 `words`。需要在 Dio interceptor 或 Repository 层做统一适配。

### 4.10 Error Response（统一格式）

```dart
class ApiError {
  final String error;          // always present
  // Never expose stack traces
}
```

---

## 5. 可复用结构分析

### 5.1 统一 BaseResponse（建议 Flutter 层统一包装）

```
所有成功响应都是直接 JSON 对象/数组，没有统一的 {code, message, data} 包装。
需要在 Flutter Dio Interceptor 层处理：
  - HTTP 2xx → 返回 data
  - HTTP 4xx/5xx → 抛出 ApiException(error: message)
  - HTTP 401 → 触发 Refresh/重新登录流程
```

### 5.2 建议抽取的 DTO

| DTO | 复用场景 |
|-----|----------|
| `WordBrief` | Units, Words, Quiz Detail, Teacher Words |
| `QuizSessionBrief` | History list, Teacher sessions |
| `QuizSessionDetail` | History detail, Teacher session detail |
| `PaginatedResponse<T>` | History, Teacher words |
| `BookInfo` | Auth books, Teacher books |
| `UserBrief` | Login, Register, /me |
| `GroupMemoryRecord` | Group history POST/GET, Stats group-history |
| `ErrorWord` | Group history, Stats |

### 5.3 命名不统一问题

| Backend | 建议 DART 命名 | 说明 |
|---------|---------------|------|
| `score_pct` | `scorePct` | snake→camel |
| `unit_ids` (string) | `unitIds` | 后端是逗号分隔字符串，Flutter 层转为 `List<int>` |
| `book_schema` | `bookSchema` | |
| `per_page` | `perPage` | |
| `total_pages` | `totalPages` | |
| `duration_seconds` | `durationSeconds` | |
| `created_at` | `createdAt` | |
| `completed_at` | `completedAt` | |
| `finished_at` | `finishedAt` | |
| `word_id` | `wordId` | |
| `user_answer` | `userAnswer` | |
| `is_correct` | `isCorrect` | |
| `error_count` | `errorCount` | |
| `error_words` | `errorWords` | |
| `event_type` | `eventType` | |
| `round_index` | `roundIndex` | |
| `group_index` | `groupIndex` | |
| `group_size` | `groupSize` | |
| `unit_name` | `unitName` | |
| `order_num` | `orderNum` | |
| `word_count` | `wordCount` | |
| `total_count` | `totalCount` | |
| `correct_count` | `correctCount` | |
| `total_quizzes` | `totalQuizzes` | |
| `avg_score` | `avgScore` | |
| `best_score` | `bestScore` | |
| Pagination: `items` vs `words` | 统一为 `data` 或保持不一致 | 建议 Repository 层统一 |
| `current_book` (可为 null) | `currentBook` (nullable) | |
| `unit_max_completed_round` | `unitMaxCompletedRound` | |
| `unit_complete` | `unitComplete` | |

---

## 6. Repository 设计

### 6.1 Repository 总览

```
lib/repositories/
├── auth_repository.dart
├── unit_repository.dart
├── word_repository.dart
├── quiz_repository.dart
├── history_repository.dart
├── stats_repository.dart
├── group_learning_repository.dart
├── teacher_repository.dart
└── tts_repository.dart
```

### 6.2 AuthRepository

```dart
class AuthRepository {
  Future<UserBrief> register(String username, String password, {String? bookSchema});
  Future<UserBrief> login(String username, String password);
  Future<UserBrief> teacherLogin(String username, String password);
  Future<void> logout();
  Future<BookSwitchResult> switchBook(String bookSchema);
  Future<List<BookInfo>> getBooks();
  Future<UserBrief?> me(); // null → not authenticated
}
```

**依赖 API**: A1, A2, A3, A4, A5, A6, A7

### 6.3 UnitRepository

```dart
class UnitRepository {
  Future<List<UnitBrief>> getUnits({String? bookSchema});
}
```

**依赖 API**: U1

### 6.4 WordRepository

```dart
class WordRepository {
  Future<List<WordBrief>> getWords({String? bookSchema, List<int>? unitIds, bool random = false});
  Future<List<UnitWithWords>> getAllWordsGrouped({String? bookSchema});
  Future<PhonicsData> getPhonics(String word, {String? bookSchema});
}
```

**依赖 API**: W1, W2, W3

### 6.5 QuizRepository

```dart
class QuizRepository {
  Future<QuizSubmitResponse> submitQuiz(QuizSubmitRequest request);
}
```

**依赖 API**: Q1

### 6.6 HistoryRepository

```dart
class HistoryRepository {
  Future<PaginatedResponse<QuizSessionBrief>> getHistory({
    int? unitId, int page = 1, int perPage = 10, String? bookSchema
  });
  Future<QuizSessionDetail> getDetail(int sessionId);
}
```

**依赖 API**: H1, H2

### 6.7 StatsRepository

```dart
class StatsRepository {
  Future<List<TrendPoint>> getTrend({String? bookSchema});
  Future<StatsSummary> getSummary({String? bookSchema});
  Future<List<GroupMemoryRecord>> getGroupHistory({String? bookSchema});
}
```

**依赖 API**: S1, S2, S3

### 6.8 GroupLearningRepository

```dart
class GroupLearningRepository {
  Future<GroupHistoryResponse> submitHistory(GroupHistoryRequest request);
  Future<GroupHistoryFull> getHistory({String? bookSchema, int? unitId});
}
```

**依赖 API**: G1, G2

### 6.9 TeacherRepository

```dart
class TeacherRepository {
  Future<List<StudentInfo>> getStudents();
  Future<StudentInfo> getStudentDetail(int studentId);
  Future<List<QuizSessionBrief>> getStudentSessions(int studentId);
  Future<QuizSessionDetail> getStudentSessionDetail(int studentId, int sessionId);
  Future<List<BookInfo>> getBooks();
  Future<PaginatedResponse<WordBrief>> getWords({int? unitId, int page = 1, int perPage = 50, String? bookSchema});
  Future<WordBrief> createWord({required int unitId, required String english, required String chinese, String? bookSchema});
  Future<WordBrief> updateWord(int wordId, {int? unitId, String? english, String? chinese, String? bookSchema});
  Future<void> deleteWord(int wordId, {String? bookSchema});
}
```

**依赖 API**: T1-T9

### 6.10 TtsRepository

```dart
class TtsRepository {
  // Returns audio bytes (Uint8List) or a stream
  Future<Uint8List> speak(String text, {String lang = 'en'});
}
```

**依赖 API**: TTS1

---

## 7. 网络层设计

### 7.1 ApiClient（Dio Singleton）

```dart
class ApiClient {
  late final Dio dio;

  // Base URL from config
  // Interceptors: JWT/Session, Logging, Retry, Error

  // Cookie-based auth (Flask-Login session cookie)
  // On Android, Dio automatically manages cookies via cookieJar
}
```

### 7.2 Interceptors

| Interceptor | 职责 |
|-------------|------|
| AuthInterceptor | 自动附带 Session Cookie；401 时触发重新登录 |
| LoggingInterceptor | Debug 模式下打印请求/响应 |
| ErrorInterceptor | 统一转换 DioException → AppException |
| RetryInterceptor | 网络错误时自动重试（最多 3 次，指数退避） |

### 7.3 异常体系

```dart
sealed class AppException implements Exception {
  final String message;
}
class NetworkException extends AppException { ... }
class AuthException extends AppException { ... }       // 401
class ForbiddenException extends AppException { ... }  // 403
class NotFoundException extends AppException { ... }   // 404
class ConflictException extends AppException { ... }   // 409
class ValidationException extends AppException { ... } // 400
class ServerException extends AppException { ... }     // 500/502
class TimeoutException extends AppException { ... }
class UnknownException extends AppException { ... }
```

---

## 8. 【建议新增 API】

> ⚠️ 这些 API 目前不存在，但 Flutter App 的某些功能可能需要。**不要修改 Backend，先确认是否需要。**

### 8.1 【建议】`GET /api/auth/profile` — 获取学生个人信息
- **原因**: `/me` 返回信息太少，没有 `created_at`, `total_quizzes`, `current_book` 显示名
- **替代方案**: 当前前端组合 `/me` + `/stats/summary` 可凑齐信息

### 8.2 【建议】`PUT /api/auth/profile` — 修改密码
- **原因**: 当前没有修改密码的 API
- **影响**: 移动端用户应该能改密码

### 8.3 【建议】`GET /api/units/<unit_id>` — 获取单个单元详情
- **原因**: 当前只有列表接口
- **影响**: 小，前端按需使用列表即可

### 8.4 【建议】`GET /api/stats/unit-progress` — 获取每个单元的学习进度
- **原因**: 当前需要组合 `group-learning/history` + `units` 来计算，逻辑分散
- **替代方案**: Flutter 客户端自己组合计算

### 8.5 【建议】`GET /api/words/<word_id>` — 获取单个单词详情
- **原因**: 按需获取单词详情（含 phonics），避免一次加载全部
- **影响**: 小，Flashcard 模式需要单个单词的完整数据

### 8.6 【建议】`DELETE /api/auth/account` — 注销账号
- **原因**: 隐私合规要求
- **影响**: GDPR/个人信息保护法合规

### 8.7 【缺陷】Quiz Submit 不支持 `?random=1` 区分模式
- **分析**: Quiz submit 传 `unit_ids` 和 `answers`，但没有区分随机模式/顺序模式
- **解决**: 当前不区分，提交什么存什么，Flutter 侧记录 mode 仅本地对比

---

## 9. 数据流

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter App                           │
│                                                         │
│  Widgets ──► State (Riverpod) ──► Repository ──► Dio   │
│     ▲                               │                   │
│     │                               │                   │
│     └────── AsyncValue ◄────────────┘                   │
│                                                         │
│  Repository 层职责：                                     │
│    1. 参数序列化（camelCase → snake_case JSON key）     │
│    2. 响应反序列化（snake_case JSON key → camelCase）   │
│    3. unit_ids (String "1,2" → List<int> [1,2])         │
│    4. 类型安全（int/double/bool 严格转换）              │
│    5. 异常转换（DioException → AppException）           │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│              Flask Backend (Session Cookie Auth)         │
│                                                         │
│  Blueprint → Route → Model (SQLAlchemy) → PostgreSQL    │
│                                                         │
│  Response: { "key": value } JSON (no wrapper)            │
│  Error:    { "error": "message" } + HTTP Status          │
└─────────────────────────────────────────────────────────┘
```

---

## 10. 是否需要 Backend 修改

| 项目 | 结论 |
|------|------|
| 新增 API | **不建议，除非确认必要** |
| 修改现有 API 签名 | **不修改** |
| 统一 JSON 返回格式 | **不修改**（Flutter 层适配） |
| Flask-Login → JWT | **暂不修改**（Flutter Dio CookieJar 兼容 Session） |
| CORS | **可能需要添加 `Access-Control-Allow-Origin`**（但 App 用 Dio，非浏览器，不需要 CORS） |

---

## 11. 下一阶段计划 (Milestone 1)

确认本 Contract 后：

1. **Flutter Project Init**: `flutter create --org com.vocabmem vocabulary_memorization`
2. **目录结构**: Feature First + MVVM + Repository Pattern
3. **核心依赖**: Dio, Riverpod, GoRouter, Material 3, Google Fonts
4. **网络层**: ApiClient + Dio Interceptors + Error Handler
5. **Model 层**: 所有 DTO（基于本文档）+ JSON serialization
6. **Repository 层**: 所有 Repository 实现
7. **Config 层**: Base URL, Timeout 等

---

## 附录：API 统计

| 模块 | 接口数 | 需认证 | 分页 |
|------|--------|--------|------|
| Auth | 7 | 3 公开 | — |
| Units | 1 | 全部 | — |
| Words | 3 | 全部 | — |
| Quiz | 1 | 全部 | — |
| History | 2 | 全部 | H1 |
| Stats | 3 | 全部 | — |
| Group Learning | 2 | 全部 | — |
| Teacher | 9 | 全部（Teacher） | T6 |
| TTS | 1 | 全部 | — |
| **合计** | **29** | | **2** |
