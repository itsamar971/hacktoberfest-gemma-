import 'package:confetti/confetti.dart';
import '../services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/app_state.dart';
import '../models/challenge_step.dart';
import '../models/dream.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/custom_tab_switcher.dart';
import 'home_tab_screen.dart';
import 'explore_tab_screen.dart';
import '../services/auth_service.dart';
import 'customer_center_screen.dart';
import 'achievement_completion_page.dart';
import '../utils/pro_modal_utils.dart';
import '../utils/bloom_snackbar.dart';
import '../services/gemini_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _tabController = TabController(length: 2, vsync: this);
    
    // Check for streak achievements after frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
       final newAchievements = await Provider.of<AppState>(context, listen: false).trackActivity();
       
       if (mounted && newAchievements.isNotEmpty) {
           for (final achievement in newAchievements) {
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

  @override
  void dispose() {
    _confettiController.dispose();
    _tabController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.white, // allow theme to handle this
      appBar: AppBar(
        // backgroundColor: Colors.white, // allow theme to handle this
        elevation: 0,
        titleSpacing: 20,
        centerTitle: false,
        title: Consumer<AppState>(
          builder: (context, appState, child) {
            return GestureDetector(
              onTap: () => ProModalUtils.showProStatusModal(context, appState.isPro),
              behavior: HitTestBehavior.opaque,
              child: appState.isPro
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _AnimatedGradientLogo(),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B9D).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Pro',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF6B9D),
                            ),
                          ),
                        ),
                      ],
                    )
                  : _AnimatedGradientLogo(),
            );
          },
        ),
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTabSwitcher(
                tabController: _tabController,
                tabs: const ["Home", "Explore"],
                icons: const [Icons.home_rounded, Icons.explore_rounded],
                width: 180,
                height: 40,
                isAppBarMode: true,
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _showUserProfileBottomSheet(context),
                child: StreamBuilder<AuthState>(
                  stream: AuthService().authStateChanges,
                  builder: (context, snapshot) {
                    final user = AuthService().currentUser;
                    final avatarUrl = user?.userMetadata?['avatar_url'] as String?;
                    
                    return Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).primaryColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 17,
                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                        backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                            ? NetworkImage(avatarUrl)
                            : null,
                        child: (avatarUrl == null || avatarUrl.isEmpty)
                            ? Icon(Icons.person_rounded, size: 20, color: Theme.of(context).primaryColor)
                            : null,
                      ),
                    );
                  }
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ],
      ),
      body: ConfettiOverlay(
        controller: _confettiController,
        child: SafeArea(
          child: Column(
            children: [
               Expanded(
                 child: TabBarView(
                   controller: _tabController,
                   children: [
                      HomeTabScreen(
                        onChallengeCardTap: () => _tabController.animateTo(0),
                        onConfettiPlay: () => _confettiController.play(),
                      ),
                     const ExploreTabScreen(),
                   ],
                 ),
               )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLetsDoItTab(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        if (appState.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 32),
              Expanded(child: _buildDailyFocus(context, appState)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEverydayMotivation(BuildContext context) {
     final quotes = [
        "Believe you can and you're halfway there.",
        "Your only limit is your mind.",
        "Small steps every day.",
        "You are capable of amazing things.",
        "Dream big, start small."
     ];
     // Simple random quote for now
     final quote = quotes[DateTime.now().day % quotes.length];

     return SingleChildScrollView(
       padding: const EdgeInsets.all(24),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.stretch,
         children: [
           // Quote Card
           Container(
             padding: const EdgeInsets.all(32),
             decoration: BoxDecoration(
               gradient: const LinearGradient(
                 colors: [Color(0xFF8EC5FC), Color(0xFFE0C3FC)], // Mesh-like soft gradient
                 begin: Alignment.topLeft,
                 end: Alignment.bottomRight,
               ),
               borderRadius: BorderRadius.circular(30),
               boxShadow: [
                  BoxShadow(color: Colors.purple.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))
               ]
             ),
             child: Column(
               children: [
                 const Icon(Icons.format_quote_rounded, size: 40, color: Colors.white),
                 const SizedBox(height: 16),
                 Text(
                   quote,
                   textAlign: TextAlign.center,
                   style: const TextStyle(
                     fontSize: 24,
                     height: 1.3,
                     fontWeight: FontWeight.bold,
                     fontStyle: FontStyle.italic,
                     color: Colors.white,
                     shadows: [Shadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                   ),
                 ),
               ],
             ),
           )
           .animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0, duration: 600.ms),
           
           const SizedBox(height: 32),
           
           // Affirmations
           Text("Daily Affirmations", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
           const SizedBox(height: 16),
           _buildAffirmationTile(context, "I am enough.", 0),
           _buildAffirmationTile(context, "I choose happiness.", 1),
           _buildAffirmationTile(context, "I am creating the life I want.", 2),
           
           const SizedBox(height: 32),
           // Animated Breathing Widget
            Container(
             padding: const EdgeInsets.all(24),
             decoration: BoxDecoration(
               color: Theme.of(context).cardColor,
               borderRadius: BorderRadius.circular(30),
               boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 5))
               ]
             ),
             child: Row(
               children: [
                 Container(
                   padding: const EdgeInsets.all(12),
                   decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.1), shape: BoxShape.circle),
                   child: Icon(Icons.air, color: Theme.of(context).colorScheme.primary),
                 )
                 .animate(onPlay: (controller) => controller.repeat(reverse: true))
                 .scale(begin: const Offset(1,1), end: const Offset(1.2, 1.2), duration: 2000.ms, curve: Curves.easeInOut),
                 
                 const SizedBox(width: 16),
                 Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                      const Text("Take a breath", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("Inhale... Exhale...", style: TextStyle(color: Colors.grey.shade600)),
                   ],
                 )
               ],
             ),
           ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1, end: 0),
         ],
       ),
     );
  }

  Widget _buildAffirmationTile(BuildContext context, String text, int index) {
    // Simple state tracking for demo purposes in this build method is messy, 
    // but for MVP visual polish we'll just make them interactive visually.
    return StatefulBuilder(
      builder: (context, setState) {
        bool checked = false; // Local state for the tile
        return GestureDetector(
          onTap: () => setState(() => checked = !checked),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: checked ? Colors.green.withOpacity(0.1) : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: checked ? Colors.green.shade200 : Colors.grey.shade100),
              boxShadow: [
                 BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))
              ]
            ),
            child: Row(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: checked 
                     ? const Icon(Icons.check_circle, color: Colors.green, key: ValueKey('checked'))
                     : const Icon(Icons.circle_outlined, color: Colors.grey, key: ValueKey('unchecked')),
                ),
                const SizedBox(width: 16),
                Text(
                   text, 
                   style: TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.w600,
                      color: checked ? Colors.green.shade800 : Colors.black87,
                      decoration: checked ? TextDecoration.lineThrough : null,
                      decorationColor: Colors.green.shade200
                   )
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideX();
      }
    );
  }

  Widget _buildHeader(BuildContext context) {
    final now = DateTime.now();
    
    return StreamBuilder<AuthState>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        final user = AuthService().currentUser; // Get latest user object
        final metadataName = user?.userMetadata?['display_name'] as String?;
        
        final displayName = (metadataName != null && metadataName.trim().isNotEmpty) 
            ? metadataName 
            : (user?.email?.split('@').first ?? 'Traveler'); // Fallback to email prefix

        String greeting = _getGreeting();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                  Text(
                    DateFormat('EEEE, MMM d').format(now).toUpperCase(),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                          letterSpacing: 1.2,
                        ),
                  ),
               ]
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                CircleAvatar(
                   radius: 28,
                   backgroundColor: Theme.of(context).colorScheme.surface,
                   child: Icon(Icons.person_rounded, size: 32, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        displayName,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        );
      }
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning,';
    } else if (hour < 17) {
      return 'Good Afternoon,';
    } else {
      return 'Good Evening,';
    }
  }

  Widget _buildDailyFocus(BuildContext context, AppState appState) {
    ChallengeStep? todaysTask;
    String? relatedDreamTitle;
    String? dreamId;
    
    // Logic: Find the earliest INCOMPLETE step from ALL dreams.
    // If that step's date is today or in the past -> Show it (Catch up or Today).
    // If that step's date is in the future -> Show "All Caught Up" (Locked).
    
    // 1. Flatten all steps with metadata
    final allSteps = <_StepWithMetadata>[];
    for (var dream in appState.dreams) {
       for (var step in dream.steps) {
          if (!step.isCompleted) {
             allSteps.add(_StepWithMetadata(step, dream.title, dream.id));
          }
       }
    }
    
    // 2. Sort by scheduledDate
    allSteps.sort((a, b) {
       final dateA = a.step.scheduledDate ?? DateTime.now(); // Fallback if null
       final dateB = b.step.scheduledDate ?? DateTime.now();
       return dateA.compareTo(dateB);
    });

    // 3. Pick the first one
    if (allSteps.isNotEmpty) {
       final bestCandidate = allSteps.first;
       final scheduledDate = bestCandidate.step.scheduledDate;
       
       if (scheduledDate != null) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          // If scheduled for future (> today), we are caught up
          if (scheduledDate.isAfter(today)) {
             todaysTask = null; 
          } else {
             // Scheduled for today or past -> Show it
             todaysTask = bestCandidate.step;
             relatedDreamTitle = bestCandidate.dreamTitle;
             dreamId = bestCandidate.dreamId;
          }
       } else {
          // No date? Show it just in case
          todaysTask = bestCandidate.step;
          relatedDreamTitle = bestCandidate.dreamTitle;
          dreamId = bestCandidate.dreamId;
       }
    }

    if (todaysTask == null) {
      if (appState.dreams.isEmpty) {
        return _buildEmptyStateCard(context);
      } else {
        // Show progress of the first dream
        return _buildContinueChallengeCard(context, appState.dreams.first);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "TODAY'S MICRO-ACTION",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
               color: Theme.of(context).cardColor,
               borderRadius: BorderRadius.circular(40), // Circular UI
               boxShadow: [
                  BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.1), blurRadius: 30, offset: const Offset(0, 10))
               ]
            ),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          relatedDreamTitle?.toUpperCase() ?? '',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                       Icon(
                          Icons.timer_outlined,
                          size: 40,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        '${todaysTask.durationMinutes} MIN',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                           color: Theme.of(context).colorScheme.primary.withOpacity(0.5)
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        todaysTask.title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                           height: 1.3
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        height: 64,
                        child: ElevatedButton(
                          onPressed: () {
                            appState.toggleStepCompletion(dreamId!, todaysTask!.id);
                            _confettiController.play();
                          },
                           style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32))
                           ),
                          child: const Text("I did it!"),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: () {
                          BloomSnackBar.show(
                            context,
                            message: "We'll skip this one for now! (Mock implementation)",
                            icon: Icons.refresh_rounded,
                          );
                        },
                        icon: Icon(Icons.refresh_rounded, size: 18, color: Theme.of(context).colorScheme.outline),
                        label: Text(
                          "Give me something easier",
                          style: TextStyle(color: Theme.of(context).colorScheme.outline),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                   top: 2,
                   right: 2,
                   child: IconButton(
                      onPressed: () => _showAiInsight(context, "${todaysTask!.title}. Give me a strategy tip for this."),
                      icon: Container(
                         padding: const EdgeInsets.all(8),
                         decoration: BoxDecoration(
                           color: Colors.purple.withOpacity(0.1),
                           shape: BoxShape.circle,
                         ),
                         child: const Icon(Icons.auto_awesome_rounded, color: Colors.purple, size: 20),
                      ),
                   ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _showAiInsight(BuildContext context, String text) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                 BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))
              ]
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "AI Strategy Tip",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: FutureBuilder<String>(
                    future: GeminiService().getJournalInsight(
                      "Daily focus context: $text\nGive an inspiring, actionable 2-sentence productivity strategy tip for an ambitious woman.",
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 16),
                              Text(
                                "Thinking...",
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      if (snapshot.hasError) {
                         return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.withOpacity(0.5)),
                                const SizedBox(height: 16),
                                Text(
                                  "Couldn't get a tip right now.",
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      
                      final content = snapshot.data ?? "Focus on one high-impact micro-step today.";

                      return SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(24),
                        child: MarkdownBody(
                          data: content,
                          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                            p: const TextStyle(fontSize: 16, height: 1.5),
                             h1: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                            h2: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                            h3: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            blockquote: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                            blockquoteDecoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border(left: BorderSide(color: Colors.purple.withOpacity(0.5), width: 4)),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyStateCard(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rocket_launch_rounded, size: 80, color: Theme.of(context).colorScheme.surfaceVariant),
          const SizedBox(height: 24),
          Text(
            "Start your journey",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            "Add a dream in the Dreams tab to get started.",
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContinueChallengeCard(BuildContext context, Dream dream) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "CONTINUE YOUR JOURNEY",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
        const SizedBox(height: 16),
        Container(
           width: double.infinity,
           padding: const EdgeInsets.all(24),
           decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Theme.of(context).cardColor 
                  : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                 BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 4))
              ]
           ),
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   Expanded(
                     child: Text(
                       dream.title,
                       style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                         fontWeight: FontWeight.bold,
                       ),
                       maxLines: 1,
                       overflow: TextOverflow.ellipsis,
                     ),
                   ),
                   Container(
                     padding: const EdgeInsets.all(8),
                     decoration: BoxDecoration(
                       color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                       shape: BoxShape.circle,
                     ),
                     child: Icon(Icons.arrow_forward_rounded, color: Theme.of(context).colorScheme.primary),
                   )
                 ],
               ),
               const SizedBox(height: 16),
               ClipRRect(
                 borderRadius: BorderRadius.circular(8),
                 child: LinearProgressIndicator(
                   value: dream.progress,
                   minHeight: 8,
                   backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                   valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                 ),
               ),
               const SizedBox(height: 12),
               Text(
                 "${(dream.progress * 100).toInt()}% Completed (${dream.completedSteps}/${dream.totalSteps} steps)",
                 style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                   color: Theme.of(context).colorScheme.onSurfaceVariant,
                 ),
               )
             ],
           ),
        ),
      ],
    );
  }



  Future<void> _showUserProfileBottomSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // Allow keyboard to push sheet up
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: const UserProfileSheet(),
      ),
    );
    // Refresh the Home screen to show updated profile data
    if (mounted) {
      setState(() {});
    }
  }
}

