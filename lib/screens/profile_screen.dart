import 'package:zitface_mobile/theme/app_theme.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zitface_mobile/widget/glass_card.dart';
import '../services/zitface_backend.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const String _profileStorageKey = 'profile';
  String _name = '';
  String _handle = '';
  String _school = '';
  String _bio = '';
  String _photoPath = '';
  String _photoData = '';
  String _avatarUrl = '';
  bool _hasProfile = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      if (ZitfaceBackend.isConfigured) {
        final profile = await ZitfaceBackend.loadMyProfile();
        if (!mounted) return;
        setState(() {
          _name = profile.displayName;
          _handle = profile.handle;
          _school = profile.school;
          _bio = profile.bio;
          _avatarUrl = profile.avatarUrl;
          _hasProfile = true;
          _isLoading = false;
        });
        return;
      }

      final preferences = await SharedPreferences.getInstance();
      final savedProfile = preferences.getString(_profileStorageKey);
      if (savedProfile != null) {
        final decoded = jsonDecode(savedProfile);
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException('Saved profile is not a valid object.');
        }

        String readField(String key) {
          final value = decoded[key];
          if (value is! String) {
            throw FormatException('Saved profile field "$key" is invalid.');
          }
          return value;
        }

        final name = readField('name');
        final handle = readField('handle');
        final school = readField('school');
        final bio = readField('bio');
        final photoPath = decoded['photoPath'];
        if (photoPath != null && photoPath is! String) {
          throw const FormatException('Saved profile photo path is invalid.');
        }
        final photoData = decoded['photoData'];
        if (photoData != null && photoData is! String) {
          throw const FormatException('Saved profile photo data is invalid.');
        }
        _name = name;
        _handle = handle;
        _school = school;
        _bio = bio;
        _photoPath = photoPath ?? '';
        _photoData = photoData ?? '';
        _avatarUrl = '';
        _hasProfile = true;
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showStorageError('load', error);
    }
  }

  Future<void> _openEditProfile(BuildContext context) async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditProfileScreen(
        currentName: _name,
        currentSchool: _school,
        currentBio: _bio,
        currentPhotoPath: _photoPath,
        currentPhotoData: _photoData,
        currentAvatarUrl: _avatarUrl,
        isCreating: !_hasProfile,
      ),
    );

    if (result != null && mounted) {
      final updatedName = result['name'] ?? _name;
      final updatedHandle = result['handle'] ?? _handle;
      final updatedSchool = result['school'] ?? _school;
      final updatedBio = result['bio'] ?? _bio;
      final updatedPhotoPath = result['photoPath'] ?? _photoPath;
      final updatedPhotoData = result['photoData'] ?? _photoData;
      var updatedAvatarUrl = _avatarUrl;

      if (ZitfaceBackend.isConfigured) {
        try {
          final profile = await ZitfaceBackend.saveMyProfile(
            displayName: updatedName,
            handle: updatedHandle,
            school: updatedSchool,
            bio: updatedBio,
            photoData: updatedPhotoData,
            removeAvatar: result['removeAvatar'] == 'true',
          );
          updatedAvatarUrl = profile.avatarUrl;
        } on Exception catch (error) {
          if (mounted) _showStorageError('save', error);
          return;
        }
      } else {
        final updatedProfile = <String, String>{
          'name': updatedName,
          'handle': updatedHandle,
          'school': updatedSchool,
          'bio': updatedBio,
          'photoPath': updatedPhotoPath,
          'photoData': updatedPhotoData,
        };

        try {
          final preferences = await SharedPreferences.getInstance();
          final saved = await preferences.setString(
            _profileStorageKey,
            jsonEncode(updatedProfile),
          );
          if (!saved) {
            _showStorageError(
              'save',
              Exception('Device storage did not confirm the profile update.'),
            );
            return;
          }
        } on Exception catch (error) {
          if (mounted) _showStorageError('save', error);
          return;
        }
      }

      if (!mounted) return;
      setState(() {
        _name = updatedName;
        _handle = updatedHandle;
        _school = updatedSchool;
        _bio = updatedBio;
        _photoPath = updatedPhotoPath;
        _photoData = ZitfaceBackend.isConfigured ? '' : updatedPhotoData;
        _avatarUrl = updatedAvatarUrl;
        _hasProfile = true;
      });
    }
  }

  void _showStorageError(String action, Exception error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not $action profile changes: $error')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleHandle = RegExp(r'^u_[0-9a-f]{28}$').hasMatch(_handle)
        ? ''
        : _handle;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Profile',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.06),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Icon(
                          Icons.settings_outlined,
                          color: Theme.of(context).colorScheme.onSurface,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Profile Info Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: GlassCard(
                  padding: const EdgeInsets.all(20),
                  borderRadius: 24,
                  child: Column(
                    children: [
                      _buildAvatar(),
                      const SizedBox(height: 14),

                      Text(
                        _hasProfile ? _name : 'Your profile',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (_hasProfile) ...[
                        if (visibleHandle.isNotEmpty || _school.isNotEmpty)
                          Text(
                            [
                              if (visibleHandle.isNotEmpty) visibleHandle,
                              if (_school.isNotEmpty) _school,
                            ].join(' • '),
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        const SizedBox(height: 14),
                        Text(
                          _bio,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.7),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                        Text(
                          'Add your name, campus details, bio, and a photo.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Profile Action Row
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: _isLoading
                                  ? null
                                  : () => _openEditProfile(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Center(
                                  child: Text(
                                    _hasProfile
                                        ? 'Edit Profile'
                                        : 'Create Profile',
                                    style: TextStyle(
                                      color: AppColors.onAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (_hasProfile)
                            GestureDetector(
                              onTap: () {},
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.1),
                                  ),
                                ),
                                child: Icon(
                                  Icons.share_outlined,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  size: 18,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (_hasProfile) ...[
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              // Campus Stats Grid
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      _buildStatCard('Posts', '28'),
                      const SizedBox(width: 10),
                      _buildStatCard('Market Listings', '3'),
                      const SizedBox(width: 10),
                      _buildStatCard('Groups', '4'),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Recent Activity Section Title
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'My Campus Activity',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // Sample Activity Feed Items
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildActivityItem(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'Posted in SICT (Computer Science)',
                      time: '2 hours ago',
                    ),
                    _buildActivityItem(
                      icon: Icons.storefront_outlined,
                      title: 'Listed item in CBU Market',
                      time: '1 day ago',
                    ),
                  ]),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 86,
      height: 86,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: ClipOval(child: _buildPhotoPreview()),
    );
  }

  Widget _buildPhotoPreview() {
    if (_photoData.isNotEmpty) {
      try {
        return Image.memory(
          base64Decode(_photoData),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _emptyAvatar(),
        );
      } on FormatException {
        return _emptyAvatar();
      }
    }
    if (_avatarUrl.isNotEmpty) {
      return Image.network(
        _avatarUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _emptyAvatar(),
      );
    }
    return _emptyAvatar();
  }

  Widget _emptyAvatar() {
    return Icon(
      Icons.person,
      color: Theme.of(context).colorScheme.onSurface,
      size: 46,
    );
  }

  Widget _buildStatCard(String title, String count) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 16),
        borderRadius: 18,
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String time,
  }) {
    return GestureDetector(
      onTap: () {},
      child: GlassCard(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        borderRadius: 16,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    time,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
