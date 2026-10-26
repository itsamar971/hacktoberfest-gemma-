import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bloom/services/storage_service.dart';
import 'dart:convert';

class AchievementService extends ChangeNotifier {
  static final AchievementService _instance = AchievementService._internal();
  factory AchievementService() => _instance;
  AchievementService._internal();

  final List<Achievement> _achievements = [];
  final List<String> _unlockedAchievementIds = [];
  
  List<Achievement> get achievements => _achievements;
  List<Achievement> get unlockedAchievements => 
      _achievements.where((a) => _unlockedAchievementIds.contains(a.id)).toList();
  
  int get totalUnlocked => _unlockedAchievementIds.length;

  Future<void> initialize() async {
    _initializeAchievements();
    await _loadUnlockedAchievements();
  }

  void _initializeAchievements() {
    _achievements.addAll([
      // Streak achievements (7)
      Achievement('first_step', '🌱', 'First Step', 'Complete your first daily check-in', AchievementType.streak, 1),
      Achievement('3_day_streak', '🔥', '3-Day Streak', 'Check in for 3 days in a row', AchievementType.streak, 3),
      Achievement('week_warrior', '⚡', 'Week Warrior', 'Complete a full week of check-ins', AchievementType.streak, 7),
      Achievement('consistency', '💪', 'Consistency', 'Check in for 14 days straight', AchievementType.streak, 14),
      Achievement('month_master', '🏆', 'Month Master', 'Complete 30 days in a row', AchievementType.streak, 30),
      Achievement('half_century', '🎖️', 'Half Century', 'Maintain a 50-day streak', AchievementType.streak, 50),
      Achievement('diamond_streak', '💎', 'Diamond Streak', 'Maintain a 75-day streak', AchievementType.streak, 75),
      Achievement('century_club', '👑', 'Century Club', 'Reach a 100-day streak', AchievementType.streak, 100),
      
      // Points achievements (8)
      Achievement('point_starter', '⭐', 'Point Starter', 'Earn your first 100 points', AchievementType.points, 100),
      Achievement('rising_star', '✨', 'Rising Star', 'Collect 500 points', AchievementType.points, 500),
      Achievement('shining_bright', '💫', 'Shining Bright', 'Reach 1,000 points', AchievementType.points, 1000),
      Achievement('superstar', '🌟', 'Superstar', 'Accumulate 2,500 points', AchievementType.points, 2500),
      Achievement('diamond_status', '💎', 'Diamond Status', 'Earn 5,000 points', AchievementType.points, 5000),
      Achievement('legendary', '🔮', 'Legendary', 'Reach 10,000 points', AchievementType.points, 10000),
      Achievement('point_elite', '🚀', 'Point Elite', 'Acrue 20,000 points', AchievementType.points, 20000),
      Achievement('bloom_millionaire', '💰', 'Bloom Millionaire', 'Amass 50,000 points', AchievementType.points, 50000),
      
      // Dream achievements (6)
      Achievement('dreamer', '💭', 'Dreamer', 'Create your first dream', AchievementType.dreams, 1),
      Achievement('goal_setter', '🎯', 'Goal Setter', 'Add 3 dreams', AchievementType.dreams, 3),
      Achievement('ambitious', '🚀', 'Ambitious', 'Track 5 different dreams', AchievementType.dreams, 5),
      Achievement('big_dreamer', '🪐', 'Big Dreamer', 'Envision 10 different dreams', AchievementType.dreams, 10),
      Achievement('dream_achiever', '🎊', 'Dream Achiever', 'Complete your first dream', AchievementType.completedDreams, 1),
      Achievement('visionary_master', '🌈', 'Visionary Master', 'Fully realize 5 dreams', AchievementType.completedDreams, 5),

      // Action achievements (4)
      Achievement('first_action', '📝', 'First Step', 'Complete your first micro-action', AchievementType.actions, 1),
      Achievement('action_taker', '✅', 'Action Taker', 'Complete 10 micro-actions', AchievementType.actions, 10),
      Achievement('momentum_builder', '🌊', 'Momentum Builder', 'Finish 50 micro-actions', AchievementType.actions, 50),
      Achievement('unstoppable', '💥', 'Unstoppable', 'Complete 100 micro-actions', AchievementType.actions, 100),
      
      // Travel achievements (8)
      Achievement('explorer', '🗺️', 'Explorer', 'Add your first travel memory', AchievementType.travel, 1),
      Achievement('vacation_mode', '🏖️', 'Vacation Mode', 'Record 5 travel memories', AchievementType.travel, 5),
      Achievement('travel_addict', '🗽', 'Travel Addict', 'Log 25 travel memories', AchievementType.travel, 25),
      Achievement('jet_setter', '✈️', 'Jet Setter', 'Visit 3 different countries', AchievementType.countries, 3),
      Achievement('world_traveler', '🌍', 'World Traveler', 'Collect memories from 5 countries', AchievementType.countries, 5),
      Achievement('globe_trotter', '🌏', 'Globe Trotter', 'Visit 10 different countries', AchievementType.countries, 10),
      Achievement('memory_keeper', '📸', 'Memory Keeper', 'Add 10 travel photos', AchievementType.travelPhotos, 10),
      Achievement('shutterbug', '🖼️', 'Shutterbug', 'Save 50 travel photos', AchievementType.travelPhotos, 50),
      
      // Journal achievements (6)
      Achievement('journal_starter', '📓', 'Journal Starter', 'Write your first journal entry', AchievementType.journalEntries, 1),
      Achievement('journal_regular', '✒️', 'Journal Regular', 'Write 10 journal entries', AchievementType.journalEntries, 10),
      Achievement('journal_pro', '📖', 'Journal Pro', 'Write 30 journal entries', AchievementType.journalEntries, 30),
      Achievement('journal_legend', '📚', 'Journal Legend', 'Write 100 journal entries', AchievementType.journalEntries, 100),
      Achievement('todo_starter', '🎫', 'Todo Starter', 'Complete 5 todo items', AchievementType.todoItems, 5),
      Achievement('todo_master', '🏅', 'Todo Master', 'Complete 25 todo items', AchievementType.todoItems, 25),



      // Garden achievements (4)
      Achievement('garden_seed', '🌱', 'Garden Seed', 'Have 5 growing plants in your garden', AchievementType.gardenGrowth, 5),
      Achievement('garden_bloomer', '🌸', 'Garden Bloomer', 'Grow your first plant to full bloom', AchievementType.gardenGrowth, 1),
      Achievement('garden_botanist', '🌻', 'Botanist', 'Grow 10 plants to full bloom', AchievementType.gardenGrowth, 10),
      Achievement('garden_paradise', '🏞️', 'Garden Paradise', 'Fill your entire 5x5 garden with life', AchievementType.gardenGrowth, 25),

      // Check-in achievements removed in favor of streak achievements

      // Special achievements (2)
      Achievement('customizer', '🎨', 'Customizer', 'Change your theme', AchievementType.special, 1),
      Achievement('pro_access', '🃏', 'Pro Status', 'Upgrade to Bloom Pro', AchievementType.special, 1),
      
      // Level achievements (3)
      Achievement('level_5', '🌟', 'Level 5 Reached', 'Reach level 5', AchievementType.level, 5),
      Achievement('level_10', '⭐', 'Level 10 Reached', 'Reach level 10', AchievementType.level, 10),
      Achievement('level_20', '💫', 'Level 20 Reached', 'Reach level 20', AchievementType.level, 20),
    ]);
  }

