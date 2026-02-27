import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sproki/debug/api_smoke_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _loading = false;
  String? _error;

  bool _smokeRunning = false;

  Future<void> _signIn() async {
    if (_loading) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final messenger = ScaffoldMessenger.of(context);

    try {
      final email = _email.text.trim().toLowerCase();
      final password = _password.text;

      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final token = res.session?.accessToken;
      debugPrint('LOGIN OK | TOKEN_PARTS=${token?.split(".").length ?? 0}');
      _logTokenSafe(token);

      // Stop loading + navigate immediately.
      if (mounted) {
        setState(() => _loading = false);

        // Go to boot, router will push to /home when AppState finished.
        context.go('/boot');
      }

      // Smoke test must NEVER block navigation.
      _runSmokeTestInBackground(messenger);
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _runSmokeTestInBackground(ScaffoldMessengerState messenger) {
    if (!kDebugMode) return;
    if (_smokeRunning) return;

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return;

    _smokeRunning = true;

    // Fire-and-forget. Never awaited.
    unawaited(() async {
      try {
        final apiTest = ApiSmokeTest.create(
          accessTokenProvider: () async =>
              Supabase.instance.client.auth.currentSession?.accessToken,
        );

        if (!apiTest.shouldRun()) {
          debugPrint('API SMOKE TEST SKIP: API_BASE_URL not set');
          return;
        }

        await apiTest.run();

        if (mounted) {
          messenger.showSnackBar(
            const SnackBar(content: Text('API Smoke test OK ✅')),
          );
        }
      } catch (e) {
        debugPrint('API SMOKE TEST FAILED: $e');
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text('API Smoke test fejlede: $e')),
          );
        }
      } finally {
        _smokeRunning = false;
      }
    }());
  }

  void _logTokenSafe(String? token) {
    if (token == null || token.isEmpty) {
      debugPrint('ACCESS_TOKEN: (null)');
      return;
    }

    final startLen = token.length >= 20 ? 20 : token.length;
    final start = token.substring(0, startLen);
    final end = token.length > 12 ? token.substring(token.length - 12) : token;

    debugPrint('ACCESS_TOKEN: len=${token.length} start=$start… end=…$end');
  }

  Future<void> _sendMagicLink() async {
    if (_loading) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final messenger = ScaffoldMessenger.of(context);

    try {
      final email = _email.text.trim().toLowerCase();

      await Supabase.instance.client.auth.signInWithOtp(
        email: email,
      );

      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Magic link sendt. Tjek din email.')),
        );
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = _loading;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text('Login')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: const InputDecoration(labelText: 'Email'),
                        enabled: !disabled,
                        onSubmitted: (_) => disabled ? null : _signIn(),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _password,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        autocorrect: false,
                        enableSuggestions: false,
                        onSubmitted: (_) => disabled ? null : _signIn(),
                        decoration:
                            const InputDecoration(labelText: 'Password'),
                        enabled: !disabled,
                      ),
                      const SizedBox(height: 16),
                      if (_error != null) ...[
                        Text(_error!, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 12),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: disabled ? null : _signIn,
                              child: Text(_loading ? 'Logger ind…' : 'Login'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: disabled ? null : _sendMagicLink,
                        child: const Text('Send magic link'),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}