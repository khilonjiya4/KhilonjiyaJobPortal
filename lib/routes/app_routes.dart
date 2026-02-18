import 'package:flutter/material.dart';

import '../presentation/role_selection/role_selection_screen.dart';
import '../presentation/auth/job_seeker_login_screen.dart';
import '../presentation/auth/employer_login_screen.dart';

import 'home_router.dart';

// JOB SEEKER MAIN SHELL (BOTTOM NAV)
import '../presentation/home_marketplace_feed/job_seeker_main_shell.dart';

// PROFILE EDIT (PUSH PAGE)
import '../presentation/home_marketplace_feed/profile_edit_page.dart';

// SETTINGS + PAGES
import '../presentation/home_marketplace_feed/settings_page.dart';
import '../presentation/home_marketplace_feed/notification_settings_page.dart';
import '../presentation/home_marketplace_feed/privacy_settings_page.dart';
import '../presentation/home_marketplace_feed/language_settings_page.dart';
import '../presentation/home_marketplace_feed/about_page.dart';
import '../presentation/home_marketplace_feed/policies_page.dart';
import '../presentation/home_marketplace_feed/webview_page.dart';

// EMPLOYER
import '../presentation/company/dashboard/company_dashboard.dart';
import '../presentation/company/jobs/create_job_screen.dart';
import '../presentation/company/jobs/employer_job_list_screen.dart';
import '../presentation/company/jobs/job_applicants_screen.dart';

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
  // POST LOGIN (ROLE BASED)
  // ------------------------------------------------------------
  static const String home = '/home';

  // ------------------------------------------------------------
  // JOB SEEKER
  // ------------------------------------------------------------
  static const String jobSeekerHome = '/job-seeker-home';
  static const String profileEdit = '/profile-edit';

  // Settings
  static const String settings = '/settings';
  static const String notificationSettings = '/settings-notifications';
  static const String privacySettings = '/settings-privacy';
  static const String languageSettings = '/settings-language';
  static const String about = '/about';
  static const String policies = '/policies';

  // WebView
  static const String webview = '/webview';

  // ------------------------------------------------------------
  // EMPLOYER
  // ------------------------------------------------------------
  static const String companyDashboard = '/company-dashboard';
  static const String employerJobs = '/employer-jobs';
  static const String createJob = '/create-job';

  // Requires argument: jobId (String)
  static const String jobApplicants = '/job-applicants';

  // ------------------------------------------------------------
  // ROUTES MAP (NO-ARGUMENT ROUTES ONLY)
  // ------------------------------------------------------------
  static final Map<String, WidgetBuilder> routes = {
    // Safety
    initial: (_) => const RoleSelectionScreen(),

    // Role selection
    roleSelection: (_) => const RoleSelectionScreen(),

    // Login
    jobSeekerLogin: (_) => const JobSeekerLoginScreen(),
    employerLogin: (_) => const EmployerLoginScreen(),

    // Role based router (final truth)
    home: (_) => const HomeRouter(),

    // Job seeker shell
    jobSeekerHome: (_) => const JobSeekerMainShell(),

    // Profile edit
    profileEdit: (_) => const ProfileEditPage(),

    // Settings
    settings: (_) => const SettingsPage(),
    notificationSettings: (_) => const NotificationSettingsPage(),
    privacySettings: (_) => const PrivacySettingsPage(),
    languageSettings: (_) => const LanguageSettingsPage(),
    about: (_) => const AboutPage(),
    policies: (_) => const PoliciesPage(),

    // Employer
    companyDashboard: (_) => const CompanyDashboard(),
    employerJobs: (_) => const EmployerJobListScreen(),
    createJob: (_) => const CreateJobScreen(),
  };

  // ------------------------------------------------------------
  // onGenerateRoute (ARGUMENT ROUTES)
  // ------------------------------------------------------------
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case jobApplicants:
        final jobId = settings.arguments;

        if (jobId == null || jobId is! String || jobId.trim().isEmpty) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(
                child: Text("Job ID missing for applicants screen"),
              ),
            ),
          );
        }

        return MaterialPageRoute(
          builder: (_) => JobApplicantsScreen(jobId: jobId),
        );

      case webview:
        final args = settings.arguments;

        if (args == null || args is! Map) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(
                child: Text("Invalid WebView arguments"),
              ),
            ),
          );
        }

        final title = (args['title'] ?? '').toString().trim();
        final url = (args['url'] ?? '').toString().trim();

        if (title.isEmpty || url.isEmpty) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(
                child: Text("Missing title or url"),
              ),
            ),
          );
        }

        return MaterialPageRoute(
          builder: (_) => WebViewPage(title: title, url: url),
        );
    }

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