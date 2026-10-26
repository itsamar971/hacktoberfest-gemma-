import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../models/dream.dart';
import '../models/challenge_step.dart';
import '../models/travel_memory.dart';
import '../models/journal_entry.dart';
// import '../models/journal_group.dart';
import '../services/storage_service.dart';
import '../services/achievement_service.dart';
import '../utils/widget_to_image_converter.dart';
import '../widgets/world_map_svg.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/blog_post.dart';
import '../services/blog_audio_handler.dart';

@pragma('vm:entry-point')
class AppState extends ChangeNotifier {
  final StorageService _storage = StorageService();
  
  // TTS / Audio Podcast State
  final FlutterTts _flutterTts = FlutterTts();
  BlogAudioHandler? _audioHandler;
  bool _isAudioHandlerReady = false;
  List<BlogPost> _allBlogs = [];
  BlogPost? _currentAudioBlog;
  bool _isAudioPlaying = false;
  double _audioProgress = 0.0;
  int _audioLastOffset = 0;
  String _audioFullText = "";
  static const int _charsPerSecond = 10;
  
  BlogPost? get currentAudioBlog => _currentAudioBlog;
  bool get isAudioPlaying => _isAudioPlaying;
  double get audioProgress => _audioProgress;
  int get audioLastOffset => _audioLastOffset;
  String get audioFullText => _audioFullText;
  int get audioTotalSeconds => _audioFullText.length ~/ _charsPerSecond;
  int get audioElapsedSeconds => (_audioProgress * audioTotalSeconds).toInt();

  List<Dream> _dreams = [];
  List<TravelMemory> _travelMemories = [];
  List<TravelMemory> _publicMemories = [];
  List<JournalEntry> _journalEntries = [];
  // List<JournalGroup> _journalGroups = [];
  List<String> _pinnedCardIds = [];
  List<String> _pinnedDreamIds = [];
  List<String> _pinnedJournalToHomeIds = []; // Pin checklists to Home screen
  String? _widgetJournalEntryId; // The journal entry currently on the App Widget
  bool _widgetTravelMapActive = false; // Whether travel map is on the App Widget
  bool _isLoading = true;
  bool _isPro = true; // All features permanently unlocked
  
  // Garden (formerly Bloom Garden)
  List<int> _gardenCells = List.filled(25, 0); // 5x5 grid
  double _waterRate = 0.0;
  int _lastMissedDays = 0; // Days missed since last activity
  int _negotiationsCompleted = 0;
  int _totalTodoCompletions = 0;
  Set<String> _distinctGamesPlayed = {};
  int _totalCheckIns = 0;
  String? _instagramUsername;
  
  List<Dream> get dreams => _dreams;
  List<TravelMemory> get travelMemories => _travelMemories;
  List<TravelMemory> get publicMemories => _publicMemories;
  List<JournalEntry> get journalEntries => _journalEntries;
  // List<JournalGroup> get journalGroups => _journalGroups;
  List<String> get pinnedCardIds => _pinnedCardIds;
  List<String> get pinnedDreamIds => _pinnedDreamIds;
  List<String> get pinnedJournalToHomeIds => _pinnedJournalToHomeIds;
  String? get widgetJournalEntryId => _widgetJournalEntryId;
  bool get widgetTravelMapActive => _widgetTravelMapActive;
  bool get isLoading => _isLoading;
  bool get isPro => _isPro;
  List<int> get gardenCells => _gardenCells;
  double get waterRate => _waterRate;
  int get lastMissedDays => _lastMissedDays;
  int get negotiationsCompleted => _negotiationsCompleted;
  String? get instagramUsername => _instagramUsername;
  int get activityPoints => (AchievementService().totalUnlocked * 100) + (_travelMemories.length * 50) + (_currentStreak * 10); // Updated formula to match storage service

  // Settings
  ThemeMode _themeMode = ThemeMode.light;
  Color _themeColor = const Color(0xFFFF7F50); // Coral Orange default
  double _textScaleFactor = 1.0;
  bool _isWinterMode = false;
  bool _showMotivation = true;
  bool _showGarden = true;
  bool _showAchievements = true;
  bool _showMap = true;