  Future<void> _loadUnlockedAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    final unlockedJson = prefs.getString('unlocked_achievements');
    if (unlockedJson != null) {
      _unlockedAchievementIds.clear();
      _unlockedAchievementIds.addAll(List<String>.from(json.decode(unlockedJson)));
    }
  }

  Future<void> _saveUnlockedAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('unlocked_achievements', json.encode(_unlockedAchievementIds));
  }

  /// Check and unlock achievements based on user stats
  Future<List<Achievement>> checkAchievements({
    int? currentStreak,
    int? totalPoints,
    int? totalDreams,
    int? completedActions,
    int? completedDreams,
    int? travelMemories,
    int? countriesVisited,
    int? travelPhotos,
    int? totalCheckIns,
    int? currentLevel,
    int? journalEntries,
    int? todoItems,
    int? gardenPlantsStage4,
    int? gardenPlantsTotal,
    bool? isPro,
  }) async {
    final newlyUnlocked = <Achievement>[];
    bool hasChanges = false;

    for (final achievement in _achievements) {
      // Logic determines if it SHOULD be unlocked right now
      bool shouldBeUnlocked = false;

      switch (achievement.type) {
        case AchievementType.streak:
          shouldBeUnlocked = (currentStreak ?? 0) >= achievement.requirement;
          break;
        case AchievementType.points:
          shouldBeUnlocked = (totalPoints ?? 0) >= achievement.requirement;
          break;
        case AchievementType.dreams:
          shouldBeUnlocked = (totalDreams ?? 0) >= achievement.requirement;
          break;
        case AchievementType.actions:
          shouldBeUnlocked = (completedActions ?? 0) >= achievement.requirement;
          break;
        case AchievementType.completedDreams:
          shouldBeUnlocked = (completedDreams ?? 0) >= achievement.requirement;
          break;
        case AchievementType.travel:
          shouldBeUnlocked = (travelMemories ?? 0) >= achievement.requirement;
          break;
        case AchievementType.countries:
          shouldBeUnlocked = (countriesVisited ?? 0) >= achievement.requirement;
          break;
        case AchievementType.travelPhotos:
          shouldBeUnlocked = (travelPhotos ?? 0) >= achievement.requirement;
          break;

        case AchievementType.level:
          shouldBeUnlocked = (currentLevel ?? 0) >= achievement.requirement;
          break;

        case AchievementType.journalEntries:
          shouldBeUnlocked = (journalEntries ?? 0) >= achievement.requirement;
          break;
        case AchievementType.todoItems:
          shouldBeUnlocked = (todoItems ?? 0) >= achievement.requirement;
          break;
        case AchievementType.gardenGrowth:
          if (achievement.id == 'garden_seed') {
            shouldBeUnlocked = (gardenPlantsTotal ?? 0) >= achievement.requirement;
          } else if (achievement.id == 'garden_paradise') {
            shouldBeUnlocked = (gardenPlantsTotal ?? 0) >= achievement.requirement;
          } else {
            shouldBeUnlocked = (gardenPlantsStage4 ?? 0) >= achievement.requirement;
          }
          break;

        case AchievementType.special:
          if (achievement.id == 'pro_access') {
             shouldBeUnlocked = isPro ?? false;
          } else {
             shouldBeUnlocked = _unlockedAchievementIds.contains(achievement.id);
          }
          break;
      }

      final isCurrentlyUnlocked = _unlockedAchievementIds.contains(achievement.id);

      if (shouldBeUnlocked && !isCurrentlyUnlocked) {
        // New unlock!
        _unlockedAchievementIds.add(achievement.id);
        newlyUnlocked.add(achievement);
        hasChanges = true;
      }
    }

    if (hasChanges) {
      await _saveUnlockedAchievements();
      
      // Sync to cloud
      await StorageService().saveUnlockedAchievementsToCloud(_unlockedAchievementIds);
      
      notifyListeners();
    }

    return newlyUnlocked;
  }

  /// Manually unlock a special achievement
  Future<void> unlockSpecialAchievement(String achievementId) async {
    if (!_unlockedAchievementIds.contains(achievementId)) {
      _unlockedAchievementIds.add(achievementId);
      await _saveUnlockedAchievements();
      await StorageService().saveUnlockedAchievementsToCloud(_unlockedAchievementIds);
      notifyListeners();
    }
  }

  bool isUnlocked(String achievementId) {
    return _unlockedAchievementIds.contains(achievementId);
  }
}