class UserProfileSheet extends StatefulWidget {
  const UserProfileSheet({super.key});

  @override
  State<UserProfileSheet> createState() => _UserProfileSheetState();
}

class _UserProfileSheetState extends State<UserProfileSheet> {
  final _nameController = TextEditingController();
  final _instaController = TextEditingController();
  bool _isEditingName = false;
  bool _isLoading = false;
  File? _selectedImage;
  String? _currentAvatarUrl;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = AuthService().currentUser;
    final appState = Provider.of<AppState>(context, listen: false);
    final metadataName = user?.userMetadata?['display_name'] as String?;
    final avatarUrl = user?.userMetadata?['avatar_url'] as String?;
    
    _nameController.text = (metadataName != null && metadataName.trim().isNotEmpty) 
        ? metadataName 
        : (user?.email?.split('@').first ?? 'Traveler');
    _instaController.text = appState.instagramUsername ?? '';
    _currentAvatarUrl = avatarUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _instaController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 70);
      if (image != null) {
        setState(() => _selectedImage = File(image.path));
        await _saveProfileChanges(updateImage: true);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        BloomSnackBar.show(
          context,
          message: 'Failed to pick image: $e',
          icon: Icons.error_outline_rounded,
        );
      }
    }
  }

  Future<void> _saveProfileChanges({bool updateImage = false, String? specificAvatarUrl}) async {
    setState(() => _isLoading = true);
    try {
      debugPrint('Updating profile with name: ${_nameController.text.trim()}');

      // Update metadata and get the *fresh* user object directly from the response
      final response = await AuthService().updateUserMetadata(
        displayName: _nameController.text.trim(),
        avatarUrl: specificAvatarUrl,
      );
      
      final updatedUser = response.user;
      
      if (updatedUser != null) {
          // Update local state with the CONFIRMED new data from server
          var newName = updatedUser.userMetadata?['display_name'] as String?;
          
          // Double check if the immediate response didn't have it (sometime happens with Supabase w/o session refresh)
          if (newName == null || newName != _nameController.text.trim()) {
             final refreshedUser = AuthService().currentUser;
             newName = refreshedUser?.userMetadata?['display_name'] as String?;
             debugPrint('⚠️ Immediate response might be stale. Refreshed user has: $newName');
          }

          if (newName != null) {
              _nameController.text = newName;
          }
          
          final newAvatar = updatedUser.userMetadata?['avatar_url'] as String?;
          if (newAvatar != null) {
             _currentAvatarUrl = newAvatar;
             // If we saved a specific URL, clear the local file selection to show the network image
             if (specificAvatarUrl != null) {
                _selectedImage = null;
             }
          }
          
          await StorageService().syncProfile();
      }
      
      if (mounted) {
        BloomSnackBar.show(
          context,
          message: 'Profile updated successfully!',
          icon: Icons.check_circle_rounded,
          iconColor: Colors.green, // Keep success green
        );
        setState(() {
          if (!updateImage) _isEditingName = false;
        });
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      if (mounted) {
        BloomSnackBar.show(
          context,
          message: 'Failed to update profile: $e',
          icon: Icons.error_outline_rounded,
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  final List<String> _avatarOptions = [
    'https://img.freepik.com/premium-vector/portrait-beautiful-women-round-frame-avatar-female-character-isolated-white-background_559729-213.jpg',
    'https://img.freepik.com/premium-vector/portrait-beautiful-women-round-frame-avatar-female-character-isolated-white-background_559729-216.jpg',
    'https://img.freepik.com/premium-vector/portrait-beautiful-women-round-frame-avatar-female-character-isolated-white-background_559729-215.jpg',
    'https://img.freepik.com/premium-vector/portrait-beautiful-women-round-frame-avatar-female-character-isolated-white-background_559729-211.jpg',
  ];

  Future<void> _showAvatarSelectionBottomSheet() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark 
              ? Theme.of(context).cardColor 
              : Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Choose Avatar',
                  style: TextStyle(
                    fontSize: 20, 
                    fontWeight: FontWeight.bold
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _pickImage();
                  },
                  icon: Icon(Icons.photo_library_rounded, size: 18, color: Theme.of(context).primaryColor),
                  label: Text(
                    'Gallery',
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _avatarOptions.length,
              itemBuilder: (context, index) {
                final url = _avatarOptions[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _handleAvatarSelection(url);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.white24 
                            : Colors.grey.shade200
                      ),
                    ),
                    child: ClipOval(
                      child: Image.network(
                        url,
                        fit: BoxFit.cover,
                        loadingBuilder: (ctx, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(child: Icon(Icons.person, color: Colors.grey));
                        },
                        errorBuilder: (ctx, error, stackTrace) => 
                            const Center(child: Icon(Icons.error_outline, size: 20, color: Colors.grey)),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAvatarSelection(String url) async {
      setState(() {
          _selectedImage = null; // Clear local file if any
          _currentAvatarUrl = url;
      });
      await _saveProfileChanges(updateImage: true, specificAvatarUrl: url);
  }

  Widget _buildWidgetsSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => _showHomeWidgetsBottomSheet(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.dashboard_rounded, size: 20, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    "Home Widgets",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Customize cards on your home screen",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded, 
              color: isDark ? Colors.white24 : Colors.grey.shade400
            ),
          ],
        ),
      ),
    );
  }

  void _showHomeWidgetsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer<AppState>(
        builder: (context, appState, child) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Theme.of(context).cardColor : Colors.white,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Home Widgets",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "Choose which cards to display on your home screen.",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 24),
                _buildWidgetToggle(
                  context,
                  title: "Daily Motivation",
                  value: appState.showMotivation,
                  onChanged: (val) => appState.setShowMotivation(val),
                ),
                _buildWidgetToggle(
                  context,
                  title: "Bloom Garden",
                  value: appState.showGarden,
                  onChanged: (val) => appState.setShowGarden(val),
                ),
                _buildWidgetToggle(
                  context,
                  title: "Achievements",
                  value: appState.showAchievements,
                  onChanged: (val) => appState.setShowAchievements(val),
                ),
                _buildWidgetToggle(
                  context,
                  title: "World Map",
                  value: appState.showMap,
                  onChanged: (val) => appState.setShowMap(val),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPublicProfileSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.public_rounded, size: 18, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  const Text(
                    "PUBLIC PROFILE",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _instaController,
                decoration: InputDecoration(
                  labelText: "Instagram Username",
                  hintText: "username",
                  prefixText: "@ ",
                  helperText: "Visible on your public profile memories",
                  helperStyle: const TextStyle(fontSize: 11),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) => appState.setInstagramUsername(value.trim()),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWidgetToggle(BuildContext context, {required String title, required bool value, required ValueChanged<bool> onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).primaryColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        dense: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final email = user?.email ?? 'No email';

    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Theme.of(context).cardColor 
            : Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 24),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white24 
                  : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Profile Header with Avatar & Pencil
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.2), width: 2),
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  backgroundImage: _selectedImage != null 
                      ? FileImage(_selectedImage!) 
                      : (_currentAvatarUrl != null ? NetworkImage(_currentAvatarUrl!) as ImageProvider : null),
                  child: (_selectedImage == null && _currentAvatarUrl == null)
                      ? Text(
                          _nameController.text.isNotEmpty ? _nameController.text.characters.first.toUpperCase() : '?',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        )
                      : null,
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _showAvatarSelectionBottomSheet,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Theme.of(context).scaffoldBackgroundColor 
                          : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
                      ],
                    ),
                    child: Icon(Icons.edit_rounded, size: 14, color: Theme.of(context).primaryColor),
                  ),
                ),
              ),
              Consumer<AppState>(
                builder: (context, appState, child) {
                  if (!appState.isPro) return const SizedBox.shrink();
                  return Positioned(
                    bottom: 0,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B9D),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF6B9D).withOpacity(0.3),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Display Name with Edit Pencil
          if (_isEditingName)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      autofocus: true,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      onSubmitted: (_) => _saveProfileChanges(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    onPressed: () => _saveProfileChanges(),
                  ),
                ],
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _nameController.text,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _isEditingName = true),
                  child: Icon(
                    Icons.edit_rounded, 
                    size: 16, 
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.white38 
                        : Colors.grey.shade400
                  ),
                ),
              ],
            ),
            
          Text(
            email,
            style: TextStyle(
              fontSize: 14, 
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white54 
                  : Colors.grey.shade500
            ),
          ),
          const SizedBox(height: 32),
          
          _buildPublicProfileSection(context),
          const SizedBox(height: 16),
          
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  minHeight: 6,
                  backgroundColor: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white10 
                      : Colors.grey.shade100,
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                ),
              ),
            ),

          // Actions

          
          const SizedBox(height: 8),
          _buildWidgetsSection(context),
          
          const Divider(height: 32),
          
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 32),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context); // Close sheet
                  await AuthService().signOut();
                  if (context.mounted) {
                    // Navigate to AuthGateway and remove all previous routes
                     Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                  }
                },
                icon: const Icon(Icons.logout_rounded, color: Colors.red),
                label: const Text("Log Out", style: TextStyle(color: Colors.red)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.red.withOpacity(0.1) 
                      : Colors.red.shade50,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildProfileOption(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).iconTheme.color?.withOpacity(0.7)),
            const SizedBox(width: 16),
            Text(
              title, 
              style: TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              )
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right_rounded, 
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white24 
                  : Colors.grey.shade400
            ),
          ],
        ),
      ),
    );
  }
}

