import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/resume/resume_list_screen.dart';
import '../screens/resume/resume_editor_screen.dart';
import '../screens/resume/resume_preview_screen.dart';
import 'route_names.dart';

/// App-wide router. Auth-gated redirects will be added in a later phase
/// once the real session provider exists — kept intentionally simple here.
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
        path: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.signup,
        builder: (context, state) => const SignupScreen(),
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
    ],
  );
});
