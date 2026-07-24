/// Centralized API path constants.
///
/// Every backend endpoint is defined here as a static const.
/// Repositories MUST reference these constants — never inline strings.
///
/// Generated from Milestone 0 Backend API Inventory (29 endpoints).
class ApiPaths {
  ApiPaths._();

  // ── Auth ───────────────────────────────────────────────────
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String teacherLogin = '/auth/teacher/login';
  static const String logout = '/auth/logout';
  static const String switchBook = '/auth/book';
  static const String listBooks = '/auth/books';
  static const String me = '/auth/me';

  // ── Units ──────────────────────────────────────────────────
  static const String units = '/units';

  // ── Words ──────────────────────────────────────────────────
  static const String words = '/words';
  static const String wordsAll = '/words/all';
  static const String wordsPhonics = '/words/phonics';

  // ── Quiz ───────────────────────────────────────────────────
  static const String quizSubmit = '/quiz/submit';

  // ── History ────────────────────────────────────────────────
  static const String history = '/history';
  static String historyDetail(int sessionId) => '/history/$sessionId';

  // ── Stats ──────────────────────────────────────────────────
  static const String statsTrend = '/stats/trend';
  static const String statsSummary = '/stats/summary';
  static const String statsGroupHistory = '/stats/group-history';

  // ── Group Learning ─────────────────────────────────────────
  static const String groupLearningHistory = '/group-learning/history';

  // ── Teacher ────────────────────────────────────────────────
  static const String teacherStudents = '/teacher/students';
  static String teacherStudentDetail(int id) => '/teacher/students/$id';
  static String teacherStudentSessions(int id) =>
      '/teacher/students/$id/sessions';
  static String teacherStudentSessionDetail(int studentId, int sessionId) =>
      '/teacher/students/$studentId/sessions/$sessionId';
  static const String teacherBooks = '/teacher/books';
  static const String teacherWords = '/teacher/words';
  static String teacherWordDetail(int wordId) => '/teacher/words/$wordId';

  // ── TTS ────────────────────────────────────────────────────
  static const String tts = '/tts';
}
