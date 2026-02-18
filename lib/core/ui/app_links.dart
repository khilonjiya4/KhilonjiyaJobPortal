// File: lib/core/ui/app_links.dart

class AppLinks {
  // ------------------------------------------------------------
  // COMPANY
  // ------------------------------------------------------------
  static const String companyName = 'Khilonjiya India Private Limited';

  // ------------------------------------------------------------
  // WEBSITE (SET THIS LATER)
  // ------------------------------------------------------------
  /// Example:
  /// https://khilonjiya.in
  /// https://www.khilonjiya.in
  static const String websiteBase = '';

  static bool get hasWebsite => websiteBase.trim().isNotEmpty;

  static String get websiteUrl => hasWebsite ? websiteBase : '';

  // ------------------------------------------------------------
  // LEGAL URLS (AUTO GENERATED FROM websiteBase)
  // ------------------------------------------------------------
  /// Recommended website pages:
  /// /privacy-policy
  /// /terms
  /// /refund-policy
  /// /contact

  static String get privacyPolicyUrl =>
      hasWebsite ? "$websiteBase/privacy-policy" : '';

  static String get termsUrl => hasWebsite ? "$websiteBase/terms" : '';

  static String get refundPolicyUrl =>
      hasWebsite ? "$websiteBase/refund-policy" : '';

  static String get contactSupportUrl =>
      hasWebsite ? "$websiteBase/contact" : '';

  // ------------------------------------------------------------
  // SUPPORT
  // ------------------------------------------------------------
  static const String supportEmail = 'support@khilonjiya.in';

  /// Optional later
  static const String supportPhone = '';
  static const String supportWhatsapp = '';

  // ------------------------------------------------------------
  // PLAY STORE
  // ------------------------------------------------------------
  /// Example:
  /// https://play.google.com/store/apps/details?id=com.khilonjiya.app
  static const String playStoreUrl = '';
}