  ThemeMode get themeMode => _themeMode;
  Color get themeColor => _themeColor;
  double get textScaleFactor => _textScaleFactor;
  bool get isWinnerMode => _isWinterMode; // Keep existing naming if any, but adding new ones
  bool get isWinterMode => _isWinterMode;
  bool get showMotivation => _showMotivation;
  bool get showGarden => _showGarden;
  bool get showAchievements => _showAchievements;
  bool get showMap => _showMap;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _saveSettings();
    notifyListeners();
  }
  
  void setThemeColor(Color color) {
    _themeColor = color;
    _saveSettings();
    notifyListeners();
  }

  void setTextScaleFactor(double scale) {
    _textScaleFactor = scale.clamp(0.8, 1.3);
    _saveSettings();
    notifyListeners();
  }

  void setWinterMode(bool value) {
    _isWinterMode = value;
    _saveSettings();
    notifyListeners();
  }

  void setShowMotivation(bool value) {
    _showMotivation = value;
    _saveSettings();
    notifyListeners();
  }

  void setShowGarden(bool value) {
    _showGarden = value;
    _saveSettings();
    notifyListeners();
  }

  void setShowAchievements(bool value) {
    _showAchievements = value;
    _saveSettings();
    notifyListeners();
  }

  void setShowMap(bool value) {
    _showMap = value;
    _saveSettings();
    notifyListeners();
  }

  void setInstagramUsername(String? value) {
    _instagramUsername = value;
    _saveSettings();
    notifyListeners();
  }
  
  Future<void> _saveSettings() async {
    await _storage.saveSettings(
      themeModeIndex: _themeMode.index,
      themeColorValue: _themeColor.value,
      textScale: _textScaleFactor,
      isWinterMode: _isWinterMode,
      showMotivation: _showMotivation,
      showGarden: _showGarden,
      showAchievements: _showAchievements,
      showMap: _showMap,
      instagram: _instagramUsername,
    );
  }

  AppState() {
    _loadSettings();
    _loadData();
    _initAudioService();
    _initTts();
    HomeWidget.registerBackgroundCallback(backgroundCallback);
  }

  Future<void> _initAudioService() async {
    try {
      // Request notification permission for Android 13+
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }

      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.speech());
      
      _audioHandler = await AudioService.init(
        builder: () => BlogAudioHandler(
          onPlay: () {
            if (_currentAudioBlog != null) playBlog(_currentAudioBlog!);
          },
          onPause: () => pauseBlog(),
          onStop: () => stopBlog(),
          onSkipNext: () => skipNextBlog(),
          onSkipPrevious: () => skipPreviousBlog(),
          onSeek: (position) {
            if (audioTotalSeconds > 0) {
              seekAudio((position.inSeconds / audioTotalSeconds).clamp(0.0, 1.0));
            }
          },
        ),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.shipyardapps.bloom.channel.audio',
          androidNotificationChannelName: 'Bloom Narration',
          androidNotificationOngoing: false,
          androidStopForegroundOnPause: false,
          androidNotificationIcon: 'mipmap/launcher_icon',
        ),
      );
      _isAudioHandlerReady = true;
      if (_currentAudioBlog != null) {
        _audioHandler?.updateMetadata(_currentAudioBlog!);
        _audioHandler?.updatePlaybackState(
          playing: _isAudioPlaying,
          position: Duration(seconds: audioElapsedSeconds),
        );
      }
    } catch (e) {
      debugPrint('Error initializing audio service: $e');
    }
  }
  
  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);

    _flutterTts.setStartHandler(() {
      _isAudioPlaying = true;
      if (_isAudioHandlerReady) {
        _audioHandler?.updatePlaybackState(
          playing: true,
          position: Duration(seconds: audioElapsedSeconds),
        );
      }
      notifyListeners();
    });

    _flutterTts.setCompletionHandler(() {
      _isAudioPlaying = false;
      _audioProgress = 1.0;
      _audioLastOffset = 0;
      if (_isAudioHandlerReady) {
        _audioHandler?.updatePlaybackState(
          playing: false,
          position: Duration(seconds: audioTotalSeconds),
        );
      }
      notifyListeners();
    });

    _flutterTts.setProgressHandler((text, start, end, word) {
      if (_audioFullText.isNotEmpty) {
        _audioProgress = (_audioLastOffset + start) / _audioFullText.length;
        if (_isAudioHandlerReady) {
          _audioHandler?.updatePlaybackState(
            playing: _isAudioPlaying,
            position: Duration(seconds: audioElapsedSeconds),
          );
        }
        notifyListeners();
      }
    });

    _flutterTts.setErrorHandler((msg) {
      _isAudioPlaying = false;
      if (_isAudioHandlerReady) {
        _audioHandler?.updatePlaybackState(
          playing: false,
          position: Duration(seconds: audioElapsedSeconds),
        );
      }
      notifyListeners();
    });
  }

  String _cleanMarkdownForTts(String text) {
    // Remove headers (#, ##, etc.)
    var cleaned = text.replaceAll(RegExp(r'#+\s*'), '');
    // Remove bold/italic (**, *, __, _)
    cleaned = cleaned.replaceAll(RegExp(r'\*\*|__|\*|_'), '');
    // Remove links ([text](url)) - keep only text
    cleaned = cleaned.replaceAllMapped(RegExp(r'\[(.*?)\]\(.*?\)') , (match) => match.group(1) ?? '');
    // Remove images (![alt](url))
    cleaned = cleaned.replaceAll(RegExp(r'!\[.*?\]\(.*?\)') , '');
    // Remove extra whitespace
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    return cleaned.trim();
  }

  Future<void> playBlog(BlogPost blog, {List<BlogPost>? allBlogs}) async {
    if (allBlogs != null) {
      _allBlogs = allBlogs;
    }
    
    if (_currentAudioBlog?.id != blog.id) {
      await stopBlog();
      _currentAudioBlog = blog;
      _audioFullText = _cleanMarkdownForTts("${blog.title}. ${blog.excerpt}. ${blog.content}");
      _audioProgress = 0.0;
      _audioLastOffset = 0;
      if (_isAudioHandlerReady) {
        _audioHandler?.updateMetadata(blog);
      }
    }

    if (_audioProgress >= 0.99) {
      _audioLastOffset = 0;
      _audioProgress = 0.0;
    } else {
      _audioLastOffset = (_audioProgress * _audioFullText.length).toInt();
    }

    final textToSpeak = _audioFullText.substring(_audioLastOffset);
    if (textToSpeak.isNotEmpty) {
      _isAudioPlaying = true;
      if (_isAudioHandlerReady) {
        _audioHandler?.updatePlaybackState(
          playing: true,
          position: Duration(seconds: audioElapsedSeconds),
        );
      }
      notifyListeners();
      await _flutterTts.speak(textToSpeak);
    }
  }

  Future<void> skipNextBlog() async {
    if (_allBlogs.isEmpty || _currentAudioBlog == null) return;
    
    final currentIndex = _allBlogs.indexWhere((b) => b.id == _currentAudioBlog!.id);
    final nextIndex = (currentIndex + 1) % _allBlogs.length;
    final nextBlog = _allBlogs[nextIndex];
    
    await stopBlog();
    await playBlog(nextBlog);
  }

  Future<void> skipPreviousBlog() async {
    if (_allBlogs.isEmpty || _currentAudioBlog == null) return;
    
    final currentIndex = _allBlogs.indexWhere((b) => b.id == _currentAudioBlog!.id);
    final prevIndex = (currentIndex - 1 + _allBlogs.length) % _allBlogs.length;
    final prevBlog = _allBlogs[prevIndex];
    
    await stopBlog();
    await playBlog(prevBlog);
  }

  Future<void> pauseBlog() async {
    await _flutterTts.pause();
    _isAudioPlaying = false;
    if (_isAudioHandlerReady) {
      _audioHandler?.updatePlaybackState(
        playing: false,
        position: Duration(seconds: audioElapsedSeconds),
      );
    }
    notifyListeners();
  }

  Future<void> stopBlog() async {
    await _flutterTts.stop();
    _isAudioPlaying = false;
    _currentAudioBlog = null;
    _audioProgress = 0.0;
    _audioLastOffset = 0;
    _audioFullText = "";
    if (_isAudioHandlerReady) {
      _audioHandler?.updatePlaybackState(
        playing: false,
        position: Duration.zero,
      );
    }
    notifyListeners();
  }

  Future<void> seekAudio(double value) async {
    if (_currentAudioBlog == null) return;
    
    final wasPlaying = _isAudioPlaying;
    await _flutterTts.stop();
    
    _audioProgress = value;
    _audioLastOffset = (value * _audioFullText.length).toInt();
    notifyListeners();

    if (wasPlaying) {
      final textToSpeak = _audioFullText.substring(_audioLastOffset);
      if (textToSpeak.isNotEmpty) {
        await _flutterTts.speak(textToSpeak);
      }
    }
  }

  Future<void> _loadSettings() async {
    final settings = await _storage.loadSettings();
    _applySettings(settings);
    notifyListeners();
  }
  @pragma('vm:entry-point')
  static Future<void> backgroundCallback(Uri? uri) async {
    debugPrint('--- Background Callback Triggered: $uri ---');
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    
    if (uri?.host == 'toggle') {
      final String? entryId = uri?.queryParameters['id'];
      final String? taskId = uri?.queryParameters['task'];
      debugPrint('Background Toggle Request: entryId=$entryId, taskId=$taskId');
      
      if (entryId != null && taskId != null) {
        final String? localData = prefs.getString('bloom_journal_entries');
        if (localData != null) {
          try {
            final List<dynamic> jsonList = jsonDecode(localData);
            bool found = false;
            
            for (var entryMap in jsonList) {
              if (entryMap['id'] == entryId) {
                final todos = entryMap['todos'] as List<dynamic>?;
                if (todos != null) {
                  for (var todo in todos) {
                    if (todo['id'] == taskId) {
                      todo['isCompleted'] = !(todo['isCompleted'] ?? false);
                      found = true;
                      debugPrint('Toggled Task: ${todo['id']} to ${todo['isCompleted']}');
                      break;
                    }
                  }
                }
                break;
              }
            }
            
            if (found) {
              await prefs.setString('bloom_journal_entries', jsonEncode(jsonList));
              debugPrint('Saved toggled entries back to storage');
              
              // Trigger a refresh after toggle to update widget
              await _syncWidgetDataInIsolate(prefs, entryId);
            }
          } catch (e) {
            debugPrint('Background Toggle Error: $e');
          }
        }
      }
    } else if (uri?.host == 'refresh') {
      debugPrint('Background Refresh Request');
      final String? entryId = prefs.getString('bloom_widget_journal_entry_id');
      await _syncWidgetDataInIsolate(prefs, entryId);
    } else if (uri?.host == 'refresh_travel') {
      debugPrint('Background Travel Widget Refresh Request');
      await _syncTravelWidgetDataInIsolate(prefs);
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _syncWidgetDataInIsolate(SharedPreferences prefs, String? entryId) async {
    debugPrint('Syncing Widget Data in Background: entryId=$entryId');
    
    if (entryId == null) {
      await HomeWidget.saveWidgetData<String>('todo_title', "Todo List");
      await HomeWidget.saveWidgetData<int>('todo_count', 0);
    } else {
      final String? localData = prefs.getString('bloom_journal_entries');
      if (localData != null) {
        try {
          final List<dynamic> jsonList = jsonDecode(localData);
          final entry = jsonList.firstWhere((e) => e['id'] == entryId, orElse: () => null);
          
          if (entry != null) {
            await HomeWidget.saveWidgetData<String>('todo_title', entry['title'] ?? "");
            await HomeWidget.saveWidgetData<String>('todo_entry_id', entryId);
            
            final String type = (entry['type'] ?? '').toString();
            if (type.contains('todo')) {
              final List<dynamic> todos = entry['todos'] as List<dynamic>? ?? [];
              await HomeWidget.saveWidgetData<int>('todo_count', todos.length);
              for (int i = 0; i < todos.length && i < 5; i++) {
                await HomeWidget.saveWidgetData<String>('todo_${i+1}_text', todos[i]['text'] ?? "");
                await HomeWidget.saveWidgetData<bool>('todo_${i+1}_checked', todos[i]['isCompleted'] ?? false);
                await HomeWidget.saveWidgetData<String>('todo_${i+1}_id', todos[i]['id'] ?? "");
              }
            } else {
              await HomeWidget.saveWidgetData<int>('todo_count', 1);
              await HomeWidget.saveWidgetData<String>('todo_1_text', entry['content'] ?? "");
              await HomeWidget.saveWidgetData<bool>('todo_1_checked', false);
              await HomeWidget.saveWidgetData<String>('todo_1_id', entryId);
            }
            debugPrint('Successfully re-saved data for widget');
          }
        } catch (e) {
          debugPrint('Error syncing widget data in background: $e');
        }
      }
    }
    
    await HomeWidget.updateWidget(name: 'TodoWidget', androidName: 'TodoWidget');
    debugPrint('Triggered Widget Update from Background');
  }

  @pragma('vm:entry-point')
  static Future<void> _syncTravelWidgetDataInIsolate(SharedPreferences prefs) async {
    debugPrint('Travel Widget Refresh Request from Background');
    
    // Cannot generate map image in background isolate (no UI context)
    // Set flag for foreground app to regenerate on next resume
    await HomeWidget.saveWidgetData<bool>('travel_needs_refresh', true);
    
    await HomeWidget.updateWidget(name: 'TravelWidget', androidName: 'TravelWidget');
    debugPrint('Flagged travel widget for foreground refresh');
  }

  // Check if travel widget needs refresh (called when app resumes)
  Future<void> checkAndRefreshTravelWidget() async {
    final needsRefresh = await HomeWidget.getWidgetData<bool>('travel_needs_refresh');
    if (needsRefresh == true && _widgetTravelMapActive) {
      debugPrint('Refreshing travel widget in foreground');
      final imagePath = await _generateMapImage();
      if (imagePath != null) {
        await HomeWidget.saveWidgetData<String>('travel_map_path', imagePath);
      }
      await _updateTravelWidget();
      await HomeWidget.saveWidgetData<bool>('travel_needs_refresh', false);
    }
  }

  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // PHASE 1: Parallel Local Reads
      final results = await Future.wait([
        _storage.loadSettings(),
        _storage.loadDreams(),
        _storage.loadTravelMemories(),
        _storage.loadJournalEntries(),
        _storage.loadPinnedCards(),
        _storage.loadGarden(),
        _storage.loadNegotiationsCompleted(),
        _storage.loadTodoCompletions(),
        _storage.loadDistinctGames(),
        _storage.loadTotalCheckIns(),
        _storage.loadStreakData(),
        _storage.hasSeedData(),
        _storage.loadPinnedJournalHome(),
        _storage.loadWidgetJournalEntryId(),
        _storage.loadWidgetTravelMapActive(),
      ]);

      // Assign results
      final settings = results[0] as Map<String, dynamic>;
      _dreams = results[1] as List<Dream>;
      _travelMemories = results[2] as List<TravelMemory>;
      _journalEntries = results[3] as List<JournalEntry>;
      _pinnedCardIds = results[4] as List<String>;
      _gardenCells = results[5] as List<int>;
      _negotiationsCompleted = results[6] as int;
      _totalTodoCompletions = results[7] as int;
      _distinctGamesPlayed = (results[8] as List<String>).toSet();
      _totalCheckIns = results[9] as int;
      final streakData = results[10] as Map<String, dynamic>;
      _currentStreak = streakData['streak'] ?? 0;
      _pinnedJournalToHomeIds = results[12] as List<String>;
      _widgetJournalEntryId = results[13] as String?;
      _widgetTravelMapActive = results[14] as bool;
      
      // Robust duplicate ID check
      bool hasDuplicateIds = false;
      for (var entry in _journalEntries) {
        if (entry.type == JournalEntryType.todo) {
          final ids = entry.todos.map((t) => t.id).toList();
          if (ids.length != ids.toSet().length && ids.isNotEmpty) {
            hasDuplicateIds = true;
            break;
          }
        }
      }

      if (_journalEntries.isEmpty || hasDuplicateIds) {
        debugPrint('Refreshing journal entries: isEmpty=${_journalEntries.isEmpty}, hasDuplicateIds=$hasDuplicateIds');
        await _addSampleData();
      }

      // Apply settings immediately
      _applySettings(settings);
      _updateWaterRate();

      // PHASE 2: Local activity tracking
      await trackActivity();

      // READY: Show UI with local data
      _isLoading = false;
      notifyListeners();
      
      // Check if widget needs refresh after loading
      checkAndRefreshTravelWidget();
      
      // PHASE 3: Background Cloud Sync
      _syncWithCloudInBackground();

    } catch (e) {
      debugPrint('Error in _loadData: $e');
      _isLoading = false;
      notifyListeners();
      
      // Still check for widget refresh even on error
      checkAndRefreshTravelWidget();
    }
  }

  void _applySettings(Map<String, dynamic> settings) {
    final themeIndex = settings['themeMode'];
    if (themeIndex == ThemeMode.system.index) {
       _themeMode = ThemeMode.light;
    } else {
       _themeMode = ThemeMode.values[themeIndex];
    }
    final themeColorVal = settings['themeColor'];
    if (themeColorVal != null) {
      _themeColor = Color(themeColorVal);
    }
    _textScaleFactor = (settings['textScale'] as num?)?.toDouble().clamp(0.8, 1.3) ?? 1.0;
    _isWinterMode = settings['isWinterMode'] ?? false;
    _showMotivation = settings['showMotivation'] ?? true;
    _showGarden = settings['showGarden'] ?? true;
    _showAchievements = settings['showAchievements'] ?? true;
    _showMap = settings['showMap'] ?? true;
    _instagramUsername = settings['instagram'];
  }

  Future<void> _syncWithCloudInBackground() async {
    // 1. Fetch profile ONCE
    final cloudProfile = await _storage.fetchFullProfile();
    
    if (cloudProfile != null) {
      // 2. Update stats and settings from the same profile object
      final streakData = await _storage.loadStreakData(cloudProfile: cloudProfile);
      _currentStreak = streakData['streak'] ?? 0;

      _currentStreak = streakData['streak'] ?? 0;

      _gardenCells = await _storage.loadGarden(cloudProfile: cloudProfile);
      
      // Update memories from cloud in background
      _travelMemories = await _storage.loadTravelMemories(syncCloud: true);
      
      final settings = await _storage.loadSettings(cloudProfile: cloudProfile);
      _applySettings(settings);
      
      _updateWaterRate();
      notifyListeners();
    }

    // 3. Other network tasks
    fetchPublicMemories();
    updateProStatus();
    _checkAchievements();
  }

  void _updateWaterRate() {
    // Water rate based on streak (e.g., 7 days = 1.0)
    _waterRate = (_currentStreak / 7.0).clamp(0.0, 1.0);
  }

  Future<void> _updateGardenGrowth(bool isActiveToday, int dayDifference) async {
    if (dayDifference == 0 && isActiveToday) {
       // Just active today, maybe give a small growth boost if not already done today
       // (Real implementation would track "wateredToday" flag)
       _growRandomPlant();
    } else if (dayDifference > 1) {
       // Missed days! Wither some plants
       _witherPlants(dayDifference - 1);
    } else if (dayDifference == 1 && isActiveToday) {
       // Consecutive day! Grow plants
       _growRandomPlant();
    }
    
    await _storage.saveGarden(_gardenCells);
    notifyListeners();
  }

  void _growRandomPlant() {
    // Find cells that can grow (shuffled for randomness)
    final indices = List.generate(25, (i) => i)..shuffle();
    for (final i in indices) {
      if (_gardenCells[i] < 4) { // Max growth is 4 (Bloom)
        _gardenCells[i]++;
        break;
      }
    }
  }

  void _witherPlants(int missedDays) {
    // Wither plants based on missed days
    final indices = List.generate(25, (i) => i)..shuffle();
    int witheredCount = 0;
    for (final i in indices) {
      if (_gardenCells[i] > 0) {
        _gardenCells[i]--; // Back to previous stage or sand
        witheredCount++;
        if (witheredCount >= missedDays) break;
      }
    }
  }
  
  // Activity Streak
  int _currentStreak = 0;
  int get currentStreak => _currentStreak;

  int get totalPoints => activityPoints;
  int get currentLevel => 1 + (activityPoints / 200).floor();
  
  // Helper for UI
  int get pointsToNextLevel => currentLevel * 200;
  
  String get levelName {
    if (currentLevel >= 20) return "Bloom Legend";
    if (currentLevel >= 15) return "Master Botanist";
    if (currentLevel >= 10) return "Star Gardener";
    if (currentLevel >= 7) return "Green Thumb";
    if (currentLevel >= 4) return "Nature Guard";
    if (currentLevel >= 2) return "Sprout Guide";
    return "Seed Sower";
  }

  Future<List<Achievement>> trackActivity() async {
    // Load points data first - REMOVED

    final streakData = await _storage.loadStreakData();
    int loadedStreak = streakData['streak'] as int;
    String? lastActiveStr = streakData['lastActiveDate'] as String?;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (lastActiveStr == null) {
      // First time
      _currentStreak = 1;
      _totalCheckIns = 1;
      _lastMissedDays = 0;
      await _storage.saveTotalCheckIns(_totalCheckIns);
      await _storage.saveStreak(1, today.toIso8601String());
      await _updateGardenGrowth(true, 0);
    } else {
      final lastActiveDate = DateTime.parse(lastActiveStr);
      final lastActiveDay = DateTime(lastActiveDate.year, lastActiveDate.month, lastActiveDate.day);
      
      final difference = today.difference(lastActiveDay).inDays;
      
      if (difference == 0) {
        // Already active today, maintain streak
        _currentStreak = loadedStreak;
        _lastMissedDays = 0;
        await _updateGardenGrowth(true, 0);
      } else if (difference == 1) {
        // Consecutive day
        _currentStreak = loadedStreak + 1;
        _totalCheckIns++;
        _lastMissedDays = 0;
        await _storage.saveTotalCheckIns(_totalCheckIns);
        await _storage.saveStreak(_currentStreak, today.toIso8601String());
        await _updateGardenGrowth(true, 1);
      } else {
        // Streak penalty logic: -1 for every missed day
        int missedDays = difference - 1;
        _currentStreak = (loadedStreak - missedDays).clamp(1, 1000).toInt();
        _lastMissedDays = difference;
        
        // Points are now dynamic, no need to deduct explicitly
        
        await _storage.saveStreak(_currentStreak, today.toIso8601String());
        _totalCheckIns++;
        await _storage.saveTotalCheckIns(_totalCheckIns);
        await _updateGardenGrowth(true, difference);
      }
    }
    _updateWaterRate();
    notifyListeners();
    
    // Check for streak achievements
    return await _checkAchievements();
  }

  Future<void> updateProStatus({bool forceRefresh = false}) async {
    _isPro = true;
    notifyListeners();
  }

  Future<List<Achievement>> addDream(String title, {DateTime? deadline, int? themeColor, int? themeIcon, List<Map<String, dynamic>>? initialSteps}) async {
    // Determine steps source: provided AI steps OR generated mock steps
    final steps = (initialSteps != null && initialSteps.isNotEmpty)
        ? initialSteps.map((s) {
            // Ensure we handle String parsing for DateTime if needed, assuming edge function returns proper structure
            // Edge Function expected to return: {'title': '...', 'duration': 15}
            final dayOffset = initialSteps.indexOf(s); // 0-based index
            final scheduledDate = DateTime.now().add(Duration(days: dayOffset));
            
            return ChallengeStep(
              title: s['title'] ?? 'Action Step ${dayOffset + 1}',
              durationMinutes: s['duration'] is int ? s['duration'] : (int.tryParse(s['duration'].toString()) ?? 15),
              scheduledDate: scheduledDate, // Schedule sequentially
            );
          }).toList()
        : _generateStepsForDream(title);

    final newDream = Dream(
      title: title,
      deadline: deadline,
      themeColor: themeColor,
      themeIcon: themeIcon,
      steps: steps,
    );
    _dreams.add(newDream);
    await _save();
    notifyListeners();
    
    // Check for dream achievements
    return await _checkAchievements();
  }
  
  Future<void> addPoints(int amount) async {
    // Points are now calculated dynamically based on achievements/activity directly.
    // This function acts as a notifier for UI updates if needed, but storage is handled via derived score.
    notifyListeners();
  }

  Future<List<Achievement>> recordNegotiationCompletion() async {
    _negotiationsCompleted++;
    await _storage.saveNegotiationsCompleted(_negotiationsCompleted);
    // Also track as a generic She Stacks completion
    await trackGameCompletion("Negotiation Lab");
    
    // Add points for negotiation completion (+250 as seen in SheStacksScreen)
    await addPoints(250);
    notifyListeners();
    return await _checkAchievements();
  }

  Future<void> trackGameCompletion(String gameTitle) async {
    if (!_distinctGamesPlayed.contains(gameTitle)) {
      _distinctGamesPlayed.add(gameTitle);
      await _storage.saveDistinctGames(_distinctGamesPlayed.toList());
      notifyListeners();
      await _checkAchievements();
    }
  }
  
  Future<List<Achievement>> addTravelMemory(String place, double lat, double lng, {String? id, String memory = '', String? note, List<String> photos = const [], bool isPublic = false}) async {
    // Prevent duplicate entries if retrying with the same ID
    if (id != null) {
      _travelMemories.removeWhere((m) => m.id == id);
    }

    final newMemory = TravelMemory(
      id: id,
      place: place,
      latitude: lat,
      longitude: lng,
      memory: memory,
      note: note,
      photos: photos,
      isPublic: isPublic,
    );
    _travelMemories.add(newMemory);
    await _save();
    
    // Add points for travel (+20)
    await addPoints(20);
    
    notifyListeners();
    
    // Check for travel achievements
    return await _checkAchievements();
  }

  Future<void> fetchPublicMemories() async {
    _publicMemories = await _storage.fetchPublicMemories();
    notifyListeners();
  }

  Future<void> deleteTravelMemory(String id) async {
    final index = _travelMemories.indexWhere((m) => m.id == id);
    if (index != -1) {
      final memory = _travelMemories[index];
      _travelMemories.removeAt(index);
      await _storage.deleteTravelMemory(id, memory.photos);
      await _save();
      notifyListeners();
      
      // Check for changes (potentially re-locking achievements)
      await _checkAchievements();
    }
  }

  Future<void> updateTravelMemory(TravelMemory updatedMemory) async {
    final index = _travelMemories.indexWhere((m) => m.id == updatedMemory.id);
    if (index != -1) {
      _travelMemories[index] = updatedMemory;
      await _save();
      notifyListeners();
    }
  }

  // Journal Methods
  Future<List<Achievement>> addJournalEntry(JournalEntry entry) async {
    _journalEntries.add(entry);
    await _save();
    notifyListeners();
    return await _checkAchievements();
  }

  Future<void> updateJournalEntry(JournalEntry updatedEntry) async {
    final index = _journalEntries.indexWhere((e) => e.id == updatedEntry.id);
    if (index != -1) {
      _journalEntries[index] = updatedEntry;
      await _save();
      notifyListeners();
    }
  }

  Future<void> deleteJournalEntry(String id) async {
    _journalEntries.removeWhere((e) => e.id == id);
    await _save();
    notifyListeners();
    await _checkAchievements();
  }

  Future<List<Achievement>> toggleTodoItem(String entryId, String todoId) async {
    debugPrint('Toggling Todo: entryId=$entryId, todoId=$todoId');
    final entryIndex = _journalEntries.indexWhere((e) => e.id == entryId);
    if (entryIndex == -1) {
      debugPrint('Entry not found: $entryId');
      return [];
    }

    final entry = _journalEntries[entryIndex];
    final todoIndex = entry.todos.indexWhere((t) => t.id == todoId);
    if (todoIndex == -1) {
      debugPrint('Todo not found: $todoId among ${entry.todos.map((t) => t.id).toList()}');
      return [];
    }

    final updatedTodos = List<TodoItem>.from(entry.todos);
    updatedTodos[todoIndex] = updatedTodos[todoIndex].copyWith(
      isCompleted: !updatedTodos[todoIndex].isCompleted,
    );

    _journalEntries[entryIndex] = entry.copyWith(
      todos: updatedTodos,
      updatedAt: DateTime.now(),
    );

    debugPrint('Todo $todoId toggled to: ${updatedTodos[todoIndex].isCompleted}');

    // Track total todo completions
    if (updatedTodos[todoIndex].isCompleted) {
      _totalTodoCompletions++;
      await _storage.saveTodoCompletions(_totalTodoCompletions);
      await _checkAchievements();
    } else {
      _totalTodoCompletions = (_totalTodoCompletions - 1).clamp(0, 99999);
      await _storage.saveTodoCompletions(_totalTodoCompletions);
    }

    await _save();
    notifyListeners();
    return await _checkAchievements();
  }




  // Saved & AI Insight Methods
  Future<void> toggleSavedEntry(String entryId, {bool? save, String? insight}) async {
    final index = _journalEntries.indexWhere((e) => e.id == entryId);
    if (index != -1) {
      final entry = _journalEntries[index];
      // If save is null, toggle. If insight is provided, auto-save=true.
      final newSavedState = save ?? !entry.isSaved; 
      
      _journalEntries[index] = entry.copyWith(
        isSaved: newSavedState,
        aiInsight: insight ?? entry.aiInsight, // Update insight if provided
      );
      await _save();
      notifyListeners();
    }
  }

  // Group methods removed...
  // Future<void> addJournalGroup...
  // Future<void> updateJournalGroup...
  // Future<void> deleteJournalGroup...
  // Future<void> assignEntryToGroup...

  Future<bool> togglePinEntry(String entryId) async {
    final index = _journalEntries.indexWhere((e) => e.id == entryId);
    if (index == -1) return false;

    final entry = _journalEntries[index];
    
    // If trying to pin, check if we already have 3 pinned
    if (!entry.isPinned) {
      final pinnedCount = _journalEntries.where((e) => e.isPinned).length;
      if (pinnedCount >= 3) {
        return false; // Can't pin more than 3
      }
    }

    _journalEntries[index] = entry.copyWith(isPinned: !entry.isPinned);
    await _save();
    notifyListeners();
    return true;
  }

  Future<void> deleteDream(String id) async {
    _dreams.removeWhere((d) => d.id == id);
    await _save();
    notifyListeners();
    
    // Check for changes (potentially re-locking achievements)
    await _checkAchievements();
  }

  Future<List<Achievement>> toggleStepCompletion(String dreamId, String stepId) async {
    final dreamIndex = _dreams.indexWhere((d) => d.id == dreamId);
    if (dreamIndex == -1) return [];

    final stepIndex = _dreams[dreamIndex].steps.indexWhere((s) => s.id == stepId);
    if (stepIndex == -1) return [];

    final step = _dreams[dreamIndex].steps[stepIndex];
    step.isCompleted = !step.isCompleted;
    step.completedAt = step.isCompleted ? DateTime.now() : null;

    // Re-save entire list for simplicity
    await _save();
    
    // Award points if completed (+30)
    if (step.isCompleted) {
      await addPoints(30);
    }
    
    notifyListeners();
    
    // Check for action completion achievements and return them
    return await _checkAchievements();
  }

  Future<void> _save() async {
    await _storage.saveDreams(_dreams);
    await _storage.saveTravelMemories(_travelMemories);
    await _storage.saveJournalEntries(_journalEntries);
    await _storage.savePinnedJournalHome(_pinnedJournalToHomeIds);
    await _storage.saveWidgetJournalEntryId(_widgetJournalEntryId);
    // await _storage.saveJournalGroups(_journalGroups);
  }

  // Mock AI breakdown
  List<ChallengeStep> _generateStepsForDream(String title) {
    // Start from midnight today to ensure consistent comparison
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return [
      ChallengeStep(title: 'Visualize exactly what "$title" looks like', durationMinutes: 5, scheduledDate: today),
      ChallengeStep(title: 'Research one person who has done this', durationMinutes: 10, scheduledDate: today.add(const Duration(days: 1))),
      ChallengeStep(title: 'Write down 3 main blockers', durationMinutes: 5, scheduledDate: today.add(const Duration(days: 2))),
      ChallengeStep(title: 'Brainstorm 5 tiny first steps', durationMinutes: 5, scheduledDate: today.add(const Duration(days: 3))),
      ChallengeStep(title: 'Pick one tiny step and do it now', durationMinutes: 15, scheduledDate: today.add(const Duration(days: 4))),
      ChallengeStep(title: 'Share your goal with one friend', durationMinutes: 5, scheduledDate: today.add(const Duration(days: 5))),
      ChallengeStep(title: 'Celebrate your first week of progress!', durationMinutes: 5, scheduledDate: today.add(const Duration(days: 6))),
    ]
;
  }
  
  Future<void> updateDream(Dream updatedDream) async {
    final index = _dreams.indexWhere((d) => d.id == updatedDream.id);
    if (index != -1) {
      _dreams[index] = updatedDream;
      await _save();
      notifyListeners();
    }
  }

  /// Check and unlock achievements based on current stats
  Future<List<Achievement>> _checkAchievements() async {
    final achievementService = AchievementService();
    
    // Calculate stats
    final totalDreams = _dreams.length;
    final completedActions = _dreams
        .expand((dream) => dream.steps)
        .where((step) => step.isCompleted)
        .length;
    final completedDreams = _dreams.where((dream) => 
        dream.steps.every((step) => step.isCompleted)).length;
    
    final travelMemories = _travelMemories.length;
    final countriesVisited = _travelMemories.map((m) => m.place).toSet().length;
    final travelPhotos = _travelMemories
        .expand((m) => m.photos)
        .length;
    
    final gardenPlantsTotal = _gardenCells.where((c) => c > 0).length;
    final gardenPlantsStage4 = _gardenCells.where((c) => c == 4).length;

    // Filter out demo entries for achievements
    final userJournalEntries = _journalEntries.where((e) => e.id != 'welcome_note' && e.id != 'daily_rituals').length;
    final userTodoItems = _journalEntries
        .where((e) => e.id != 'welcome_note' && e.id != 'daily_rituals' && e.type == JournalEntryType.todo)
        .expand((e) => e.todos)
        .where((t) => t.isCompleted)
        .length;
    
    // Check achievements
    final newAchievements = await achievementService.checkAchievements(
      currentStreak: _currentStreak,
      totalPoints: activityPoints,
      totalDreams: totalDreams,
      completedActions: completedActions,
      completedDreams: completedDreams,
      travelMemories: travelMemories,
      countriesVisited: countriesVisited,
      travelPhotos: travelPhotos,
      totalCheckIns: _totalCheckIns,
      currentLevel: currentLevel,
      gardenPlantsTotal: gardenPlantsTotal,
      gardenPlantsStage4: gardenPlantsStage4,
      isPro: _isPro,
      journalEntries: userJournalEntries,
      todoItems: userTodoItems,
    );
    
    if (newAchievements.isNotEmpty) {
      // +50 points for each new badge
      await addPoints(50 * newAchievements.length);
    }
    
    return newAchievements;
  }

  Future<void> toggleCardPin(String cardId) async {
    if (_pinnedCardIds.contains(cardId)) {
      _pinnedCardIds.remove(cardId);
    } else {
      _pinnedCardIds.add(cardId);
    }
    await _storage.savePinnedCards(_pinnedCardIds);
    notifyListeners();
  }

  Future<void> toggleDreamPin(String dreamId) async {
    if (_pinnedDreamIds.contains(dreamId)) {
      _pinnedDreamIds.remove(dreamId);
    } else {
      _pinnedDreamIds.add(dreamId);
    }
    // Storage persistence would be added to _storage.savePinnedDreams if desired
    // For now we rely on the main _save() which saves the dreams list
    // Actually, we should probably add a dedicated save for pinned dreams or
    // just ensure dreams are sorted by pinned status in the getter.
    notifyListeners();
  }

  void toggleJournalPinToHome(String entryId) {
    if (_pinnedJournalToHomeIds.contains(entryId)) {
      _pinnedJournalToHomeIds.remove(entryId);
    } else {
      _pinnedJournalToHomeIds.add(entryId);
    }
    _storage.savePinnedJournalHome(_pinnedJournalToHomeIds);
    notifyListeners();
  }

  void toggleJournalPinToWidget(String entryId) {
    if (_widgetJournalEntryId == entryId) {
      _widgetJournalEntryId = null;
    } else {
      _widgetJournalEntryId = entryId;
    }
    
    _updateWidget();
    _storage.saveWidgetJournalEntryId(_widgetJournalEntryId);
    notifyListeners();
  }

  Future<void> _updateWidget() async {
    final entry = _journalEntries.firstWhere((e) => e.id == _widgetJournalEntryId, orElse: () => JournalEntry(title: '', content: '', type: JournalEntryType.note, color: 0));
    const String groupId = 'group.com.shipyardapps.bloom';

    if (_widgetJournalEntryId == null) {
      await HomeWidget.saveWidgetData<String>('todo_title', "Todo List");
      await HomeWidget.saveWidgetData<int>('todo_count', 0);
    } else {
      await HomeWidget.saveWidgetData<String>('todo_title', entry.title);
      await HomeWidget.saveWidgetData<String>('todo_entry_id', _widgetJournalEntryId);
      
      if (entry.type == JournalEntryType.todo) {
        final int count = entry.todos.length;
        await HomeWidget.saveWidgetData<int>('todo_count', count);
        for (int i = 0; i < count && i < 5; i++) {
          await HomeWidget.saveWidgetData<String>('todo_${i+1}_text', entry.todos[i].text);
          await HomeWidget.saveWidgetData<bool>('todo_${i+1}_checked', entry.todos[i].isCompleted);
          await HomeWidget.saveWidgetData<String>('todo_${i+1}_id', entry.todos[i].id);
        }
      } else {
        await HomeWidget.saveWidgetData<int>('todo_count', 1);
        await HomeWidget.saveWidgetData<String>('todo_1_text', entry.content);
        await HomeWidget.saveWidgetData<bool>('todo_1_checked', false);
        await HomeWidget.saveWidgetData<String>('todo_1_id', entry.id);
      }
    }

    await HomeWidget.updateWidget(
      name: 'TodoWidget',
      androidName: 'TodoWidget',
    );
  }

  Future<void> toggleTravelMapToWidget() async {
    _widgetTravelMapActive = !_widgetTravelMapActive;
    
    if (_widgetTravelMapActive) {
      // Generate map image when widget is activated
      final imagePath = await _generateMapImage();
      if (imagePath != null) {
        await HomeWidget.saveWidgetData<String>('travel_map_path', imagePath);
      }
    } else {
      // Clear map image when widget is deactivated
      final oldPath = await HomeWidget.getWidgetData<String>('travel_map_path');
      await WidgetToImageConverter.deleteImage(oldPath);
      await HomeWidget.saveWidgetData<String>('travel_map_path', '');
    }
    
    await _updateTravelWidget();
    _storage.saveWidgetTravelMapActive(_widgetTravelMapActive);
    notifyListeners();
  }

  Future<String?> _generateMapImage() async {
    try {
      // Calculate country visits
      Map<String, int> countryVisits = {};
      for (var memory in _travelMemories) {
        String country = memory.place;
        if (country.contains(',')) {
          country = country.split(',').last.trim();
        }
        if (country.isNotEmpty) {
          countryVisits[country] = (countryVisits[country] ?? 0) + 1;
        }
      }

      // Create map widget
      final mapWidget = Container(
        width: 800,
        height: 400,
        color: Colors.white,
        child: WorldMapSvg(countryVisits: countryVisits),
      );

      // Convert to image
      final imagePath = await WidgetToImageConverter.convertWidgetToImage(
        widget: mapWidget,
        filename: 'travel_map_widget.png',
        size: const Size(800, 400),
      );

      return imagePath;
    } catch (e) {
      debugPrint('Error generating map image: $e');
      return null;
    }
  }

  Future<void> _updateTravelWidget() async {
    // The map image is already saved to 'travel_map_path' by toggleTravelMapToWidget
    // Just trigger the widget update
    await HomeWidget.updateWidget(
      name: 'TravelWidget',
      androidName: 'TravelWidget',
    );
  }

  String _formatTravelDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    }
  }

  Future<void> syncAllData() async {
    await _storage.syncAllLocalData();
    await _loadData(); // Re-load to get merged results or just to refresh everything
  }

  Future<void> _addSampleData() async {
    // Clear and add to ensure clean state
    _journalEntries.removeWhere((e) => e.id == 'welcome_note' || e.id == 'daily_rituals');
    
    final welcomeNote = JournalEntry(
      id: 'welcome_note',
      title: "Welcome to Bloom! 🌸",
      content: "This is your personal space to reflect, dream, and grow. \n\n"
          "✨ **How to use Bloom:**\n"
          "• Tap the + button to create a new note or list.\n"
          "• Use the 'Discuss' button on any entry to dive deeper with AI.\n"
          "• Track your mood to see how your garden grows.\n\n"
          "We're glad to have you on this journey!",
      type: JournalEntryType.note,
      color: Colors.purple.shade100.value,
      tags: ["Welcome", "Guide"],
      mood: "😊",
      isPinned: true,
      isSaved: true,
    );

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final dailyRituals = JournalEntry(
      id: 'daily_rituals',
      title: "Daily Rituals 🌿",
      content: "",
      type: JournalEntryType.todo,
      color: Colors.green.shade100.value,
      tags: ["Habits", "Routine"],
      todos: [
        TodoItem(id: 'ritual_1_$timestamp', text: "Morning Reflection", isCompleted: false),
        TodoItem(id: 'ritual_2_$timestamp', text: "Drink 2L Water", isCompleted: false),
        TodoItem(id: 'ritual_3_$timestamp', text: "30-min Movement", isCompleted: false),
        TodoItem(id: 'ritual_4_$timestamp', text: "Express Gratitude", isCompleted: false),
      ],
      mood: "✨",
      isSaved: true,
    );

    _journalEntries.addAll([welcomeNote, dailyRituals]);
    await _save();
    await _storage.setHasSeedData();
    notifyListeners();
  }
}
