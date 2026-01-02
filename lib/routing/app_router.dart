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
import '../features/auth/domain/user_model.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  // Use a Listenable that notifies when auth state changes
  // We use ValueNotifier to bridge Riverpod state to GoRouter
  final authStateNotifier = ValueNotifier<AsyncValue<UserModel?>>(const AsyncValue.loading());

  // Keep the notifier in sync with the provider
  ref.onDispose(authStateNotifier.dispose);
  
  ref.listen<AsyncValue<UserModel?>>(
    authNotifierProvider,
    (previous, next) {
      authStateNotifier.value = next;
    },
    fireImmediately: true,
  );

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authStateNotifier,
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      
      // If still loading (initial), don't redirect yet or show loading?
      // But typically we wait for data.
      // If we have data (even null), we can decide.
      if (authState.isLoading) return null;

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
        path: '/favorites',
        builder: (context, state) => const PersonalizedJobsScreen(title: 'Favoriler'),
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
        builder: (context, state) {
          final jobToEdit = state.extra as JobModel?;
          return AddJobScreen(jobToEdit: jobToEdit);
        },
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
