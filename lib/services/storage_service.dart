import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;
import '../models/dream.dart';
import '../models/challenge_step.dart';
import '../models/travel_memory.dart';
import '../models/journal_entry.dart';
// import '../models/journal_group.dart';

class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const String _dreamsKey = 'bloom_dreams';
  static const String _travelMemoriesKey = 'bloom_travel_memories';
  static const String _journalEntriesKey = 'bloom_journal_entries';
  // static const String _journalGroupsKey = 'bloom_journal_groups'; // Removed
  static const String _gardenKey = 'bloom_garden_state';
  static const String _negotiationsCompletedKey = 'bloom_negotiations_completed';
  static const String _todoCompletionsKey = 'bloom_todo_completions';
  static const String _distinctGamesKey = 'bloom_distinct_she_stacks_games';
  static const String _totalCheckInsKey = 'bloom_total_check_ins';
  static const String _hasSeedDataKey = 'bloom_has_seed_data';
  static const String _pinnedJournalHomeKey = 'bloom_pinned_journal_home';
  static const String _widgetJournalEntryIdKey = 'bloom_widget_journal_entry_id';
  static const String _widgetTravelMapActiveKey = 'bloom_widget_travel_map_active';
  static const String _isWinterModeKey = 'bloom_is_winter_mode';
  static const String _showDailyMotivationKey = 'bloom_show_motivation';
  static const String _showGardenKey = 'bloom_show_garden';
  static const String _showAchievementsKey = 'bloom_show_achievements';
  static const String _showMapKey = 'bloom_show_map';
  
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<SharedPreferences> get _getPrefs async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  User? get _currentUser => _supabase.auth.currentUser;

  // --- PHOTO UPLOAD ---

  Future<String?> _uploadPhoto(String localPath) async {
    final user = _currentUser;
    if (user == null) return null;

    final file = File(localPath);
    if (!await file.exists()) return null;

    final fileName = p.basename(localPath);
    final path = '${user.id}/$fileName';

    try {
      await _supabase.storage.from('travel-photos').upload(
            path,
            file,
            fileOptions: const FileOptions(upsert: true),
          );
      return _supabase.storage.from('travel-photos').getPublicUrl(path);
    } catch (e) {
      debugPrint('Photo Upload Error: $e');
      return null;
    }
  }

  // --- DREAMS ---

  Future<void> saveDreams(List<Dream> dreams) async {
    // Local Only
    final prefs = await _getPrefs;
    final String data = jsonEncode(dreams.map((e) => e.toMap()).toList());
    await prefs.setString(_dreamsKey, data);
  }

  Future<List<Dream>> loadDreams() async {
    final prefs = await _getPrefs;
    final String? localData = prefs.getString(_dreamsKey);

    if (localData == null) return [];
    try {
      final List<dynamic> jsonList = jsonDecode(localData);
      return jsonList.map((e) => Dream.fromMap(e)).toList();
    } catch (e) {
      return [];
    }
  }

  // --- TRAVEL MEMORIES ---

  Future<void> saveTravelMemories(List<TravelMemory> memories) async {
    final prefs = await _getPrefs;
    
    // 1. Handle Photo Uploads locally before saving
    final updatedMemories = <TravelMemory>[];
    for (final memory in memories) {
       final updatedPhotos = <String>[];
       bool modified = false;
       
       for (final photo in memory.photos) {
         if (photo.startsWith('http')) {
           updatedPhotos.add(photo);
         } else {
           final url = await _uploadPhoto(photo);
           if (url != null) {
             updatedPhotos.add(url);
             modified = true;
           } else {
             updatedPhotos.add(photo); // Keep local if failed
           }
         }
       }
       
       if (modified) {
         updatedMemories.add(TravelMemory(
           id: memory.id,
           place: memory.place,
           latitude: memory.latitude,
           longitude: memory.longitude,
           visitedDate: memory.visitedDate,
           memory: memory.memory,
           note: memory.note,
           photos: updatedPhotos,
           isPublic: memory.isPublic,
         ));
       } else {
         updatedMemories.add(memory);
       }
    }

    final String data = jsonEncode(updatedMemories.map((e) => e.toMap()).toList());
    await prefs.setString(_travelMemoriesKey, data);

    final user = _currentUser;
    if (user != null) {
      try {
        final upsertData = updatedMemories.map((m) => {
          'id': m.id,
          'user_id': user.id,
          'place': m.place,
          'latitude': m.latitude,
          'longitude': m.longitude,
          'visited_date': m.visitedDate.toIso8601String(),
          'memory': m.memory,
          'note': m.note,
          'photos': m.photos,
          'public': m.isPublic,
        }).toList();
        
        await _supabase.from('travel_memories').upsert(upsertData);
      } catch (e) {
        debugPrint('Supabase Travel Sync Error: $e');
        rethrow;
      }
    }
  }

  Future<List<TravelMemory>> loadTravelMemories({bool syncCloud = false}) async {
    final prefs = await _getPrefs;
    final String? localData = prefs.getString(_travelMemoriesKey);

    if (syncCloud) {
      final user = _currentUser;
      if (user != null) {
        try {
          final List<dynamic> cloudData = await _supabase
              .from('travel_memories')
              .select()
              .eq('user_id', user.id)
              .order('visited_date');
          
          if (cloudData.isNotEmpty) {
            final memories = cloudData.map((m) => TravelMemory(
              id: m['id'],
              place: m['place'],
              latitude: (m['latitude'] as num).toDouble(),
              longitude: (m['longitude'] as num).toDouble(),
              visitedDate: DateTime.parse(m['visited_date']),
              memory: m['memory'] ?? '',
              note: m['note'],
              photos: List<String>.from(m['photos'] ?? []),
              isPublic: m['public'] ?? false,
            )).toList();
            
            await prefs.setString(_travelMemoriesKey, jsonEncode(memories.map((e) => e.toMap()).toList()));
            return memories;
          }
        } catch (e) {
          debugPrint('Supabase Travel Load Error: $e');
        }
      }
    }

    if (localData == null) return [];
    try {
      final List<dynamic> jsonList = jsonDecode(localData);
      return jsonList.map((e) => TravelMemory.fromMap(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<TravelMemory>> fetchPublicMemories() async {
    try {
      debugPrint('StorageService: Fetching public memories...');
      
      List<dynamic> cloudData;
      
      try {
        // Attempt join with profiles table
        cloudData = await _supabase
            .from('travel_memories')
            .select('*, profiles(display_name, avatar_url)')
            .eq('public', true)
            .order('visited_date', ascending: false)
            .limit(100);
      } catch (e) {
        debugPrint('?????????????????????????????????????????????????????');
        debugPrint('StorageService: JOIN FETCH FAILED. CAUSE: $e');
        debugPrint('This usually means the Foreign Key is missing in Supabase.');
        debugPrint('?????????????????????????????????????????????????????');
        // Fallback to simple query if relationship doesn't exist
        cloudData = await _supabase
            .from('travel_memories')
            .select('*')
            .eq('public', true)
            .order('visited_date', ascending: false)
            .limit(100);
      }
      
      debugPrint('StorageService: Fetched ${cloudData.length} public memories');
      if (cloudData.isNotEmpty) {
          debugPrint('DEBUG First Record: ${cloudData.first}');
          debugPrint('DEBUG Profile Field: ${cloudData.first['profiles']}');
      }
      
      return cloudData.map((m) {
        // Handle profile data which might be a Map (1:1) or List (1:M) or null
        final rawProfile = m['profiles'];
        Map<String, dynamic>? profile;
        
        if (rawProfile is Map) {
          profile = rawProfile as Map<String, dynamic>;
        } else if (rawProfile is List && rawProfile.isNotEmpty) {
          profile = rawProfile.first as Map<String, dynamic>;
        }
        
        return TravelMemory(
          id: m['id'],
          place: m['place'],
          latitude: (m['latitude'] as num).toDouble(),
          longitude: (m['longitude'] as num).toDouble(),
          visitedDate: DateTime.parse(m['visited_date']),
          memory: m['memory'] ?? '',
          note: m['note'],
          photos: List<String>.from(m['photos'] ?? []),
          isPublic: true,
          userId: m['user_id'],
          userDisplayName: profile?['display_name'],
          userAvatarUrl: profile?['avatar_url'],
        );
      }).toList();
    } catch (e) {
      debugPrint('Supabase Public Fetch Error: $e');
      return [];
    }
  }

  // --- JOURNAL ---

  Future<void> saveJournalEntries(List<JournalEntry> entries) async {
    final prefs = await _getPrefs;
    final String data = jsonEncode(entries.map((e) => e.toMap()).toList());
    await prefs.setString(_journalEntriesKey, data);
  }

  Future<List<JournalEntry>> loadJournalEntries() async {
    final prefs = await _getPrefs;
    final String? localData = prefs.getString(_journalEntriesKey);

    if (localData == null) return [];
    try {
      final List<dynamic> jsonList = jsonDecode(localData);
      return jsonList.map((e) => JournalEntry.fromMap(e)).toList();
    } catch (e) {
      return [];
    }
  }

  // --- JOURNAL GROUPS (Removed) ---
  // Future<void> saveJournalGroups(List<JournalGroup> groups) async { ... }
  // Future<List<JournalGroup>> loadJournalGroups() async { ... }

  // Settings & Profile Sync
  static const String _themeModeKey = 'bloom_theme_mode';
  static const String _themeColorKey = 'bloom_theme_color';
  static const String _textScaleKey = 'bloom_text_scale';

  Future<void> saveSettings({
    required int themeModeIndex,
    required int themeColorValue,
    required double textScale,
    bool? isWinterMode,
    bool? showMotivation,
    bool? showGarden,
    bool? showAchievements,
    bool? showMap,
    String? instagram,
  }) async {
    final prefs = await _getPrefs;
    await prefs.setInt(_themeModeKey, themeModeIndex);
    await prefs.setInt(_themeColorKey, themeColorValue);
    await prefs.setDouble(_textScaleKey, textScale);
    if (isWinterMode != null) {
      await prefs.setBool(_isWinterModeKey, isWinterMode);
    }
    if (showMotivation != null) await prefs.setBool(_showDailyMotivationKey, showMotivation);
    if (showGarden != null) await prefs.setBool(_showGardenKey, showGarden);
    if (showAchievements != null) await prefs.setBool(_showAchievementsKey, showAchievements);
    if (showMap != null) await prefs.setBool(_showMapKey, showMap);
    if (instagram != null) await prefs.setString('bloom_instagram', instagram);

    final user = _currentUser;
    if (user != null) {
      try {
        await _supabase.from('profiles').upsert({
          'id': user.id,
          'theme_mode': themeModeIndex,
          'theme_color': themeColorValue,
          'display_name': user.userMetadata?['display_name'],
          'avatar_url': user.userMetadata?['avatar_url'],
          'instagram': instagram,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
         debugPrint('Supabase Profile Sync Error: $e');
      }
    }
  }

  Future<void> syncProfile() async {
    final user = _currentUser;
    if (user != null) {
      try {
        await _supabase.from('profiles').upsert({
          'id': user.id,
          'display_name': user.userMetadata?['display_name'],
          'avatar_url': user.userMetadata?['avatar_url'],
          'updated_at': DateTime.now().toIso8601String(),
        });
        debugPrint('✅ Profile table synced with metadata');
      } catch (e) {
        debugPrint('❌ Profile table sync error: $e');
      }
    }
  }

  Future<Map<String, dynamic>?> fetchFullProfile() async {
    final user = _currentUser;
    if (user == null) return null;
    try {
      return await _supabase.from('profiles').select().eq('id', user.id).single();
    } catch (e) {
      debugPrint('Supabase Full Profile Fetch Error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchUserProfile(String userId) async {
    try {
      return await _supabase.from('profiles').select().eq('id', userId).single();
    } catch (e) {
      debugPrint('Supabase User Profile Fetch Error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> loadSettings({Map<String, dynamic>? cloudProfile}) async {
    final prefs = await _getPrefs;
    Map<String, dynamic> settings = {
      'themeMode': prefs.getInt(_themeModeKey) ?? 0,
      'themeColor': prefs.getInt(_themeColorKey) ?? 0xFFFF7F50,
      'textScale': prefs.getDouble(_textScaleKey) ?? 1.0,
      'isWinterMode': prefs.getBool(_isWinterModeKey) ?? false,
      'showMotivation': prefs.getBool(_showDailyMotivationKey) ?? true,
      'showGarden': prefs.getBool(_showGardenKey) ?? true,
      'showAchievements': prefs.getBool(_showAchievementsKey) ?? true,
      'showMap': prefs.getBool(_showMapKey) ?? true,
      'instagram': prefs.getString('bloom_instagram'),
    };

    if (cloudProfile != null) {
      settings['themeMode'] = cloudProfile['theme_mode'] ?? settings['themeMode'];
      settings['themeColor'] = cloudProfile['theme_color'] ?? settings['themeColor'];
      settings['instagram'] = cloudProfile['instagram'] ?? settings['instagram'];
      
      // Also sync achievements if they exist in cloud profile
      if (cloudProfile['unlocked_achievements'] != null) {
        final List<String> cloudUnlocked = List<String>.from(cloudProfile['unlocked_achievements']);
        await prefs.setString('unlocked_achievements', json.encode(cloudUnlocked));
      }
    }
    return settings;
  }

  // --- STATS SYNC ---

  Future<void> saveStreak(int streak, String lastActiveDate) async {
    final prefs = await _getPrefs;
    await prefs.setInt(_currentStreakKey, streak);
    await prefs.setString(_lastActiveDateKey, lastActiveDate);

    final user = _currentUser;
    if (user != null) {
      await _supabase.from('profiles').upsert({
        'id': user.id,
        'current_streak': streak,
        'last_active_date': lastActiveDate,
      });
    }
  }

  // Points & Level persistence removed in favor of dynamic calculation
  Future<void> saveActivityScore(int score) async {
    final user = _currentUser;
    if (user != null) {
      await _supabase.from('profiles').upsert({
        'id': user.id,
        'activity_score': score,
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> saveGarden(List<int> cells) async {
    final prefs = await _getPrefs;
    await prefs.setString(_gardenKey, jsonEncode(cells));

    final user = _currentUser;
    if (user != null) {
      await _supabase.from('profiles').upsert({
        'id': user.id,
        'garden_state': cells,
      });
    }
  }

  /// Sync all existing local data to cloud (Call this after login)
  Future<void> syncAllLocalData() async {
    final user = _currentUser;
    if (user == null) return;

    final dreams = await loadDreams();
    if (dreams.isNotEmpty) await saveDreams(dreams);

    final memories = await loadTravelMemories();
    if (memories.isNotEmpty) await saveTravelMemories(memories);

    // final groups = await loadJournalGroups(); // Removed
    // if (groups.isNotEmpty) await saveJournalGroups(groups); // Removed

    final entries = await loadJournalEntries();
    if (entries.isNotEmpty) await saveJournalEntries(entries);

    // Sync Stats & Score
    final streakData = await loadStreakData();
    if (streakData['streak'] != null) await saveStreak(streakData['streak'], streakData['lastActiveDate'] ?? '');

    // Restore IDs for score calculation
    final unlockedIds = await _getPrefs.then((p) => p.getString('unlocked_achievements'));
    final List<String> loadedIds = unlockedIds != null ? List<String>.from(json.decode(unlockedIds)) : [];

    // Auto-calculate score based on all metrics
    // Note: Points logic removed, so points component is 0 or derived if needed. 
    // Assuming score formula is: (Achievements * 100) + (Memories * 50) + (Streak * 10)
    final score = await _calculateActivityScore(
      achievementsCount: loadedIds.length,
      travelMemoriesCount: memories.length,
      streak: streakData['streak'] ?? 0,
    );
    
    await saveActivityScore(score);

    final garden = await loadGarden();
    await saveGarden(garden);
    
    // Sync Achievements list
    if (loadedIds.isNotEmpty) {
      await saveUnlockedAchievementsToCloud(loadedIds);
    }
  }

  Future<int> _calculateActivityScore({
    required int achievementsCount, 
    required int travelMemoriesCount, 
    required int streak
  }) async {
    // Formula: (Achievements * 100) + (Memories * 50) + (Streak * 10)
    return (achievementsCount * 100) + (travelMemoriesCount * 50) + (streak * 10);
  }

  Future<void> saveUnlockedAchievementsToCloud(List<String> ids) async {
    final user = _currentUser;
    if (user != null) {
      try {
        // Also update the score while we are at it
        // Also update the score while we are at it
        final memories = await loadTravelMemories();
        final streakData = await loadStreakData();
        
        final score = await _calculateActivityScore(
          achievementsCount: ids.length, 
          travelMemoriesCount: memories.length, 
          streak: streakData['streak'] ?? 0
        );

        await _supabase.from('profiles').upsert({
          'id': user.id,
          'unlocked_achievements': ids,
          'activity_score': score,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        debugPrint('Supabase Achievement Sync Error: $e');
      }
    }
  }

  // --- STREAK persistence ---
  static const String _currentStreakKey = 'bloom_current_streak';
  static const String _lastActiveDateKey = 'bloom_last_active_date';

  Future<Map<String, dynamic>> loadStreakData({Map<String, dynamic>? cloudProfile}) async {
    final prefs = await _getPrefs;
    Map<String, dynamic> data = {
      'streak': prefs.getInt(_currentStreakKey) ?? 0,
      'lastActiveDate': prefs.getString(_lastActiveDateKey),
    };

    final profile = cloudProfile;
    if (profile != null) {
      data['streak'] = profile['current_streak'] ?? data['streak'];
      data['lastActiveDate'] = profile['last_active_date'] ?? data['lastActiveDate'];
    }
    return data;
  }



  // Garden State
  Future<List<int>> loadGarden({Map<String, dynamic>? cloudProfile}) async {
    final prefs = await _getPrefs;
    final String? localJson = prefs.getString(_gardenKey);
    List<int> cells = localJson != null ? List<int>.from(jsonDecode(localJson)) : List.filled(25, 0);

    final profile = cloudProfile;
    if (profile != null && profile['garden_state'] != null) {
      cells = List<int>.from(profile['garden_state']);
    }
    return cells;
  }

  // Pinned Cards (Still semi-local for UI preference)
  static const String _pinnedCardsKey = 'bloom_pinned_cards';

  Future<void> savePinnedCards(List<String> cardIds) async {
    final prefs = await _getPrefs;
    await prefs.setStringList(_pinnedCardsKey, cardIds);
  }

  Future<List<String>> loadPinnedCards() async {
    final prefs = await _getPrefs;
    return prefs.getStringList(_pinnedCardsKey) ?? [];
  }

  Future<void> saveNegotiationsCompleted(int count) async {
    final prefs = await _getPrefs;
    await prefs.setInt(_negotiationsCompletedKey, count);
  }

  Future<int> loadNegotiationsCompleted() async {
    final prefs = await _getPrefs;
    return prefs.getInt(_negotiationsCompletedKey) ?? 0;
  }

  Future<void> saveTodoCompletions(int count) async {
    final prefs = await _getPrefs;
    await prefs.setInt(_todoCompletionsKey, count);
  }

  Future<int> loadTodoCompletions() async {
    final prefs = await _getPrefs;
    return prefs.getInt(_todoCompletionsKey) ?? 0;
  }

  Future<void> saveDistinctGames(List<String> games) async {
    final prefs = await _getPrefs;
    await prefs.setStringList(_distinctGamesKey, games);
  }

  Future<List<String>> loadDistinctGames() async {
    final prefs = await _getPrefs;
    return prefs.getStringList(_distinctGamesKey) ?? [];
  }

  Future<void> saveTotalCheckIns(int count) async {
    final prefs = await _getPrefs;
    await prefs.setInt(_totalCheckInsKey, count);
  }

  Future<int> loadTotalCheckIns() async {
    final prefs = await _getPrefs;
    return prefs.getInt(_totalCheckInsKey) ?? 0;
  }

  Future<void> savePinnedJournalHome(List<String> entryIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_pinnedJournalHomeKey, entryIds);
  }

  Future<List<String>> loadPinnedJournalHome() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_pinnedJournalHomeKey) ?? [];
  }

  Future<void> saveWidgetJournalEntryId(String? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(_widgetJournalEntryIdKey);
    } else {
      await prefs.setString(_widgetJournalEntryIdKey, id);
    }
  }

  Future<String?> loadWidgetJournalEntryId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_widgetJournalEntryIdKey);
  }

  Future<void> saveWidgetTravelMapActive(bool active) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_widgetTravelMapActiveKey, active);
  }

  Future<bool> loadWidgetTravelMapActive() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_widgetTravelMapActiveKey) ?? false;
  }

  Future<bool> hasSeedData() async {
    final prefs = await _getPrefs;
    return prefs.getBool(_hasSeedDataKey) ?? false;
  }

  Future<void> setHasSeedData() async {
    final prefs = await _getPrefs;
    await prefs.setBool(_hasSeedDataKey, true);
  }

  Future<void> deleteTravelMemory(String id, List<String> photos) async {
    final user = _currentUser;
    if (user != null) {
      try {
        // 1. Delete record from database
        await _supabase.from('travel_memories').delete().eq('id', id);
        
        // 2. Delete photos from storage bucket
        final pathsToDelete = photos
            .where((url) => url.contains('travel-photos') && url.contains(user.id))
            .map((url) {
              final parts = url.split('travel-photos/');
              return parts.length > 1 ? parts.last : null;
            })
            .whereType<String>()
            .toList();
            
        if (pathsToDelete.isNotEmpty) {
          await _supabase.storage.from('travel-photos').remove(pathsToDelete);
        }
      } catch (e) {
        debugPrint('Supabase Travel Delete Error: $e');
      }
    }
  }
}
