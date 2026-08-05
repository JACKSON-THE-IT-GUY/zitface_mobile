import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widget/glass_card.dart';
import '../widget/glass_scaffold.dart';
import 'groups_screen.dart';
import 'home_screen.dart';
import 'market_screen.dart';
import 'chats_screen.dart';
import 'profile_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const GroupsScreen(),
    const MarketplaceScreen(),
    const ChatsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      bottomNavigationBar: _buildFloatingNavBar(),
      child: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
    );
  }

  Widget _buildFloatingNavBar() {
    final List<Map<String, dynamic>> navItems = [
      {'icon': Icons.home_outlined, 'activeIcon': Icons.home, 'label': 'Home'},
      {'icon': Icons.group_outlined, 'activeIcon': Icons.group, 'label': 'Groups'},
      {'icon': Icons.storefront_outlined, 'activeIcon': Icons.storefront, 'label': 'Market'},
      {'icon': Icons.chat_bubble_outline, 'activeIcon': Icons.chat_bubble, 'label': 'Chats'},
      {'icon': Icons.person_outline, 'activeIcon': Icons.person, 'label': 'Profile'},
    ];

    return Padding(
      padding: const EdgeInsets.only(left: 14, right: 14, bottom: 14),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(navItems.length, (index) {
            final bool isActive = _currentIndex == index;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _currentIndex = index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.accent.withValues(alpha: 0.20) : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isActive ? AppColors.accent.withValues(alpha: 0.4) : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isActive ? navItems[index]['activeIcon'] : navItems[index]['icon'],
                      color: isActive ? Colors.white : Colors.white60,
                      size: 20,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      navItems[index]['label'],
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.white60,
                        fontSize: 9,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}