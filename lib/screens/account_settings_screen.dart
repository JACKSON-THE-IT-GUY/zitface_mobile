import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/profile_identity.dart';
import '../services/zitface_backend.dart';
import 'legal_information_screen.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key, this.profile, this.onProfileChanged});

  final ProfileIdentity? profile;
  final ValueChanged<ProfileIdentity>? onProfileChanged;

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  bool _isPrivate = false;
  bool _isLoadingPrivacy = ZitfaceBackend.isConfigured;
  bool _isSavingPrivacy = false;

  @override
  void initState() {
    super.initState();
    _loadPrivacy();
  }

  Future<void> _loadPrivacy() async {
    if (!ZitfaceBackend.isConfigured ||
        ZitfaceBackend.client.auth.currentUser == null) {
      return;
    }
    try {
      final isPrivate = await ZitfaceBackend.loadMyProfilePrivacy();
      if (mounted) setState(() => _isPrivate = isPrivate);
    } on Exception catch (error) {
      if (mounted) _showMessage('Could not load privacy settings: $error');
    } finally {
      if (mounted) setState(() => _isLoadingPrivacy = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _requireCloudAccount() {
    if (!ZitfaceBackend.isConfigured ||
        ZitfaceBackend.client.auth.currentUser == null) {
      _showMessage(
        'Sign in to a connected ZITFACE account to use this setting.',
      );
    }
  }

  Future<void> _changeName() async {
    if (!ZitfaceBackend.isConfigured ||
        ZitfaceBackend.client.auth.currentUser == null) {
      _requireCloudAccount();
      return;
    }
    final controller = TextEditingController(text: widget.profile?.name ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change display name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 80,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Display name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || !mounted) return;

    try {
      await ZitfaceBackend.updateMyDisplayName(name);
      final current = widget.profile ?? const ProfileIdentity();
      widget.onProfileChanged?.call(
        ProfileIdentity(
          name: name.trim(),
          school: current.school,
          program: current.program,
          yearOfStudy: current.yearOfStudy,
          interests: current.interests,
          website: current.website,
          bio: current.bio,
          handle: current.handle,
          avatarUrl: current.avatarUrl,
          photoData: current.photoData,
        ),
      );
      if (mounted) _showMessage('Display name updated.');
    } on Exception catch (error) {
      if (mounted) _showMessage('Could not update display name: $error');
    }
  }

  Future<void> _changePassword() async {
    if (!ZitfaceBackend.isConfigured ||
        ZitfaceBackend.client.auth.currentUser == null) {
      _requireCloudAccount();
      return;
    }
    final currentPassword = TextEditingController();
    final newPassword = TextEditingController();
    final confirmPassword = TextEditingController();
    final values = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change password'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPassword,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current password',
                ),
              ),
              TextField(
                controller: newPassword,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New password (12+ characters)',
                ),
              ),
              TextField(
                controller: confirmPassword,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm new password',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, [
              currentPassword.text,
              newPassword.text,
              confirmPassword.text,
            ]),
            child: const Text('Update'),
          ),
        ],
      ),
    );
    if (values == null || !mounted) {
      currentPassword.dispose();
      newPassword.dispose();
      confirmPassword.dispose();
      return;
    }
    final oldPassword = values[0];
    final nextPassword = values[1];
    final confirmation = values[2];
    currentPassword.dispose();
    newPassword.dispose();
    confirmPassword.dispose();

    if (oldPassword.isEmpty || nextPassword.length < 12) {
      _showMessage(
        'Enter your current password and a 12-character new password.',
      );
      return;
    }
    if (nextPassword != confirmation) {
      _showMessage('The new passwords do not match.');
      return;
    }

    try {
      await ZitfaceBackend.changeMyPassword(
        currentPassword: oldPassword,
        newPassword: nextPassword,
      );
      if (mounted) _showMessage('Password updated.');
    } on AuthException catch (error) {
      if (mounted) _showMessage(error.message);
    } on Exception catch (error) {
      if (mounted) _showMessage('Could not update password: $error');
    }
  }

  Future<void> _setPrivacy(bool value) async {
    if (_isSavingPrivacy) return;
    setState(() => _isSavingPrivacy = true);
    try {
      await ZitfaceBackend.setMyProfilePrivacy(value);
      if (mounted) setState(() => _isPrivate = value);
    } on Exception catch (error) {
      if (mounted) _showMessage('Could not update profile privacy: $error');
    } finally {
      if (mounted) setState(() => _isSavingPrivacy = false);
    }
  }

  Future<void> _signOutOtherDevices() async {
    if (!ZitfaceBackend.isConfigured ||
        ZitfaceBackend.client.auth.currentUser == null) {
      _requireCloudAccount();
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out other devices?'),
        content: const Text(
          'Other active sessions will be revoked. This device will stay signed in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sign out other devices'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await ZitfaceBackend.client.auth.signOut(scope: SignOutScope.others);
      if (mounted) _showMessage('Other sessions have been signed out.');
    } on AuthException catch (error) {
      if (mounted) _showMessage(error.message);
    } on Exception catch (error) {
      if (mounted) _showMessage('Could not sign out other devices: $error');
    }
  }

  Future<void> _deleteAccount() async {
    if (!ZitfaceBackend.isConfigured) {
      _requireCloudAccount();
      return;
    }
    final user = ZitfaceBackend.client.auth.currentUser;
    final email = user?.email;
    if (user == null || email == null || email.isEmpty) {
      _showMessage('Account deletion requires an email-and-password account.');
      return;
    }
    final passwordController = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete account permanently?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your profile, posts, messages, listings, membership record, and uploaded files will be deleted. This cannot be undone.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () =>
                Navigator.pop(dialogContext, passwordController.text),
            child: const Text('Delete account'),
          ),
        ],
      ),
    );
    passwordController.dispose();
    if (password == null || !mounted) return;
    if (password.isEmpty) {
      _showMessage('Enter your password to confirm account deletion.');
      return;
    }

    try {
      await ZitfaceBackend.deleteMyAccount(password: password);
      await ZitfaceBackend.client.auth.signOut(scope: SignOutScope.local);
    } on Exception catch (error) {
      if (mounted) _showMessage('Could not delete account: $error');
    }
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ZitfaceBackend.isConfigured
        ? ZitfaceBackend.client.auth.currentUser
        : null;
    final email = currentUser?.email ?? 'Local demo account';
    return Scaffold(
      appBar: AppBar(title: const Text('Account & Privacy')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(email, style: Theme.of(context).textTheme.bodyMedium),
            _sectionTitle(context, 'Account'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.badge_outlined),
              title: const Text('Change display name'),
              subtitle: Text(
                widget.profile?.name.isNotEmpty == true
                    ? widget.profile!.name
                    : 'Update the name shown to other members',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _changeName,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.password_outlined),
              title: const Text('Change password'),
              subtitle: const Text(
                'Use a unique password with 12 or more characters',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _changePassword,
            ),
            _sectionTitle(context, 'Privacy'),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _isPrivate,
              onChanged:
                  ZitfaceBackend.isConfigured &&
                      !_isLoadingPrivacy &&
                      !_isSavingPrivacy
                  ? _setPrivacy
                  : null,
              title: const Text('Private profile'),
              subtitle: const Text(
                'Only you and accepted friends can view your profile details.',
              ),
            ),
            _sectionTitle(context, 'Sessions'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.phone_iphone_outlined),
              title: const Text('This device'),
              subtitle: Text(
                currentUser == null
                    ? 'No connected account session in local demo mode.'
                    : 'Signed in. A per-device session list is not available in this app.',
              ),
            ),
            OutlinedButton.icon(
              onPressed: _signOutOtherDevices,
              icon: const Icon(Icons.phonelink_erase_outlined),
              label: const Text('Sign out other devices'),
            ),
            _sectionTitle(context, 'Your data'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.delete_forever_outlined,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Delete account',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              subtitle: const Text(
                'Permanently remove your account and its data',
              ),
              onTap: _deleteAccount,
            ),
            _sectionTitle(context, 'Policies'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Privacy and terms'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const LegalInformationScreen(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
