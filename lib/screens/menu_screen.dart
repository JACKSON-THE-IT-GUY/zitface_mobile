import 'package:flutter/material.dart';
import 'package:zitface_mobile/widget/glass_card.dart';
import '../theme/app_theme.dart';
import '../services/zitface_backend.dart';

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
              Text(
                'Menu',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              // Profile Card Header Shortcut
              GlassCard(
                padding: const EdgeInsets.all(12),
                borderRadius: 16,
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.1),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.person,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Jackson Nsonga',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'See your profile',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 14,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // All Shortcuts Grid
              Text(
                'All Shortcuts',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                  _buildShortcutCard(
                    context,
                    Icons.groups_outlined,
                    'Groups',
                    'CBU Hubs',
                  ),
                  _buildShortcutCard(
                    context,
                    Icons.storefront_outlined,
                    'Marketplace',
                    'Campus Buy/Sell',
                  ),
                  _buildShortcutCard(
                    context,
                    Icons.bookmark_outline,
                    'Saved',
                    'Posts & Notes',
                  ),
                  _buildShortcutCard(
                    context,
                    Icons.event_outlined,
                    'Campus Events',
                    'ICTA & Guild',
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Settings & Privacy Section
              _buildAccordionSection(
                context,
                icon: Icons.settings_outlined,
                title: 'Settings & Privacy',
                children: [
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: themeNotifier,
                    builder: (context, themeMode, _) => Column(
                      children: [
                        _buildAppearanceOption(
                          icon: Icons.light_mode_outlined,
                          title: 'Light mode',
                          selected: themeMode == ThemeMode.light,
                          context: context,
                          onTap: () => themeNotifier.value = ThemeMode.light,
                        ),
                        _buildAppearanceOption(
                          icon: Icons.dark_mode_outlined,
                          title: 'Dark mode',
                          selected: themeMode == ThemeMode.dark,
                          context: context,
                          onTap: () => themeNotifier.value = ThemeMode.dark,
                        ),
                      ],
                    ),
                  ),
                  _buildMenuItem(
                    context,
                    Icons.lock_outline,
                    'Privacy Shortcuts',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    context,
                    Icons.language_outlined,
                    'Language',
                    subtitle: 'English (US)',
                    onTap: () {},
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Help & Support Section
              _buildAccordionSection(
                context,
                icon: Icons.help_outline_rounded,
                title: 'Help & Support',
                children: [
                  _buildMenuItem(
                    context,
                    Icons.help_center_outlined,
                    'Help Center',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    context,
                    Icons.report_problem_outlined,
                    'Report a Problem',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    context,
                    Icons.article_outlined,
                    'Terms & Policies',
                    onTap: () {},
                  ),
                ],
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
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    ),
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

  Widget _buildShortcutCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      borderRadius: 14,
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
    return GlassCard(
      padding: EdgeInsets.zero,
      borderRadius: 16,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
            collapsedIconColor: Theme.of(context).colorScheme.onSurfaceVariant,
            leading: Icon(icon, color: Theme.of(context).colorScheme.onSurface),
            title: Text(
              title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            children: children,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title, {
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        size: 20,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 13,
        ),
      ),
      trailing: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            )
          : Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 16,
            ),
    );
  }

  Widget _buildAppearanceOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        size: 20,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 13,
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check_circle, color: AppColors.accent, size: 20)
          : Icon(
              Icons.circle_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.1),
            ),
          ),
          title: Text(
            'Log Out',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to log out of ZITFACE?',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                if (!ZitfaceBackend.isConfigured) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sign-out is unavailable in local demo mode.'),
                    ),
                  );
                  return;
                }
                try {
                  await ZitfaceBackend.client.auth.signOut();
                } on Exception catch (error) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not log out: $error')),
                  );
                }
              },
              child: Text(
                'Log Out',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
