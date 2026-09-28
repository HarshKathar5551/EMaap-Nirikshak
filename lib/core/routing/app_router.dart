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
import '../../models/certificate_model.dart';
import '../../features/certificates/presentation/screens/certificate_view_screen.dart';
import '../network/providers.dart';
import '../constants/app_colors.dart';
import '../widgets/gov_app_header.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final loc = state.uri.toString();
      final isAuth = authState.isAuthenticated;
      final user = authState.user;

      // Public verification, certificate view, and splash don't require login
      if (loc == '/' || loc.startsWith('/public') || loc.startsWith('/certificate')) {
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
        builder: (context, state) {
          final code = state.uri.queryParameters['code'];
          return PublicVerificationScreen(initialCode: code);
        },
      ),
      GoRoute(
        path: '/certificate',
        builder: (context, state) {
          final cert = state.extra as CertificateModel?;
          final currentUser = ref.watch(authControllerProvider).user;

          Widget buildGuardedCertificate(CertificateModel c) {
            // Role-based access control: If logged in as an OWNER, ensure the certificate belongs to them
            if (currentUser != null && currentUser.role == UserRole.owner) {
              final isOwnCert = c.ownerId == currentUser.id ||
                  c.ownerName.trim().toLowerCase() == currentUser.name.trim().toLowerCase();
              if (!isOwnCert) {
                return Scaffold(
                  appBar: const GovAppHeader(title: 'Access Restricted'),
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.gpp_bad, size: 64, color: AppColors.error),
                          const SizedBox(height: 16),
                          const Text(
                            'Access Denied',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'You do not have permission to view this certificate. It belongs to another establishment.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Back to Dashboard'),
                            onPressed: () => context.go('/dashboard/owner'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
            }
            return CertificateViewScreen(certificate: c);
          }

          if (cert != null) {
            return buildGuardedCertificate(cert);
          }

          final certId = state.uri.queryParameters['id']?.trim();
          final instId = state.uri.queryParameters['instrumentId']?.trim();

          Future<CertificateModel> resolveCertificate() async {
            final certRepo = ref.read(certificateRepositoryProvider);
            if (certId != null && certId.isNotEmpty) {
              return await certRepo.getCertificateById(certId);
            }
            if (instId != null && instId.isNotEmpty) {
              final certs = await certRepo.getCertificates();
              final match = certs.cast<CertificateModel?>().firstWhere(
                (c) => c?.instrumentId == instId || c?.instrumentUniqueId == instId,
                orElse: () => null,
              );
              if (match != null) return match;
            }
            if (currentUser != null && currentUser.role == UserRole.owner) {
              final ownerCerts = await certRepo.getCertificates(ownerId: currentUser.id);
              if (ownerCerts.isNotEmpty) {
                return ownerCerts.first;
              }
            }
            if (currentUser != null && currentUser.role == UserRole.admin) {
              final allCerts = await certRepo.getCertificates();
              if (allCerts.isNotEmpty) {
                return allCerts.first;
              }
            }
            throw Exception('No certificate records found.');
          }

          return FutureBuilder<CertificateModel>(
            future: resolveCertificate(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return buildGuardedCertificate(snapshot.data!);
              }
              if (snapshot.hasError) {
                final queryDisplay = certId ?? instId ?? (currentUser != null ? currentUser.name : 'Record');
                return Scaffold(
                  appBar: const GovAppHeader(title: 'Certificate Query'),
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off, size: 64, color: AppColors.warning),
                          const SizedBox(height: 16),
                          const Text(
                            'Certificate Not Found',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Certificate reference "$queryDisplay" could not be retrieved from records.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go(currentUser != null ? _dashboardPathForRole(currentUser.role) : '/login');
                              }
                            },
                            child: const Text('Return'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            },
          );
        },
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
