import 'package:flutter/material.dart';

import '../presentation/role_selection/role_selection_screen.dart';
import '../presentation/auth/job_seeker_login_screen.dart';
import '../presentation/auth/employer_login_screen.dart';

import 'home_router.dart';

// JOB SEEKER MAIN SHELL
import '../presentation/home_marketplace_feed/job_seeker_main_shell.dart';

// PROFILE EDIT
import '../presentation/home_marketplace_feed/profile_edit_page.dart';

// SETTINGS
import '../presentation/home_marketplace_feed/settings_page.dart';

// LEGAL + ABOUT + SUPPORT
import '../presentation/home_marketplace_feed/legal/privacy_policy_page.dart';
import '../presentation/home_marketplace_feed/legal/terms_and_conditions_page.dart';
import '../presentation/home_marketplace_feed/legal/refund_policy_page.dart';
import '../presentation/home_marketplace_feed/about/about_app_page.dart';
import '../presentation/home_marketplace_feed/support/contact_support_page.dart';

// SETTINGS CHILD PAGES
import '../presentation/home_marketplace_feed/settings/notifications_settings_page.dart';
import '../presentation/home_marketplace_feed/settings/language_settings_page.dart';

class AppRoutes {
  // ------------------------------------------------------------
  // CORE
  // ------------------------------------------------------------
  static const String initial = '/';

  // ------------------------------------------------------------
  // ROLE SELECTION
  // ------------------------------------------------------------
  static const String roleSelection = '/role-selection';

  // ------------------------------------------------------------
  // AUTH
  // ------------------------------------------------------------
  static const String jobSeekerLogin = '/job-seeker-login';
  static const String employerLogin = '/employer-login';

  // ------------------------------------------------------------
  // POST LOGIN
  // ------------------------------------------------------------
  static const String home = '/home';
  static const String jobSeekerHome = '/job-seeker-home';

  // ------------------------------------------------------------
  // JOB SEEKER
  // ------------------------------------------------------------
  static const String profileEdit = '/profile-edit';

  // ------------------------------------------------------------
  // SETTINGS
  // ------------------------------------------------------------
  static const String settings = '/settings';
  static const String notificationsSettings = '/settings-notifications';
  static const String languageSettings = '/settings-language';

  // ------------------------------------------------------------
  // LEGAL
  // ------------------------------------------------------------
  static const String privacyPolicy = '/privacy-policy';
  static const String termsAndConditions = '/terms-and-conditions';
  static const String refundPolicy = '/refund-policy';

  // ------------------------------------------------------------
  // ABOUT + SUPPORT
  // ------------------------------------------------------------
  static const String aboutApp = '/about';
  static const String contactSupport = '/contact-support';

  // ------------------------------------------------------------
  // ROUTES MAP (NO ARG ROUTES)
  // ------------------------------------------------------------
  static final Map<String, WidgetBuilder> routes = {
    initial: (_) => const RoleSelectionScreen(),
    roleSelection: (_) => const RoleSelectionScreen(),

    jobSeekerLogin: (_) => const JobSeekerLoginScreen(),
    employerLogin: (_) => const EmployerLoginScreen(),

    home: (_) => const HomeRouter(),
    jobSeekerHome: (_) => const JobSeekerMainShell(),

    profileEdit: (_) => const ProfileEditPage(),

    // settings root
    settings: (_) => const SettingsPage(),

    // settings children
    notificationsSettings: (_) => const NotificationsSettingsPage(),
    languageSettings: (_) => const LanguageSettingsPage(),

    // legal
    privacyPolicy: (_) => const PrivacyPolicyPage(),
    termsAndConditions: (_) => const TermsAndConditionsPage(),
    refundPolicy: (_) => const RefundPolicyPage(),

    // about + support
    aboutApp: (_) => const AboutAppPage(),
    contactSupport: (_) => const ContactSupportPage(),
  };

  // ------------------------------------------------------------
  // onGenerateRoute (NO EMPLOYER CASES)
  // ------------------------------------------------------------
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        body: Center(
          child: Text("Route not found: ${settings.name}"),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // HELPERS
  // ------------------------------------------------------------
  static Future<void> pushAndClearStack(
    BuildContext context,
    String routeName,
  ) async {
    await Navigator.of(context).pushNamedAndRemoveUntil(
      routeName,
      (_) => false,
    );
  }

  static Future<void> pushNamed(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) async {
    await Navigator.of(context).pushNamed(
      routeName,
      arguments: arguments,
    );
  }

  static Future<void> pushReplacementNamed(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) async {
    await Navigator.of(context).pushReplacementNamed(
      routeName,
      arguments: arguments,
    );
  }

  static void pop(BuildContext context, [dynamic result]) {
    Navigator.of(context).pop(result);
  }

  static bool canPop(BuildContext context) {
    return Navigator.of(context).canPop();
  }

  static T? getArguments<T>(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    return args is T ? args : null;
  }

  static String? getCurrentRouteName(BuildContext context) {
    return ModalRoute.of(context)?.settings.name;
  }
}