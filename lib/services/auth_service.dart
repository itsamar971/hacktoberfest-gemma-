import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Supabase URL and Anon / Publishable Key (can be passed via --dart-define or fallback)
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://evqctogzawhrpdziwjko.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_y3j4k2sdtKtcMn6ocaDM1Q_GnHd606C',
  );

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Initialize Supabase
  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );

      debugPrint('✅ Supabase initialized successfully');
    } catch (e) {
      debugPrint('❌ Supabase initialization failed: $e');
      // Don't rethrow here to avoid crashing app on startup if config is missing
    }
  }

  /// Get current user
  User? get currentUser => _supabase.auth.currentUser;

  /// Stream of auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: displayName != null ? {'display_name': displayName} : null,
      );
      
      return response;
    } catch (e) {
      debugPrint('❌ Sign up failed: $e');
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      return response;
    } catch (e) {
      debugPrint('❌ Sign in failed: $e');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint('❌ Sign out failed: $e');
      rethrow;
    }
  }

  /// Update user metadata (display name, avatar url)
  Future<UserResponse> updateUserMetadata({
    String? displayName,
    String? avatarUrl,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (displayName != null) updates['display_name'] = displayName;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl; // Assuming 'avatar_url' key

      final response = await _supabase.auth.updateUser(
        UserAttributes(data: updates),
      );
      
      debugPrint('✅ Metadata update request sent. Response user: ${response.user?.id}');
      debugPrint('   Sent updates: $updates');
      debugPrint('   Received metadata: ${response.user?.userMetadata}');
      
      // Force session refresh to ensure local user object is updated
      final session = await _supabase.auth.refreshSession();
      debugPrint('🔄 Session refreshed. Current user metadata: ${session.session?.user.userMetadata}');

      return response;
    } catch (e) {
      debugPrint('❌ Update user metadata failed: $e');
      rethrow;
    }
  }
}
