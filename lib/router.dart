import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';


import 'services/supabase_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/assets_screen.dart';
import 'screens/maintenance_screen.dart';
import 'screens/add_maintenance_screen.dart';
import 'screens/add_asset_screen.dart';
import 'screens/edit_asset_screen.dart';
import 'screens/asset_details_screen.dart';
import 'screens/create_request_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/qr_scanner_screen.dart';
import 'screens/locations_screen.dart';
import 'screens/licenses_screen.dart';
import 'screens/audit_history_screen.dart';
import 'screens/map_view_screen.dart';
import 'screens/requests_screen.dart';
import 'screens/my_custody_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/handover_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/manage_companies_screen.dart';
import 'screens/manage_users_screen.dart';
import 'screens/create_user_screen.dart';
import 'screens/create_company_screen.dart';
import 'screens/audit_screen.dart';
import 'models/asset_model.dart';
import 'models/maintenance_model.dart';
import 'models/location_model.dart';
import 'screens/location_details_screen.dart';

// GoRouter configuration
final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const _SplashHandler(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/assets',
      builder: (context, state) => const AssetsScreen(),
      routes: [
        GoRoute(
          path: 'add',
          builder: (context, state) => const AddAssetScreen(),
        ),
        GoRoute(
          path: 'edit',
          builder: (context, state) {
            final asset = state.extra as AssetModel;
            return EditAssetScreen(asset: asset);
          },
        ),
        GoRoute(
          path: 'details',
          builder: (context, state) {
            final asset = state.extra as AssetModel;
            return AssetDetailsScreen(asset: asset);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/maintenance',
      builder: (context, state) => const MaintenanceScreen(),
      routes: [
        GoRoute(
          path: 'add',
          builder: (context, state) {
            final logForSchedule = state.extra as MaintenanceSchedule?;
            return AddMaintenanceScreen(logForSchedule: logForSchedule);
          },
        ),
      ],
    ),

    GoRoute(
      path: '/requests/create',
      builder: (context, state) => const CreateRequestScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/qr_scanner',
      builder: (context, state) => const QrScannerScreen(),
    ),
    GoRoute(
      path: '/locations',
      builder: (context, state) => const LocationsScreen(),
      routes: [
        GoRoute(
          path: 'details',
          builder: (context, state) {
            final location = state.extra as LocationModel;
            return LocationDetailsScreen(location: location);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/licenses',
      builder: (context, state) => const LicensesScreen(),
    ),
    GoRoute(
      path: '/audit',
      builder: (context, state) => const AuditHistoryScreen(),
    ),
    GoRoute(
      path: '/map',
      builder: (context, state) => const MapViewScreen(),
    ),
    GoRoute(
      path: '/requests',
      builder: (context, state) => const RequestsScreen(),
    ),
    GoRoute(
      path: '/my_custody',
      builder: (context, state) => const MyCustodyScreen(),
    ),
    GoRoute(
      path: '/analytics',
      builder: (context, state) => const AnalyticsScreen(),
    ),
    GoRoute(
      path: '/handover',
      builder: (context, state) => const HandoverScreen(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminDashboardScreen(),
      routes: [
        GoRoute(
          path: 'companies',
          builder: (context, state) => const ManageCompaniesScreen(),
          routes: [
            GoRoute(
              path: 'create',
              builder: (context, state) => const CreateCompanyScreen(),
            ),
          ],
        ),
        GoRoute(
          path: 'users',
          builder: (context, state) => const ManageUsersScreen(),
          routes: [
            GoRoute(
              path: 'create',
              builder: (context, state) => const CreateUserScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/audit/new',
      builder: (context, state) => const AuditScreen(),
    ),
  ],
  redirect: (context, state) {
    final session = SupabaseService.client.auth.currentSession;
    final loggingIn = state.uri.toString() == '/login';
    final splash = state.uri.toString() == '/';

    // If no session, redirect to login (unless already there)
    if (session == null) {
      return loggingIn ? null : '/login';
    }

    // If session exists and we are on login or splash, go to dashboard
    if (loggingIn || splash) {
      return '/dashboard';
    }

    // No redirect needed
    return null;
    return null;
  },
  refreshListenable: GoRouterRefreshStream(
    SupabaseService.client.auth.onAuthStateChange,
  ),
);

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<AuthState> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class _SplashHandler extends StatefulWidget {
  const _SplashHandler();

  @override
  State<_SplashHandler> createState() => _SplashHandlerState();
}

class _SplashHandlerState extends State<_SplashHandler> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // Small delay for splash effect if desired
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      final session = SupabaseService.client.auth.currentSession;
      if (session != null) {
        context.go('/dashboard');
      } else {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
