import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/presentation/auth_provider.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/jobs/presentation/home_screen.dart';
import '../features/jobs/presentation/job_detail_screen.dart';
import '../features/jobs/presentation/add_job_screen.dart';
import '../features/jobs/presentation/edit_job_screen.dart';
import '../features/personalization/presentation/interests_screen.dart';
import '../features/personalization/presentation/personalized_jobs_screen.dart';
import '../features/jobs/domain/job_model.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: ValueNotifier(authState), // Simple refresh trigger
    redirect: (context, state) {
      final isLoggedIn = authState.asData?.value != null;
      final isLoggingIn = state.uri.toString() == '/login';

      if (!isLoggedIn && !isLoggingIn) return '/login';
      if (isLoggedIn && isLoggingIn) return '/home';

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/interests',
        builder: (context, state) => const InterestsScreen(),
      ),
      GoRoute(
        path: '/personalized',
        builder: (context, state) => const PersonalizedJobsScreen(),
      ),
      GoRoute(
        path: '/detail',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          final job = extra['job'] as JobModel;
          final showSalary = extra['showSalary'] as bool;
          return JobDetailScreen(job: job, showSalary: showSalary);
        },
      ),
      GoRoute(
        path: '/add_job',
        builder: (context, state) => const AddJobScreen(),
      ),
      GoRoute(
        path: '/edit_job',
        builder: (context, state) {
          final job = state.extra as JobModel;
          return EditJobScreen(job: job);
        },
      ),
    ],
  );
});
