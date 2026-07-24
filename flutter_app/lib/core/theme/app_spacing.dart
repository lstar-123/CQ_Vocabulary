/// Spacing scale used throughout the app.
///
/// Follows an 8-point grid system. Every margin, padding, and gap
/// must reference a value from this class.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Standard card border radius.
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;

  /// Standard icon sizes.
  static const double iconSm = 16;
  static const double iconMd = 24;
  static const double iconLg = 32;

  /// Standard avatar sizes.
  static const double avatarSm = 32;
  static const double avatarMd = 48;
  static const double avatarLg = 64;

  /// Max content width for tablet layouts.
  static const double maxContentWidth = 640;
}
