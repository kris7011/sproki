import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'api/api_client.dart';
import 'services/sproki_service.dart';
import 'state/app_state.dart';

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/leader_invites_screen.dart';
import 'screens/leader_invite_screen.dart';
import 'screens/children/child_detail_screen.dart';

class SprokiApp extends StatefulWidget {
  const SprokiApp({
    super.key,
    required this.apiBaseUrl,
    required this.apiBasePath,
  });

  final String apiBaseUrl;
  final String apiBasePath;

  @override
  State<SprokiApp> createState() => _SprokiAppState();
}

class _SprokiAppState extends State<SprokiApp> {
  late final SprokiService _service;
  late final AppState _appState;

  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    final api = ApiClient(
      baseUrl: widget.apiBaseUrl,
      basePath: widget.apiBasePath,
    );

    _service = SprokiService(api);
    _appState = AppState(service: _service);

    _router = GoRouter(
      initialLocation: '/boot',

      // IMPORTANT:
      // Only refresh when AppState changes.
      // AppState already reacts to sign-in/out, but ignores token refresh to avoid /me spam.
      refreshListenable: _appState,

      redirect: (context, state) {
        final session = Supabase.instance.client.auth.currentSession;

        final loc = state.matchedLocation;
        final isBoot = loc == '/boot';
        final isLogin = loc == '/login';

        if (_appState.loading) {
          return isBoot ? null : '/boot';
        }

        if (session == null) {
          return isLogin ? null : '/login';
        }

        if (isBoot || isLogin) {
          return '/home';
        }

        final isLeaderRoute = loc.startsWith('/leader');
        if (isLeaderRoute && _appState.role != 'LEDER') return '/home';

        return null;
      },

      routes: [
        GoRoute(
          path: '/boot',
          builder: (context, state) => const _BootScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => HomeScreen(
            service: _service,
            appState: _appState,
          ),
        ),
        GoRoute(
          path: '/children/:id',
          builder: (context, state) {
            final idStr = state.pathParameters['id'] ?? '';
            final childId = int.tryParse(idStr) ?? 0;

            return ChildDetailScreen(
              service: _service,
              childId: childId,
            );
          },
        ),
        GoRoute(
          path: '/leader/invites',
          builder: (context, state) => LeaderInvitesScreen(
            service: _service,
            appState: _appState,
          ),
        ),
        GoRoute(
          path: '/leader/invite',
          builder: (context, state) => LeaderInviteScreen(
            service: _service,
            appState: _appState,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Sproki',
      routerConfig: _router,
    );
  }
}

class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}