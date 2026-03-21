import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../providers/supabase_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  
  // To avoid constant rebuild loops, we just read the current user.
  // Actually, go_router will rebuild when the routerProvider is watched with authState.
  
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      // If auth state is initializing, don't redirect yet
      if (authState.isLoading) return null;

      final session = authState.value?.session;
      final isAuth = session != null;
      final isGoingToLogin = state.uri.toString() == '/login' || state.uri.toString() == '/register';

      if (!isAuth && !isGoingToLogin) {
        return '/login';
      }
      if (isAuth && isGoingToLogin) {
        return '/dashboard';
      }
      return null;
    },
    routes: [
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
    ],
  );
});
