import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

import 'dart:async';
import '../models/travel_memory.dart';
import 'package:http/http.dart' as http;
import '../widgets/add_memory_sheet.dart';
import '../providers/app_state.dart';
import '../services/achievement_service.dart';
import 'achievement_completion_page.dart';
import '../utils/bloom_snackbar.dart';
import '../utils/pro_modal_utils.dart';


import '../widgets/custom_tab_switcher.dart';
import '../widgets/travel/map_tab_widget.dart';
import '../widgets/travel/places_tab_widget.dart';
import '../widgets/travel/stamps_tab_widget.dart';


class TravelScreen extends StatefulWidget {
  const TravelScreen({super.key});

  @override
  State<TravelScreen> createState() => _TravelScreenState();
}

class _TravelScreenState extends State<TravelScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<MapTabWidgetState> _mapTabKey = GlobalKey();
  static const String _accessToken = String.fromEnvironment(
    'MAPBOX_ACCESS_TOKEN',
    defaultValue: 'YOUR_MAPBOX_ACCESS_TOKEN_HERE',
  );  

  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _isProcessing = false;
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    if (_accessToken != "YOUR_MAPBOX_ACCESS_TOKEN_HERE" && _accessToken.isNotEmpty) {
      MapboxOptions.setAccessToken(_accessToken);
    }
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(_onSearchChanged);
  }

  AppState? _appState;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newAppState = Provider.of<AppState>(context, listen: false);
    if (_appState != newAppState) {
      _appState?.removeListener(_onAppStateChange);
      _appState = newAppState;
      _appState!.addListener(_onAppStateChange);
    }
  }

  void _onAppStateChange() async {
     // MapTabWidget handles its own updates, but we can trigger refresh to be safe if active
     if (_tabController.index == 0) {
        _mapTabKey.currentState?.reloadPins();
     }
  }

  void _onSearchChanged() {
    if (_searchController.text.isEmpty) {
      _startAutoCloseTimer();
    } else {
      _cancelAutoCloseTimer();
    }
  }

  void _startAutoCloseTimer() {
    _cancelAutoCloseTimer();
    if (_isSearching) {
       _searchTimer = Timer(const Duration(seconds: 10), () {
        if (mounted && _isSearching && _searchController.text.isEmpty) {
          setState(() {
            _isSearching = false;
            _searchController.clear();
          });
        }
      });
    }
  }

  void _cancelAutoCloseTimer() {
    _searchTimer?.cancel();
    _searchTimer = null;
  }

  @override
  void dispose() {
    _cancelAutoCloseTimer();
    _appState?.removeListener(_onAppStateChange);
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              onPressed: () {
                setState(() {
                  if (_isSearching) {
                    _isSearching = false;
                    _searchController.clear();
                    _cancelAutoCloseTimer();
                  } else {
                    _isSearching = true;
                    _startAutoCloseTimer();
                  }
                });
              },
            ),
            title: _isSearching
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      hintText: 'Search places...',
                      hintStyle: TextStyle(color: Theme.of(context).hintColor),
                      border: InputBorder.none,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search_rounded),
                        onPressed: () {
                           _searchPlace(_searchController.text);
                           FocusScope.of(context).unfocus();
                        },
                      ),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (value) {
                      _searchPlace(value);
                      // Don't close immediately so user can see result or refine
                      FocusScope.of(context).unfocus();
                    },
                  )
                : CustomTabSwitcher(
                    tabController: _tabController,
                    tabs: const ['Map', 'Places', 'Stamps'],
                    icons: const [Icons.public, Icons.place, Icons.local_activity_rounded],
                    width: 300,
                    height: 40,
                    isAppBarMode: true,
                  ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded),
                onPressed: _showAddPlaceBottomSheet,
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: TabBarView(
            physics: const NeverScrollableScrollPhysics(),
            controller: _tabController,
            children: [
              MapTabWidget(
                key: _mapTabKey,
                accessToken: _accessToken,
              ),
              const PlacesTabWidget(),
              StampsTabWidget(
                onSwitchTab: (index) => _tabController.animateTo(index),
              ),
            ],
          ),
        ),
        if (_isProcessing)
          Container(
            color: Colors.black.withOpacity(0.6),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                        BoxShadow(
                          color: Colors.cyanAccent.withOpacity(0.3),
                          blurRadius: 60,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                    child: const CircularProgressIndicator(
                      strokeWidth: 8,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }





  Future<void> _searchPlace(String query) async {
    if (query.isEmpty) return;
    if (_accessToken == "YOUR_MAPBOX_ACCESS_TOKEN_HERE" || _accessToken.isEmpty) {
      if (mounted) {
        BloomSnackBar.show(context, message: "Mapbox token required for search", icon: Icons.warning_amber_rounded);
      }
      return;
    }
    
    // setState(() => _isRotationPaused = true); // Handled by widget now

    final url = 'https://api.mapbox.com/geocoding/v5/mapbox.places/${Uri.encodeComponent(query)}.json?access_token=$_accessToken';
    
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List;
        
        if (features.isNotEmpty) {
          final center = features[0]['center']; // [lng, lat]
          final lng = (center[0] as num).toDouble();
          final lat = (center[1] as num).toDouble();
          
          if (_tabController.index != 0) {
            _tabController.animateTo(0);
          }
          
          _mapTabKey.currentState?.flyTo(lat, lng);
        } else {
             if (mounted) BloomSnackBar.show(context, message: "No places found", icon: Icons.error_outline);
        }
      } else {
        debugPrint("Mapbox Search Error: ${response.statusCode} ${response.body}");
        if (mounted) BloomSnackBar.show(context, message: "Search failed: ${response.statusCode}", isError: true);
      }
    } catch (e) {
      debugPrint("Search error: $e");
      if (mounted) BloomSnackBar.show(context, message: "Network error", isError: true);
    }
  }






  void _showAddPlaceBottomSheet({TravelMemory? existingMemory}) {
    if (existingMemory != null) {
      _editMemory(existingMemory);
      return;
    }

    // Check limit
    final appState = Provider.of<AppState>(context, listen: false);
    if (!appState.isPro && appState.travelMemories.length >= 3) {
      ProModalUtils.showTravelLimitModal(context);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return AddMemorySheet(
          onAdd: (placeName, lat, lng, note, photos, isPublic, {id}) async {
             // 1. Show "adding.." snackbar
             BloomSnackBar.show(context, message: "Adding memory...", icon: Icons.sync);
             
             // 2. Add Memory & Get Achievements
             List<Achievement> newAchievements = [];
             try {
               newAchievements = await Provider.of<AppState>(context, listen: false).addTravelMemory(
                 placeName, lat, lng, id: id, memory: "", note: note, photos: photos, isPublic: isPublic
               );
               
               if (mounted) {
                 BloomSnackBar.show(context, message: "Memory uploaded successfully!", icon: Icons.check_circle, iconColor: Colors.green);
               }
             } catch (e) {
               if (mounted) {
                  BloomSnackBar.show(context, message: "Failed to add memory: $e", isError: true);
               }
               rethrow;
             }

             // 3. Background tasks
             if (mounted) setState(() => _isProcessing = true);
             try {
               await _mapTabKey.currentState?.reloadPins();
               _mapTabKey.currentState?.flyTo(lat, lng);
             } finally {
               if (mounted) setState(() => _isProcessing = false);
             }

             if (newAchievements.isNotEmpty) {
               Future.microtask(() async {
                 for (final achievement in newAchievements) {
                   if (mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AchievementCompletionPage(achievement: achievement),
                          fullscreenDialog: true,
                        ),
                      );
                     if (newAchievements.length > 1) {
                       await Future.delayed(const Duration(seconds: 2));
                     }
                   }
                 }
               });
             }
           },
        );
      },
    );
  }



  void _editMemory(TravelMemory memory) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return AddMemorySheet(
          memoryToEdit: memory,
          onAdd: (placeName, lat, lng, note, photos, isPublic, {id}) async {
             try {
               final updated = TravelMemory(
                 id: memory.id,
                 place: placeName,
                 latitude: lat == 0.0 ? memory.latitude : lat,
                 longitude: lng == 0.0 ? memory.longitude : lng,
                 visitedDate: memory.visitedDate,
                 memory: "", 
                 note: note, 
                 photos: photos,
                 isPublic: isPublic
               );
               
               await Provider.of<AppState>(context, listen: false).updateTravelMemory(updated);
               if (mounted) setState(() => _isProcessing = true);
               try {
                 await _mapTabKey.currentState?.reloadPins();
               } finally {
                 if (mounted) setState(() => _isProcessing = false);
               }
               
               if (mounted) {
                 BloomSnackBar.show(context, message: "Memory updated successfully", icon: Icons.check_circle_outline, iconColor: Colors.green);
               }
             } catch (e) {
               if (mounted) {
                 BloomSnackBar.show(context, message: "Failed to update memory: $e", isError: true);
               }
               rethrow;
             }
          },
        );
      },
    );
  }














}
