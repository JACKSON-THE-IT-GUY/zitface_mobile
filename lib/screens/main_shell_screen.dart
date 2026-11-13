import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widget/glass_card.dart';
import '../widget/glass_scaffold.dart';
import '../widget/profile_avatar.dart';
import '../services/profile_identity.dart';
import 'groups_screen.dart';
import 'home_screen.dart';
import 'market_screen.dart';
import 'chats_screen.dart';
import 'profile_screen.dart';
import 'materials_screen.dart';
import 'friends_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;
  final ValueNotifier<int> _postSignal = ValueNotifier(0);
  final ValueNotifier<int> _chatSignal = ValueNotifier(0);
  final ValueNotifier<int> _homeSignal = ValueNotifier(0);
  final ValueNotifier<int> _friendsSignal = ValueNotifier(0);
  final ValueNotifier<int> _marketSignal = ValueNotifier(0);
  final ValueNotifier<ProfileIdentity> _profile = ValueNotifier(
    const ProfileIdentity(),
  );

  late final List<Widget> _screens = [
    HomeScreen(
      onProfileTap: _openProfileTab,
      onPostPublished: () => _postSignal.value++,
      onNavigate: _selectTab,
      onProfileChanged: (profile) => _profile.value = profile,
      profile: _profile,
      refreshSignal: _homeSignal,
    ),
    const MaterialsScreen(),
    FriendsScreen(refreshSignal: _friendsSignal),
    const GroupsScreen(),
    MarketplaceScreen(profile: _profile, refreshSignal: _marketSignal),
    ChatsScreen(refreshSignal: _chatSignal),
    ProfileScreen(
      postSignal: _postSignal,
      profile: _profile,
      onMessagesTap: () => _selectTab(5),
      onProfileChanged: (profile) => _profile.value = profile,
    ),
  ];

  @override
  void dispose() {
    _postSignal.dispose();
    _chatSignal.dispose();
    _homeSignal.dispose();
    _friendsSignal.dispose();
    _marketSignal.dispose();
    _profile.dispose();
    super.dispose();
  }

  void _selectTab(int index) {
    if (index == 0) _homeSignal.value++;
    if (index == 2) _friendsSignal.value++;
    if (index == 4) _marketSignal.value++;
    if (index == 5) _chatSignal.value++;
    setState(() => _currentIndex = index);
  }

  void _openProfileTab() {
    final profileIndex = _screens.indexWhere(
      (screen) => screen is ProfileScreen,
    );
    if (profileIndex < 0) return;
    _selectTab(profileIndex);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1200;
        final isTablet = constraints.maxWidth >= 900;
        final bottomNavigationBar = isDesktop
            ? null
            : isTablet
            ? Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: _buildFloatingNavBar(),
                ),
              )
            : _buildFloatingNavBar();
        final appBody = isDesktop
            ? Row(
                children: [
                  _buildWideNavigationRail(),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1440),
                        child: SizedBox.expand(
                          child: IndexedStack(
                            index: _currentIndex,
                            children: _screens,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : IndexedStack(index: _currentIndex, children: _screens);

        return GlassScaffold(
          bottomNavigationBar: bottomNavigationBar,
          child: appBody,
        );
      },
    );
  }

  Widget _buildWideNavigationRail() {
    return NavigationRail(
      selectedIndex: _currentIndex,
      onDestinationSelected: _selectTab,
      extended: true,
      minExtendedWidth: 232,
      backgroundColor: Theme.of(context).colorScheme.surface,
      indicatorColor: AppColors.accent.withValues(alpha: 0.16),
      leading: Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 28, left: 12),
        child: Text(
          'ZITFACE',
          style: TextStyle(
            color: AppColors.accent,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      destinations: [
        const NavigationRailDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: Text('Home'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.menu_book_outlined),
          selectedIcon: Icon(Icons.menu_book),
          label: Text('Materials'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.person_search_outlined),
          selectedIcon: Icon(Icons.person_search),
          label: Text('Friends'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.group_outlined),
          selectedIcon: Icon(Icons.group),
          label: Text('Groups'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.storefront_outlined),
          selectedIcon: Icon(Icons.storefront),
          label: Text('Market'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.chat_bubble_outline),
          selectedIcon: Icon(Icons.chat_bubble),
          label: Text('Chats'),
        ),
        NavigationRailDestination(
          icon: _navigationProfileAvatar(),
          selectedIcon: _navigationProfileAvatar(),
          label: const Text('Profile'),
        ),
      ],
    );
  }

  Widget _buildFloatingNavBar() {
    final List<Map<String, dynamic>> navItems = [
      {'icon': Icons.home_outlined, 'activeIcon': Icons.home, 'label': 'Home'},
      {
        'icon': Icons.menu_book_outlined,
        'activeIcon': Icons.menu_book,
        'label': 'Materials',
      },
      {
        'icon': Icons.person_search_outlined,
        'activeIcon': Icons.person_search,
        'label': 'Friends',
      },
      {
        'icon': Icons.group_outlined,
        'activeIcon': Icons.group,
        'label': 'Groups',
      },
      {
        'icon': Icons.storefront_outlined,
        'activeIcon': Icons.storefront,
        'label': 'Market',
      },
      {
        'icon': Icons.chat_bubble_outline,
        'activeIcon': Icons.chat_bubble,
        'label': 'Chats',
      },
      {
        'icon': Icons.person_outline,
        'activeIcon': Icons.person,
        'label': 'Profile',
      },
    ];

    return Padding(
      padding: const EdgeInsets.only(left: 14, right: 14, bottom: 14),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(navItems.length, (index) {
            final bool isActive = _currentIndex == index;
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  _selectTab(index);
                },
                child: AnimatedContainer(
                  width: double.infinity,
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.accent.withValues(alpha: 0.20)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isActive
                          ? AppColors.accent.withValues(alpha: 0.4)
                          : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      index == 6
                          ? _navigationProfileAvatar()
                          : Icon(
                              isActive
                                  ? navItems[index]['activeIcon']
                                  : navItems[index]['icon'],
                              color: isActive
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              size: 19,
                            ),
                      const SizedBox(height: 2),
                      Text(
                        navItems[index]['label'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isActive
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 8,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _navigationProfileAvatar() {
    return ValueListenableBuilder<ProfileIdentity>(
      valueListenable: _profile,
      builder: (_, identity, _) => ProfileAvatar(
        radius: 14,
        name: identity.name,
        avatarUrl: identity.avatarUrl,
        photoData: identity.photoData,
      ),
    );
  }
}
