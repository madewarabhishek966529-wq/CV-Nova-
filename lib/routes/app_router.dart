import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/splash/splash_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/resume/resume_list_screen.dart';
import '../screens/resume/resume_editor_screen.dart';
import '../screens/resume/resume_preview_screen.dart';
import '../screens/ats/ats_analyzer_screen.dart';
import 'route_names.dart';

/// App-wide router. CVNova is single-user/local — there's no login/signup
/// flow and nothing to redirect-gate here. The splash screen is purely a
/// branding beat before landing on the dashboard.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: RouteNames.resumeList,
        builder: (context, state) => const ResumeListScreen(),
      ),
      GoRoute(
        path: '${RouteNames.resumeEditor}/:id',
        builder: (context, state) =>
            ResumeEditorScreen(resumeId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '${RouteNames.resumePreview}/:id',
        builder: (context, state) =>
            ResumePreviewScreen(resumeId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: RouteNames.atsAnalyzer,
        builder: (context, state) => const AtsAnalyzerScreen(),
      ),
    ],
  );
});
