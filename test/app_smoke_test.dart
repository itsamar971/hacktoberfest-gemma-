import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bloom/services/gemini_service.dart';
import 'package:bloom/services/auth_service.dart';
import 'package:bloom/models/dream.dart';
import 'package:bloom/models/challenge_step.dart';
import 'package:bloom/models/journal_entry.dart';
import 'package:bloom/models/travel_memory.dart';
import 'package:bloom/providers/app_state.dart';

import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/shared_preferences'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getAll') {
          return <String, dynamic>{};
        }
        return true;
      },
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (MethodCall methodCall) async => 1,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('home_widget'),
      (MethodCall methodCall) async => true,
    );
    await AuthService.initialize();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Bloom End-to-End Integrity Verification', () {
    test('AuthService is wired to new Supabase credentials', () {
      expect(AuthService.supabaseUrl, 'https://evqctogzawhrpdziwjko.supabase.co');
      expect(AuthService.supabaseAnonKey, 'sb_publishable_y3j4k2sdtKtcMn6ocaDM1Q_GnHd606C');
    });

    test('GeminiService uses gemma-4-26b-a4b-it and supports initialization', () {
      expect(GeminiService.defaultModel, 'gemma-4-26b-a4b-it');
      GeminiService().initialize(key: 'test_key');
      expect(GeminiService.apiKey, 'test_key');
    });

    test('AppState initializes with Lifetime Pro permanently unlocked', () {
      final state = AppState();
      expect(state.isPro, isTrue);
    });

    test('Dream & ChallengeStep serialization and state flow', () {
      final step = ChallengeStep(
        id: 'step_1',
        title: 'Step 1: Set clear intention',
        durationMinutes: 15,
        isCompleted: false,
      );

      final dream = Dream(
        id: 'dream_1',
        title: 'Launch my dream business',
        description: 'Building my startup from scratch',
        themeColor: 0xFFFF7F50,
        themeIcon: 57545,
        steps: [step],
        startDate: DateTime.now(),
      );

      final map = dream.toMap();
      final revived = Dream.fromMap(map);
      expect(revived.id, 'dream_1');
      expect(revived.title, 'Launch my dream business');
      expect(revived.steps.length, 1);
      expect(revived.steps.first.title, 'Step 1: Set clear intention');
      expect(revived.steps.first.durationMinutes, 15);
    });

    test('JournalEntry serialization with AI reflections and tags', () {
      final entry = JournalEntry(
        id: 'entry_1',
        title: 'Excited for Bloom Launch',
        content: 'Everything is tested and wired up.',
        type: JournalEntryType.note,
        color: 0xFFFF7F50,
        aiInsight: 'A journey of growth begins with consistency.',
        tags: ['growth', 'tech'],
        createdAt: DateTime.now(),
      );

      final map = entry.toMap();
      final revived = JournalEntry.fromMap(map);
      expect(revived.id, 'entry_1');
      expect(revived.tags, contains('growth'));
      expect(revived.aiInsight, contains('consistency'));
    });

    test('TravelMemory coordinates and photo serialization', () {
      final memory = TravelMemory(
        id: 'mem_1',
        userId: 'test_uuid',
        place: 'Tokyo, Japan',
        latitude: 35.6762,
        longitude: 139.6503,
        visitedDate: DateTime.now(),
        memory: 'Shibuya Crossing',
        photos: ['https://evqctogzawhrpdziwjko.supabase.co/storage/v1/object/public/travel-photos/tokyo.jpg'],
        isPublic: true,
      );

      final map = memory.toMap();
      final revived = TravelMemory.fromMap(map);
      expect(revived.place, 'Tokyo, Japan');
      expect(revived.latitude, closeTo(35.6762, 0.001));
      expect(revived.photos.length, 1);
      expect(revived.isPublic, isTrue);
    });
  });
}
