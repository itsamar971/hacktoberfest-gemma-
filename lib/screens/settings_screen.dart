import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/auth_service.dart';
import '../screens/customer_center_screen.dart';
import '../screens/faq_screen.dart';
import '../utils/bloom_snackbar.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Customize Bloom", 
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color,
          )
        ),
        backgroundColor: Colors.transparent, // Transparent to show scaffold background
        elevation: 0,
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          return ListView(
            padding: const EdgeInsets.all(16), // Tighter padding for card layout
            children: [
              _buildSubscriptionSection(context),
              const SizedBox(height: 16),
              
              _buildCard(
                context,
                title: "Appearance",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildThemeToggle(context, appState),
                    const SizedBox(height: 24),
                    Text("Accent Color", style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildColorPicker(context, appState),
                    const SizedBox(height: 24),
                    Text("Season", style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildSeasonToggle(context, appState),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              _buildCard(
                context,
                title: "Readability",
                child: Column(
                  children: [
                    _buildTextScaleSlider(context, appState),
                    const SizedBox(height: 16),
                    // Preview box inside the readability card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                           color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.black.withOpacity(0.3) 
                              : Colors.grey.shade50,
                           borderRadius: BorderRadius.circular(16),
                           border: Border.all(
                             color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.white.withOpacity(0.1) 
                                : Colors.grey.shade100
                           ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Preview", style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey)),
                            const SizedBox(height: 8),
                            Text(
                              "This is how your text will look.",
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              _buildCard(
                context,
                title: "Support",
                child: Column(
                  children: [
                    _buildSettingsTile(
                      context,
                      icon: Icons.help_outline_rounded,
                      title: "FAQ & Help",
                      subtitle: "Learn about core features",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const FaqScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              _buildCard(
                context,
                title: "Account",
                child: _buildLogoutButton(context),
              ),
              const SizedBox(height: 100),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCard(BuildContext context, {required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.white.withOpacity(0.05) 
              : Colors.grey.shade100
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white70 
                  : Colors.black, // Adapt title color
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildSeasonToggle(BuildContext context, AppState appState) {
    return Container(
      height: 56,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.black.withOpacity(0.3) 
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final segmentWidth = width / 2;
          
          Alignment alignment = appState.isWinterMode ? Alignment.centerRight : Alignment.centerLeft;

          return Stack(
            children: [
              AnimatedAlign(
                alignment: alignment,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                child: Container(
                  width: segmentWidth,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Theme.of(context).cardColor 
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                   _buildSlidingOption(
                    context, 
                    icon: Icons.wb_sunny_rounded, 
                    label: "Normal", 
                    isActive: !appState.isWinterMode,
                    onTap: () => appState.setWinterMode(false),
                  ),
                   _buildSlidingOption(
                    context, 
                    icon: Icons.ac_unit_rounded, 
                    label: "Winter", 
                    isActive: appState.isWinterMode,
                    onTap: () => appState.setWinterMode(true),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildThemeToggle(BuildContext context, AppState appState) {
    return Container(
      height: 56, // Fixed height for consistency
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.black.withOpacity(0.3) 
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final segmentWidth = width / 2;
          
          // Determine alignment based on selection
          Alignment alignment = Alignment.centerLeft;
          if (appState.themeMode == ThemeMode.dark) {
            alignment = Alignment.centerRight;
          }

          return Stack(
            children: [
              // Sliding Indicator
              AnimatedAlign(
                alignment: alignment,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                child: Container(
                  width: segmentWidth,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Theme.of(context).cardColor 
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                ),
              ),
              // Text Labels Row
              Row(
                children: [
                   _buildSlidingOption(
                    context, 
                    icon: Icons.light_mode_rounded, 
                    label: "Light", 
                    isActive: appState.themeMode == ThemeMode.light || appState.themeMode == ThemeMode.system, // Fallback if system somehow sticks
                    onTap: () => appState.setThemeMode(ThemeMode.light),
                  ),
                   _buildSlidingOption(
                    context, 
                    icon: Icons.dark_mode_rounded, 
                    label: "Dark", 
                    isActive: appState.themeMode == ThemeMode.dark,
                    onTap: () => appState.setThemeMode(ThemeMode.dark),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSlidingOption(BuildContext context, {required IconData icon, required String label, required bool isActive, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Icon(
               icon, 
               size: 20, 
               color: isActive 
                   ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black) 
                   : Colors.grey.shade600
             ),
             const SizedBox(height: 4),
             Text(
               label, 
               style: TextStyle(
                 fontSize: 12, 
                 fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                 color: isActive 
                     ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black) 
                     : Colors.grey.shade600
               )
             ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPicker(BuildContext context, AppState appState) {
    final colors = [
      const Color(0xFFFF7F50), // Coral Orange (Default)
      const Color(0xFF4ECDC4), // Turquoise
      const Color(0xFFFFD93D), // Yellow
      const Color(0xFF6C63FF), // Purple
      const Color(0xFFFF6B9D), // Pink
      const Color(0xFF2E86DE), // Blue
    ];

    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: colors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final color = colors[index];
          final isSelected = appState.themeColor.value == color.value;
          
          return GestureDetector(
            onTap: () => appState.setThemeColor(color),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected 
                      ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)
                      : Colors.transparent,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3)
                  )
                ]
              ),
              child: isSelected 
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : null,
            ),
          );
        },
      ),
    );
  }



  Widget _buildTextScaleSlider(BuildContext context, AppState appState) {
     return Column(
       children: [
         Row(
           mainAxisAlignment: MainAxisAlignment.spaceBetween,
           children: [
             const Text("A", style: TextStyle(fontSize: 12)),
             Expanded(
               child: Slider(
                 value: appState.textScaleFactor.clamp(0.8, 1.3),
                 min: 0.8,
                 max: 1.3,
                 divisions: 5,
                 label: "${appState.textScaleFactor.toStringAsFixed(1)}x",
                 onChanged: (value) => appState.setTextScaleFactor(value),
               ),
             ),
             const Text("A", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
           ],
         ),
         Text(
           "${(appState.textScaleFactor * 100).toInt()}%",
           style: Theme.of(context).textTheme.labelSmall,
         )
       ],
     );
  }

  Widget _buildSubscriptionSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: Theme.of(context).brightness == Brightness.dark 
              ? [
                  const Color(0xFF322E40), // Premium Surface
                  const Color(0xFF2A2635), // Slightly darker
                ]
              : [
                  const Color(0xFFFFF5F7),
                  const Color(0xFFF0F9FF),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.white.withOpacity(0.1) 
              : Theme.of(context).colorScheme.primary.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SvgPicture.asset(
                          'assets/images/bloom.svg',
                          height: 20,
                          colorFilter: ColorFilter.mode(
                            Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'PRO',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Theme.of(context).colorScheme.primary,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Lifetime Access Unlocked ✨',
                      style: TextStyle(
                        fontSize: 14, 
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.white70 
                            : Colors.grey.shade700
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CustomerCenterScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Membership Benefits',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () async {
          try {
            await AuthService().signOut();
            // AuthState stream in main.dart will handle navigation
          } catch (e) {
            BloomSnackBar.show(
              context,
              message: 'Error logging out: $e',
              icon: Icons.error_outline_rounded,
              isError: true,
            );
          }
        },
        icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
        label: const Text(
          "Log Out",
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.redAccent.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: isDark ? Colors.white24 : Colors.grey.shade300),
          ],
        ),
      ),
    );
  }
}
