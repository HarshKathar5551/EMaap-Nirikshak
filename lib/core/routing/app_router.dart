import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/dashboard/presentation/screens/owner_dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/officer_dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/gatc_dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/admin_dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/public_verification_screen.dart';
import '../../models/user_model.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final loc = state.uri.toString();
      final isAuth = authState.isAuthenticated;
      final user = authState.user;

      // Public verification and splash don't require login
      if (loc == '/' || loc.startsWith('/public')) {
        return null;
      }

      // If on login screen but already authenticated, route to appropriate dashboard
      if (loc == '/login') {
        if (isAuth && user != null) {
          switch (user.role) {
            case UserRole.owner:
              return '/dashboard/owner';
            case UserRole.officer:
              return '/dashboard/officer';
            case UserRole.gatc:
              return '/dashboard/gatc';
            case UserRole.admin:
              return '/dashboard/admin';
            case UserRole.public:
              return '/public/verify';
          }
        }
        return null;
      }

      // Protected dashboard routes
      if (loc.startsWith('/dashboard')) {
        if (!isAuth || user == null) {
          return '/login';
        }

        // Role-based route authorization guards
        if (loc.startsWith('/dashboard/admin') && user.role != UserRole.admin) {
          // Non-admin attempting to access admin route gets redirected to their own dashboard
          return _dashboardPathForRole(user.role);
        }

        if (loc.startsWith('/dashboard/officer') &&
            user.role != UserRole.officer &&
            user.role != UserRole.admin) {
          return _dashboardPathForRole(user.role);
        }

        if (loc.startsWith('/dashboard/owner') &&
            user.role != UserRole.owner &&
            user.role != UserRole.admin) {
          return _dashboardPathForRole(user.role);
        }

        if (loc.startsWith('/dashboard/gatc') &&
            user.role != UserRole.gatc &&
            user.role != UserRole.admin) {
          return _dashboardPathForRole(user.role);
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/dashboard/owner',
        builder: (context, state) => const OwnerDashboardScreen(),
      ),
      GoRoute(
        path: '/dashboard/officer',
        builder: (context, state) => const OfficerDashboardScreen(),
      ),
      GoRoute(
        path: '/dashboard/gatc',
        builder: (context, state) => const GatcDashboardScreen(),
      ),
      GoRoute(
        path: '/dashboard/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/public/verify',
        builder: (context, state) => const PublicVerificationScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text('Invalid Route: ${state.uri.toString()}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/login'),
              child: const Text('Return to Login'),
            ),
          ],
        ),
      ),
    ),
  );
});

String _dashboardPathForRole(UserRole role) {
  switch (role) {
    case UserRole.owner:
      return '/dashboard/owner';
    case UserRole.officer:
      return '/dashboard/officer';
    case UserRole.gatc:
      return '/dashboard/gatc';
    case UserRole.admin:
      return '/dashboard/admin';
    case UserRole.public:
      return '/public/verify';
  }
}
