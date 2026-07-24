/// Application-wide constants.
///
/// All magic values, default parameters, and configuration keys
/// are centralized here. Never hardcode these values in widgets
/// or repositories.
class AppConstants {
  AppConstants._();

  // ── API ────────────────────────────────────────────────────

  /// Base URL of the backend server.
  /// Override via --dart-define=BASE_URL=... at build time.
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://your-domain.com',
  );

  /// API prefix applied to every backend request.
  static const String apiPrefix = '/api';

  /// Request timeout in milliseconds.
  static const int connectTimeoutMs = 15000;
  static const int receiveTimeoutMs = 30000;

  /// Maximum retry count for transient failures.
  static const int maxRetries = 3;

  // ── Pagination ─────────────────────────────────────────────

  static const int defaultPageSize = 10;
  static const int teacherPageSize = 50;

  // ── Auth ───────────────────────────────────────────────────

  static const int minUsernameLength = 2;
  static const int maxUsernameLength = 50;
  static const int minPasswordLength = 3;

  // ── Session Cookie ─────────────────────────────────────────

  static const String cookieSessionKey = 'session';
  static const String cookieRememberKey = 'remember_token';

  // ── Group Learning ─────────────────────────────────────────

  /// How many words constitute one group during grouped memorization.
  static const int defaultGroupSize = 5;

  // ── TTS ────────────────────────────────────────────────────

  static const String ttsDefaultLang = 'en';

  // ── Local Storage Keys ─────────────────────────────────────

  static const String prefCurrentBook = 'current_book';
  static const String prefThemeMode = 'theme_mode';
  static const String prefLocale = 'locale';
}

/// Well-known book schema identifiers returned by the backend.
enum BookSchema {
  grade6Vol1('grade6_vol1'),
  seniorCompulsory1('senior_compulsory_1');

  const BookSchema(this.value);
  final String value;
}

/// The three valid event types for group-memory history.
enum GroupEventType {
  groupComplete('group_complete'),
  roundComplete('round_complete'),
  unitComplete('unit_complete');

  const GroupEventType(this.value);
  final String value;
}