class Achievement {
  final String id;
  final String emoji;
  final String name;
  final String description;
  final AchievementType type;
  final int requirement;

  Achievement(this.id, this.emoji, this.name, this.description, this.type, this.requirement);

  String get requirementText {
    switch (type) {
      case AchievementType.streak:
        return '$requirement-day streak';
      case AchievementType.points:
        return '$requirement points';
      case AchievementType.dreams:
        return '$requirement ${requirement == 1 ? 'dream' : 'dreams'}';
      case AchievementType.actions:
        return '$requirement ${requirement == 1 ? 'action' : 'actions'}';
      case AchievementType.completedDreams:
        return 'Complete $requirement ${requirement == 1 ? 'dream' : 'dreams'}';
      case AchievementType.travel:
        return '$requirement ${requirement == 1 ? 'memory' : 'memories'}';
      case AchievementType.countries:
        return '$requirement ${requirement == 1 ? 'country' : 'countries'}';
      case AchievementType.travelPhotos:
        return '$requirement ${requirement == 1 ? 'photo' : 'photos'}';

      case AchievementType.level:
        return 'Level $requirement';

      case AchievementType.journalEntries:
        return 'Write $requirement ${requirement == 1 ? 'entry' : 'entries'}';
      case AchievementType.todoItems:
        return 'Complete $requirement todo ${requirement == 1 ? 'item' : 'items'}';
      case AchievementType.gardenGrowth:
        if (id == 'garden_seed') return 'Grow $requirement ${requirement == 1 ? 'plant' : 'plants'}';
        if (id == 'garden_paradise') return 'Garden full of life';
        return 'Reach full bloom with $requirement ${requirement == 1 ? 'plant' : 'plants'}';

      case AchievementType.special:
        return 'Special action';
    }
  }
}

enum AchievementType {
  streak,
  points,
  dreams,
  actions,
  completedDreams,
  travel,
  countries,
  travelPhotos,

  level,
  journalEntries,
  todoItems,
  gardenGrowth,
  special,
}
