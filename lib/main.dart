import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/app_state.dart';
import 'services/achievement_service.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';
import 'services/gemini_service.dart';
import 'screens/auth_wrapper.dart';
import 'widgets/snow_overlay.dart';
import 'widgets/audio_floating_player.dart';

final GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize AuthService (Supabase)
  await AuthService.initialize();
  
  // Initialize Gemini AI (Gemma)
  GeminiService().initialize();
  
  // Initialize StorageService (SharedPrefs Cache)
  await StorageService.init();
  
  // Initialize Achievement Service
  try {
    await AchievementService().initialize();
  } catch (e) {
    debugPrint('Failed to initialize AchievementService: $e');
  }
  
  runApp(const BloomApp());
}

class BloomApp extends StatelessWidget {
  const BloomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => AchievementService()),
      ],
      child: Consumer<AppState>(
        builder: (context, appState, child) {
          return MaterialApp(
            title: 'Bloom',
            navigatorKey: globalNavigatorKey,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.getLightTheme(appState.themeColor),
            darkTheme: AppTheme.getDarkTheme(appState.themeColor),
            themeMode: appState.themeMode,
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(appState.textScaleFactor),
                ),
                child: SnowOverlay(
                  child: Stack(
                    children: [
                      child!,
                      const AudioFloatingPlayer(),
                    ],
                  ),
                ),
              );
            },
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}
