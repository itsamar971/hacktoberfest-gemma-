import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/dreams_screen.dart';
import '../screens/travel_screen.dart';
import '../screens/journal_screen.dart';
import '../screens/settings_screen.dart';


class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
     HomeScreen(),
     DreamsScreen(),
     TravelScreen(),
     JournalScreen(),
     SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Only if using a transparent/floating navbar
      body: IndexedStack(
         index: _selectedIndex,
         children: _pages,
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 24, right: 24, top: 10, bottom: 32),
        height: 64, // Explicit height for the pill
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark 
              ? const Color(0xFF1E2124) // Dark surface
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Theme.of(context).brightness == Brightness.dark
              ? Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1.0,
                )
              : null,
          boxShadow: [
            if (Theme.of(context).brightness == Brightness.dark)
              BoxShadow(
                color: Colors.white.withOpacity(0.05),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(0, Icons.wb_sunny_outlined, Icons.wb_sunny_rounded),
            _buildNavItem(1, Icons.auto_awesome_outlined, Icons.auto_awesome_rounded),
            _buildNavItem(2, Icons.map_outlined, Icons.map_rounded),
            _buildNavItem(3, Icons.book_outlined, Icons.book_rounded),
            _buildNavItem(4, Icons.settings_outlined, Icons.settings_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 64,
        width: 64,
        alignment: Alignment.center,
        child: Icon(
          isSelected ? activeIcon : icon,
          color: isSelected 
              ? Theme.of(context).colorScheme.primary 
              : (Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white54 
                  : Colors.grey.shade400),
          size: 28,
        ),
      ),
    );
  }
}
