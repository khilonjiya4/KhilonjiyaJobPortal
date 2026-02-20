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

// EMPLOYER (KEPT FOR COMPILATION)
import '../presentation/company/dashboard/company_dashboard.dart';
import '../presentation/company/dashboard/create_organization_screen.dart';
import '../presentation/company/jobs/create_job_screen.dart';
import '../presentation/company/jobs/employer_job_list_screen.dart';
import '../presentation/company/jobs/job_applicants_screen.dart';
import '../presentation/company/notifications/employer_notifications_page.dart';

class AppRoutes {
  static const String initial = '/';
  static const String roleSelection = '/role-selection';

  static const String jobSeekerLogin = '/job-seeker-login';
  static const String employerLogin = '/employer-login';

  static const String home = '/home';
  static const String jobSeekerHome = '/job-seeker-home';

  static const String profileEdit = '/profile-edit';

  static const String settings = '/settings';
  static const String notificationsSettings = '/settings-notifications';
  static const String languageSettings = '/settings-language';

  static const String privacyPolicy = '/privacy-policy';
  static const String termsAndConditions = '/terms-and-conditions';
  static const String refundPolicy = '/refund-policy';

  static const String aboutApp = '/about';
  static const String contactSupport = '/contact-support';

  // ------------------------------------------------------------
  // EMPLOYER ROUTES (RESTORED FOR BUILD)
  // ------------------------------------------------------------
  static const String companyDashboard = '/company-dashboard';
  static const String createOrganization = '/create-organization';
  static const String employerJobs = '/employer-jobs';
  static const String createJob = '/create-job';
  static const String jobApplicants = '/job-applicants';
  static const String employerNotifications = '/employer-notifications';

  static final Map<String, WidgetBuilder> routes = {
    initial: (_) => const RoleSelectionScreen(),
    roleSelection: (_) => const RoleSelectionScreen(),

    jobSeekerLogin: (_) => const JobSeekerLoginScreen(),
    employerLogin: (_) => const EmployerLoginScreen(),

    home: (_) => const HomeRouter(),
    jobSeekerHome: (_) => const JobSeekerMainShell(),

    profileEdit: (_) => const ProfileEditPage(),

    settings: (_) => const SettingsPage(),
    notificationsSettings: (_) => const NotificationsSettingsPage(),
    languageSettings: (_) => const LanguageSettingsPage(),

    privacyPolicy: (_) => const PrivacyPolicyPage(),
    termsAndConditions: (_) => const TermsAndConditionsPage(),
    refundPolicy: (_) => const RefundPolicyPage(),

    aboutApp: (_) => const AboutAppPage(),
    contactSupport: (_) => const ContactSupportPage(),

    // EMPLOYER (kept but not linked from UI)
    companyDashboard: (_) => const CompanyDashboard(),
    createOrganization: (_) => const CreateOrganizationScreen(),
    employerJobs: (_) => const EmployerJobListScreen(),
    createJob: (_) => const CreateJobScreen(),
    employerNotifications: (_) => const EmployerNotificationsPage(),
  };

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    if (settings.name == jobApplicants) {
      final args = settings.arguments as Map?;
      final jobId = args?['jobId']?.toString() ?? '';
      final companyId = args?['companyId']?.toString();

      return MaterialPageRoute(
        builder: (_) => JobApplicantsScreen(
          jobId: jobId,
          companyId: companyId,
        ),
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
}