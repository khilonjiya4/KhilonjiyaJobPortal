import 'package:flutter/material.dart';

import '../presentation/role_selection/role_selection_screen.dart';
import '../presentation/auth/job_seeker_login_screen.dart';
import '../presentation/auth/employer_login_screen.dart';

import 'home_router.dart';

// JOB SEEKER MAIN SHELL (BOTTOM NAV)
import '../presentation/home_marketplace_feed/job_seeker_main_shell.dart';

// PROFILE EDIT (PUSH PAGE)
import '../presentation/home_marketplace_feed/profile_edit_page.dart';

// SETTINGS
import '../presentation/home_marketplace_feed/settings_page.dart';

// LEGAL + ABOUT + SUPPORT
import '../presentation/home_marketplace_feed/legal/privacy_policy_page.dart';
import '../presentation/home_marketplace_feed/legal/terms_and_conditions_page.dart';
import '../presentation/home_marketplace_feed/legal/refund_policy_page.dart';
import '../presentation/home_marketplace_feed/about/about_app_page.dart';
import '../presentation/home_marketplace_feed/support/contact_support_page.dart';

// SETTINGS PAGES
import '../presentation/home_marketplace_feed/settings/notifications_settings_page.dart';
import '../presentation/home_marketplace_feed/settings/language_settings_page.dart';

// EMPLOYER
import '../presentation/company/dashboard/company_dashboard.dart';
import '../presentation/company/jobs/create_job_screen.dart';
import '../presentation/company/jobs/employer_job_list_screen.dart';
import '../presentation/company/jobs/job_applicants_screen.dart';

// ✅ NEW: PIPELINE
import '../presentation/company/jobs/job_applicants_pipeline_page.dart';

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
  // EMPLOYER
  // ------------------------------------------------------------
  static const String companyDashboard = '/company-dashboard';
  static const String employerJobs = '/employer-jobs';
  static const String createJob = '/create-job';

  // Requires argument: jobId (String)
  static const String jobApplicants = '/job-applicants';

  // ✅ NEW: Requires arguments: { jobId, companyId }
  static const String jobApplicantsPipeline = '/job-applicants-pipeline';

  // ------------------------------------------------------------
  // ROUTES MAP (NO-ARGUMENT ROUTES ONLY)
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

    // employer
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

      // ✅ NEW: PIPELINE ROUTE
      case jobApplicantsPipeline:
        final args = settings.arguments;

        if (args == null || args is! Map) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(
                child: Text("Missing arguments for pipeline page"),
              ),
            ),
          );
        }

        final jobId = (args['jobId'] ?? '').toString();
        final companyId = (args['companyId'] ?? '').toString();

        if (jobId.trim().isEmpty || companyId.trim().isEmpty) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(
                child: Text("jobId/companyId missing for pipeline page"),
              ),
            ),
          );
        }

        return MaterialPageRoute(
          builder: (_) => JobApplicantsPipelinePage(
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

  //