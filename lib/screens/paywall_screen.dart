import 'package:flutter/material.dart';
import '../utils/bloom_snackbar.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Bloom Pro'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primaryContainer,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.workspace_premium_rounded, size: 64, color: Colors.white),
              ),
              const SizedBox(height: 32),
              const Text(
                'Bloom Pro Unlocked ✨',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'You have full, lifetime access to all Bloom Pro features including AI Dream Decomposition, She Stacks Arcade, and Unlimited Vision Boards.',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    BloomSnackBar.show(
                      context,
                      message: '🎉 You already have full access!',
                      icon: Icons.auto_awesome_rounded,
                    );
                    Navigator.of(context).pop(true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Continue to Bloom', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper function to present paywall modally
Future<bool?> showPaywall(BuildContext context) async {
  return await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (context) => const PaywallScreen(),
      fullscreenDialog: true,
    ),
  );
}
