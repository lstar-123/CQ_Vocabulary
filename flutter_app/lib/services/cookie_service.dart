import 'package:cookie_jar/cookie_jar.dart';

/// Service wrapper around [PersistCookieJar] for session management.
///
/// The [ApiClient] manages cookies automatically via [CookieManager],
/// but this service provides the imperative API needed for login/logout
/// flows (e.g., clearing cookies on logout, checking session existence).
class CookieService {
  CookieService(this._cookieJar);

  final PersistCookieJar _cookieJar;

  /// Check whether any cookies exist (crude session check).
  Future<bool> hasSession() async {
    final cookies = await _cookieJar.loadForRequest(
      Uri.parse('https://placeholder'),
    );
    return cookies.isNotEmpty;
  }

  /// Clear all stored cookies (e.g., on logout).
  Future<void> clearAll() async {
    await _cookieJar.deleteAll();
  }
}
