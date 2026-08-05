import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 14),

              // Title Header
              const Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              // Profile Card Header Shortcut
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: const Center(
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Jackson Nsonga',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'See your profile',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 14),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // All Shortcuts Grid
              const Text(
                'All Shortcuts',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.2,
                children: [
                  _buildShortcutCard(Icons.groups_outlined, 'Groups', 'CBU Hubs'),
                  _buildShortcutCard(Icons.storefront_outlined, 'Marketplace', 'Campus Buy/Sell'),
                  _buildShortcutCard(Icons.bookmark_outline, 'Saved', 'Posts & Notes'),
                  _buildShortcutCard(Icons.event_outlined, 'Campus Events', 'ICTA & Guild'),
                ],
              ),

              const SizedBox(height: 24),

              // Settings & Privacy Section
              _buildAccordionSection(
                context,
                icon: Icons.settings_outlined,
                title: 'Settings & Privacy',
                children: [
                  _buildMenuItem(Icons.lock_outline, 'Privacy Shortcuts', onTap: () {}),
                  _buildMenuItem(Icons.dark_mode_outlined, 'Dark Mode', subtitle: 'On', onTap: () {}),
                  _buildMenuItem(Icons.language_outlined, 'Language', subtitle: 'English (US)', onTap: () {}),
                ],
              ),

              const SizedBox(height: 10),

              // Help & Support Section
              _buildAccordionSection(
                context,
                icon: Icons.help_outline_rounded,
                title: 'Help & Support',
                children: [
                  _buildMenuItem(Icons.help_center_outlined, 'Help Center', onTap: () {}),
                  _buildMenuItem(Icons.report_problem_outlined, 'Report a Problem', onTap: () {}),
                  _buildMenuItem(Icons.article_outlined, 'Terms & Policies', onTap: () {}),
                ],
              ),
              ValueListenableBuilder<ThemeMode>(
  valueListenable: themeNotifier,
  builder: (context, currentMode, _) {
    final isDark = currentMode == ThemeMode.dark;
    return _buildMenuItem(
      Icons.dark_mode_outlined,
      'Dark Mode',
      subtitle: isDark ? 'On' : 'Off',
      onTap: () {
        themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
      },
    );
  },
),

              const SizedBox(height: 20),

              // Log Out Button
              GestureDetector(
                onTap: () => _showLogoutDialog(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
                  ),
                  child: const Center(
                    child: Text(
                      'Log Out',
                      style: TextStyle(
                        color: Color(0xFFEF4444), // Muted warning red accent
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShortcutCard(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccordionSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: Colors.white70,
          collapsedIconColor: Colors.white38,
          leading: Icon(icon, color: Colors.white),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          children: children,
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title, {
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: Colors.white54, size: 20),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white70, fontSize: 13),
      ),
      trailing: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            )
          : const Icon(Icons.chevron_right, color: Colors.white24, size: 16),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF14151C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          title: const Text(
            'Log Out',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Are you sure you want to log out of ZITFACE?',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                // Perform auth logout action here
              },
              child: const Text('Log Out', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}