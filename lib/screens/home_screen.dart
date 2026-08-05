import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widget/glass_card.dart';
import 'menu_screen.dart';
import 'create_post_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF090A0F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.88,
        child: const MenuScreen(),
      ),
    );
  }
  void _openCreatePost(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const CreatePostScreen(),
  );
}

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        final isDark = currentMode == ThemeMode.dark;
        final surfaceColor = isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.05);
        final mutedText = isDark ? Colors.white60 : Colors.black54;
        final bodyText = isDark ? Colors.white : Colors.black87;
        final softSurface = isDark
            ? Colors.black.withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.7);

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ZITFACE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Row(
                        children: [
                          _CircleIconButton(icon: Icons.search, onTap: () {}),
                          const SizedBox(width: 10),
                          _CircleIconButton(icon: Icons.chat_bubble_outline, onTap: () {}),
                          const SizedBox(width: 10),
                          // Facebook-style Menu Trigger
                          _CircleIconButton(
                            icon: Icons.menu,
                            onTap: () => _openMenu(context),
                          ),
                          const SizedBox(width: 10),
                          // Create Post Trigger
                          _CircleIconButton(
                            icon: Icons.add,
                            onTap: () => _openCreatePost(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      GlassCard(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.white.withValues(alpha: 0.1),
                              child: const Icon(Icons.person, color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: softSurface,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: GestureDetector(
                                  onTap: () => _openCreatePost(context),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "What's on your mind?",
                                          style: TextStyle(color: mutedText, fontSize: 13),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Icon(
                                        Icons.image_outlined,
                                        color: mutedText,
                                        size: 22,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 110,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          children: [
                            _buildCreateStoryCard(),
                            _buildStoryCard('Jennifer'),
                            _buildStoryCard('Benjamin'),
                            _buildStoryCard('Edison'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      GlassCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                                    child: const Icon(Icons.person, color: Colors.white, size: 16),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Cristofar',
                                        style: TextStyle(
                                          color: bodyText,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        '20 minutes ago',
                                        style: TextStyle(color: mutedText, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Icon(Icons.more_horiz, color: mutedText),
                                ],
                              ),
                            ),
                            Container(
                              height: 220,
                              width: double.infinity,
                              margin: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: surfaceColor,
                              ),
                              child: const Center(
                                child: Icon(Icons.image_outlined, color: Colors.white24, size: 36),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                              child: Text(
                                'Liked by marina and 15,360 others',
                                style: TextStyle(color: mutedText, fontSize: 12),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: softSurface,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.favorite, color: Colors.white, size: 16),
                                        const SizedBox(width: 6),
                                        Text(
                                          '15.3K',
                                          style: TextStyle(
                                            color: bodyText,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Icon(Icons.chat_bubble_outline, color: mutedText, size: 15),
                                        const SizedBox(width: 6),
                                        Text(
                                          '300',
                                          style: TextStyle(
                                            color: bodyText,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCreateStoryCard() {
    return Container(
      width: 85,
      margin: const EdgeInsets.only(right: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              child: const Icon(Icons.add, color: Colors.white, size: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create story',
              style: TextStyle(color: Colors.white60, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryCard(String name) {
    return Container(
      width: 85,
      margin: const EdgeInsets.only(right: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(8),
        child: Stack(
          children: [
            Positioned(
              bottom: 4,
              left: 0,
              right: 0,
              child: Text(
                name,
                style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}