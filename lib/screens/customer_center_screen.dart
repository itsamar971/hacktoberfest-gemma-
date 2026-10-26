import 'package:flutter/material.dart';

class CustomerCenterScreen extends StatelessWidget {
  const CustomerCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Membership Benefits'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark 
                      ? [const Color(0xFF322E40), const Color(0xFF23202E)]
                      : [const Color(0xFFFFF0F5), const Color(0xFFEBF8FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "MEMBERSHIP STATUS", 
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text("Active • Lifetime", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Bloom Pro Edition",
                    style: TextStyle(
                      fontSize: 24, 
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Unlimited personal growth, vision boards, and She Stacks arcade unlocked forever.",
                    style: TextStyle(
                      fontSize: 14, 
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            Text(
              "Included Privileges",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildBenefitTile(
              context,
              icon: Icons.auto_awesome_rounded,
              title: "AI Dream Decomposition",
              description: "Break any goal into actionable 15-minute daily micro-steps.",
            ),
            _buildBenefitTile(
              context,
              icon: Icons.videogame_asset_rounded,
              title: "She Stacks Arcade (11 Games)",
              description: "Complete access to all financial literacy and negotiation games.",
            ),
            _buildBenefitTile(
              context,
              icon: Icons.public_rounded,
              title: "Interactive 3D Travel Globe",
              description: "Pin destinations, upload high-res photos, and earn passport stamps.",
            ),
            _buildBenefitTile(
              context,
              icon: Icons.palette_rounded,
              title: "Deep Customization & Winter Mode",
              description: "Full access to custom color schemes, font scaling, and seasonal overlays.",
            ),
            _buildBenefitTile(
              context,
              icon: Icons.lock_outline_rounded,
              title: "Privacy-First Architecture",
              description: "Your dreams and personal thoughts stay safely on your device.",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262332) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
