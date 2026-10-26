import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/she_stacks/index.dart';
import '../providers/app_state.dart';
import 'package:provider/provider.dart';
import 'achievement_completion_page.dart';
import '../utils/pro_modal_utils.dart';

class SheStacksScreen extends StatefulWidget {
  const SheStacksScreen({super.key});

  @override
  State<SheStacksScreen> createState() => _SheStacksScreenState();
}

class _SheStacksScreenState extends State<SheStacksScreen> {
  void _handleNegotiationComplete() {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.recordNegotiationCompletion().then((newAchievements) {
      if (newAchievements.isNotEmpty) {
        for (var achievement in newAchievements) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AchievementCompletionPage(achievement: achievement),
              fullscreenDialog: true,
            ),
          );
        }
      }
    });
  }



  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0F1115) : const Color(0xFFF8F9FB),
          body: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  _buildSliverAppBar(context),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // const SizedBox(height: 16), // Removed for tighter spacing
                          _buildLessonArcade(context, appState),
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 110.0,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: const EdgeInsets.only(bottom: 16),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              "SHE STACKS",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "Navigate the world of wealth",
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildLessonArcade(BuildContext context, AppState appState) {
    final isLocked = !appState.isPro;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
      mainAxisSpacing: 20,
      crossAxisSpacing: 20,
      childAspectRatio: 0.8,
      children: [
        _buildLessonCard(
          context,
          title: "She Venture",
          subtitle: "Strategic Merging",
          icon: Icons.hub_rounded,
          color: Colors.purpleAccent,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SheVentureGame(onComplete: (xp) {
                  appState.trackGameCompletion("She Venture");
                }),
                fullscreenDialog: true,
              ),
            );
          },
          xp: 750,
        ),
        _buildLessonCard(
          context,
          title: "Negotiation Lab",
          subtitle: "The 6-Figure Ask",
          icon: Icons.chat_bubble_rounded,
          color: Theme.of(context).colorScheme.primary,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NegotiationLabModal(onComplete: _handleNegotiationComplete),
                fullscreenDialog: true,
              ),
            );
          },
          xp: 250,
        ),
        _buildLessonCard(
          context,
          title: "Safety Shield",
          subtitle: "Financial Boundaries",
          icon: Icons.security_rounded,
          color: Colors.blueGrey,
          onTap: () => _startSafetyShield(context, appState),
          xp: 400,
        ),
        _buildLessonCard(
          context,
          title: "Money Flow",
          subtitle: "Values Budgeting",
          icon: Icons.account_balance_wallet_rounded,
          color: Colors.greenAccent,
          isLocked: isLocked,
          onTap: () => _startMoneyFlow(context, appState),
          xp: 300,
        ),
        _buildLessonCard(
          context,
          title: "Wealth Garden",
          subtitle: "Compound Interest",
          icon: Icons.spa_rounded,
          color: Colors.cyan,
          isLocked: isLocked,
          onTap: () => _startModularGame(context, WealthGardenModal(onComplete: (xp) {
            appState.trackGameCompletion("Wealth Garden");
          })),
          xp: 500,
        ),
        _buildLessonCard(
          context,
          title: "Inflation Trip",
          subtitle: "Money Time Travel",
          icon: Icons.history_toggle_off_rounded,
          color: Colors.redAccent,
          isLocked: isLocked,
          onTap: () => _startModularGame(context, InflationTripModal(onComplete: (xp) {
            appState.trackGameCompletion("Inflation Trip");
          })),
          xp: 300,
        ),
        _buildLessonCard(
          context,
          title: "Tax Waterfall",
          subtitle: "How Brackets Work",
          icon: Icons.water_drop_rounded,
          color: Colors.orange,
          isLocked: isLocked,
          onTap: () => _startModularGame(context, TaxWaterfallModal(onComplete: (xp) {
            appState.trackGameCompletion("Tax Waterfall");
          })),
          xp: 450,
        ),
        _buildLessonCard(
          context,
          title: "Founder Finance",
          subtitle: "Side-Hustle Logic",
          icon: Icons.rocket_launch_rounded,
          color: Colors.deepOrangeAccent,
          isLocked: isLocked,
          onTap: () => _startFounderFinance(context, appState),
          xp: 600,
        ),
        _buildLessonCard(
          context,
          title: "Longevity Fund",
          subtitle: "Plan for 100 Years",
          icon: Icons.hourglass_top_rounded,
          color: Colors.pinkAccent,
          isLocked: isLocked,
          onTap: () => _startModularGame(context, LongevityFundModal(onComplete: (xp) {
            appState.trackGameCompletion("Longevity Fund");
          })),
          xp: 600,
        ),
        _buildLessonCard(
          context,
          title: "Mindset Mirror",
          subtitle: "Psychology & Spend",
          icon: Icons.face_retouching_natural_rounded,
          color: Colors.indigoAccent,
          isLocked: isLocked,
          onTap: () => _startMindsetMirror(context, appState),
          xp: 500,
        ),
        _buildLessonCard(
          context,
          title: "Gap Visualizer",
          subtitle: "Career Break Sync",
          icon: Icons.pause_circle_filled_rounded,
          color: Colors.amber,
          isLocked: isLocked,
          onTap: () => _startModularGame(context, GapVisualizerModal(onComplete: (xp) {
            appState.trackGameCompletion("Gap Visualizer");
          })),
          xp: 450,
        ),
      ],
    );
  }

  Widget _buildLessonCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required int xp,
    bool isLocked = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Grey out if locked
    final displayColor = isLocked ? Colors.grey : color;
    final displayIcon = isLocked ? Icons.lock_outline_rounded : icon;

    return GestureDetector(
      onTap: isLocked 
          ? () => ProModalUtils.showProStatusModal(context, false)
          : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? displayColor.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isLocked 
                ? (isDark ? Colors.white10 : Colors.grey.shade200)
                : (isDark ? displayColor.withOpacity(0.3) : displayColor.withOpacity(0.1)),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: displayColor.withOpacity(isLocked ? 0.02 : 0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  displayIcon,
                  size: 100,
                  color: displayColor.withOpacity(0.05),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: displayColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isLocked ? Icons.lock_rounded : icon, 
                        color: displayColor, 
                        size: 24
                      ),
                    ),
                    const Spacer(),
                    Container(
                      decoration: isLocked ? BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ) : null,
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: isLocked ? Colors.grey.shade400 : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isLocked ? "Pro to Unlock" : subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: isLocked ? Colors.grey.shade400 : Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                  ],
                ),
              ),
              if (isLocked)
                Positioned.fill(
                  child: Container(
                    color: Colors.white.withOpacity(0.1), // Optional extra overlay
                  ),
                ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9)),
    );
  }

  // --- Modular Game Launcher ---
  void _startModularGame(BuildContext context, Widget modal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => modal,
    );
  }

  // --- New Game Launchers ---
  void _startMoneyFlow(BuildContext context, AppState appState) {
    _startModularGame(context, MoneyFlowModal(onComplete: (xp) {
      appState.trackGameCompletion("Money Flow");
    }));
  }

  void _startFounderFinance(BuildContext context, AppState appState) {
    _startModularGame(context, FounderFinanceModal(onComplete: (xp) {
      appState.trackGameCompletion("Founder Finance");
    }));
  }


  void _startSafetyShield(BuildContext context, AppState appState) {
    _startModularGame(context, SafetyShieldModal(onComplete: (xp) {
      appState.trackGameCompletion("Safety Shield");
    }));
  }

  void _startMindsetMirror(BuildContext context, AppState appState) {
    _startModularGame(context, MindsetMirrorModal(onComplete: (xp) {
      appState.trackGameCompletion("Mindset Mirror");
    }));
  }
}