class _StepWithMetadata {
  final ChallengeStep step;
  final String dreamTitle;
  final String dreamId;
  
  _StepWithMetadata(this.step, this.dreamTitle, this.dreamId);
}

class _AnimatedGradientLogo extends StatefulWidget {
  @override
  State<_AnimatedGradientLogo> createState() => _AnimatedGradientLogoState();
}

class _AnimatedGradientLogoState extends State<_AnimatedGradientLogo> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final baseColor = Theme.of(context).textTheme.titleLarge?.color ?? Colors.black;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            final slide = _controller.value;
            // Slide from -2 to 2 (approx 4 screen units)
            // Center of the gradient shift
            final double offset = -2.0 + (slide * 4.0);
            
            // Define vector for the gradient (length of the transition)
            // Keep it relatively short so the shine is visible
            const double vectorLen = 1.0; 
            
            return LinearGradient(
              colors: [
                baseColor,
                baseColor,
                primaryColor.withOpacity(0.8),
                baseColor,
                baseColor,
              ],
              stops: const [0.0, 0.45, 0.5, 0.55, 1.0],
              begin: Alignment(offset - vectorLen, offset - vectorLen),
              end: Alignment(offset + vectorLen, offset + vectorLen),
              // tileMode: TileMode.clamp, // Default, effectively extends baseColor
            ).createShader(bounds);
          },
          child: SvgPicture.asset(
            'assets/images/bloom.svg',
            height: 24,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
        );
      },
    );
  }
}
