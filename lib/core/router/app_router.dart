import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/auth/presentation/screens/profile_screen.dart';
import '../../features/auth/providers/onboarding_provider.dart';
import '../providers/supabase_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final onboardingState = ref.watch(onboardingProvider);
  
  return GoRouter(
    initialLocation: '/onboarding',
    redirect: (context, state) {
      // If auth state or onboarding state is loading, don't redirect yet
      if (authState.isLoading || onboardingState.isLoading) return null;

      final session = authState.value?.session;
      final isAuth = session != null;
      final hasSeenOnboarding = onboardingState.value ?? false;
      
      final currentPath = state.uri.toString();
      final isGoingToOnboarding = currentPath == '/onboarding';
      final isGoingToAuth = currentPath == '/login' || currentPath == '/register';

      // 1. If not seen onboarding and not already going there, redirect to onboarding
      if (!hasSeenOnboarding && !isGoingToOnboarding) {
        return '/onboarding';
      }

      // 2. If seen onboarding but on onboarding page, redirect to dashboard IF authenticated
      if (isAuth && isGoingToOnboarding) {
        return '/dashboard';
      }

      // 3. Auth redirection logic
      if (!isAuth && !isGoingToAuth && !isGoingToOnboarding) {
        return '/login';
      }
      if (isAuth && (isGoingToAuth || isGoingToOnboarding)) {
        return '/dashboard';
      }
      
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
});
