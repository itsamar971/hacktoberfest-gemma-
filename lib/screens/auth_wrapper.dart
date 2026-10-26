import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../providers/app_state.dart';
import 'auth_gateway_screen.dart';
import 'main_wrapper.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  String? _lastUserId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        final user = AuthService().currentUser;
        final isLoggedIn = user != null;

        if (isLoggedIn) {
          // Trigger sync if we just logged in or user changed
          if (_lastUserId != user.id) {
            _lastUserId = user.id;
            // Schedule sync after build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<AppState>().syncAllData();
            });
          }
          return const MainWrapper();
        } else {
          _lastUserId = null;
          return const AuthGatewayScreen();
        }
      },
    );
  }
}
