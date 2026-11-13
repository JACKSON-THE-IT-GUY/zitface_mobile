import 'package:zitface_mobile/theme/app_theme.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zitface_mobile/widget/glass_card.dart';
import '../services/zitface_backend.dart';
import '../services/profile_identity.dart';
import 'edit_profile_screen.dart';
import 'chats_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.onMessagesTap,
    this.postSignal,
    this.profile,
    this.onProfileChanged,
  });

  final VoidCallback? onMessagesTap;
  final ValueListenable<int>? postSignal;
  final ValueListenable<ProfileIdentity>? profile;
  final ValueChanged<ProfileIdentity>? onProfileChanged;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const String _profileStorageKey = 'profile';
  String _name = '';
  String _handle = '';
  String _school = '';
  String _program = '';
  String _yearOfStudy = '';
  String _interests = '';
  String _website = '';
  String _bio = '';
  String _photoPath = '';
  String _photoData = '';
  String _avatarUrl = '';
  bool _hasProfile = false;
  bool _isLoading = true;
  int? _postCount;

  void _notifyProfileChanged() {
    widget.onProfileChanged?.call(
      ProfileIdentity(
        name: _name,
        handle: _handle,
        school: _school,
        program: _program,
        yearOfStudy: _yearOfStudy,
        interests: _interests,
        website: _website,
        bio: _bio,
        avatarUrl: _avatarUrl,
        photoData: _photoData,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    widget.postSignal?.addListener(_refreshContributions);
    widget.profile?.addListener(_syncSharedProfile);
    _loadProfile();
    _refreshContributions();
  }

  @override
  void dispose() {
    widget.postSignal?.removeListener(_refreshContributions);
    widget.profile?.removeListener(_syncSharedProfile);
    super.dispose();
  }

  void _syncSharedProfile() {
    final profile = widget.profile?.value;
    if (profile == null) return;
    if (profile.name == _name &&
        profile.handle == _handle &&
        profile.school == _school &&
        profile.program == _program &&
        profile.yearOfStudy == _yearOfStudy &&
        profile.interests == _interests &&
        profile.website == _website &&
        profile.bio == _bio &&
        profile.avatarUrl == _avatarUrl &&
        profile.photoData == _photoData) {
      return;
    }
    setState(() {
      _name = profile.name;
      _handle = profile.handle;
      _school = profile.school;
      _program = profile.program;
      _yearOfStudy = profile.yearOfStudy;
      _interests = profile.interests;
      _website = profile.website;
      _bio = profile.bio;
      _avatarUrl = profile.avatarUrl;
      _photoData = profile.photoData;
      _hasProfile = true;
    });
  }

  Future<void> _refreshContributions() async {
    if (!ZitfaceBackend.isConfigured) {
      setState(() => _postCount = widget.postSignal?.value ?? 0);
      return;
    }
    try {
      final count = await ZitfaceBackend.loadMyPostCount();
      if (mounted) setState(() => _postCount = count);
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() => _postCount = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load contribution stars: $error')),
      );
    }
  }

  void _openMessages() {
    final callback = widget.onMessagesTap;
    if (callback != null) {
      callback();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => const ChatsScreen()),
      );
    }
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
          _program = profile.program;
          _yearOfStudy = profile.yearOfStudy;
          _interests = profile.interests;
          _website = profile.website;
          _bio = profile.bio;
          _avatarUrl = profile.avatarUrl;
          _hasProfile = true;
          _isLoading = false;
        });
        _notifyProfileChanged();
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
        String readOptionalField(String key) {
          final value = decoded[key];
          if (value == null) return '';
          if (value is! String) {
            throw FormatException('Saved profile field "$key" is invalid.');
          }
          return value;
        }

        _program = readOptionalField('program');
        _yearOfStudy = readOptionalField('yearOfStudy');
        _interests = readOptionalField('interests');
        _website = readOptionalField('website');
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
      _notifyProfileChanged();
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
        currentHandle: _handle,
        currentSchool: _school,
        currentProgram: _program,
        currentYearOfStudy: _yearOfStudy,
        currentInterests: _interests,
        currentWebsite: _website,
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
      final updatedProgram = result['program'] ?? _program;
      final updatedYearOfStudy = result['yearOfStudy'] ?? _yearOfStudy;
      final updatedInterests = result['interests'] ?? _interests;
      final updatedWebsite = result['website'] ?? _website;
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
            program: updatedProgram,
            yearOfStudy: updatedYearOfStudy,
            interests: updatedInterests,
            website: updatedWebsite,
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
          'program': updatedProgram,
          'yearOfStudy': updatedYearOfStudy,
          'interests': updatedInterests,
          'website': updatedWebsite,
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
        _program = updatedProgram;
        _yearOfStudy = updatedYearOfStudy;
        _interests = updatedInterests;
        _website = updatedWebsite;
        _bio = updatedBio;
        _photoPath = updatedPhotoPath;
        _photoData = ZitfaceBackend.isConfigured ? '' : updatedPhotoData;
        _avatarUrl = updatedAvatarUrl;
        _hasProfile = true;
      });
      _notifyProfileChanged();
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
                        if (_program.isNotEmpty || _yearOfStudy.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (_program.isNotEmpty)
                                _profileDetailChip(
                                  Icons.menu_book_outlined,
                                  _program,
                                ),
                              if (_yearOfStudy.isNotEmpty)
                                _profileDetailChip(
                                  Icons.calendar_today_outlined,
                                  _yearOfStudy,
                                ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 14),
                        Text(
                          _bio.isNotEmpty ? _bio : 'Add a short bio about you.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.7),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        if (_interests.isNotEmpty || _website.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'ABOUT',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (_interests.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.interests_outlined,
                                    size: 17,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(_interests)),
                                ],
                              ),
                            ),
                          if (_website.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.link,
                                    size: 17,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _website,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: AppColors.accent,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
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
                          OutlinedButton.icon(
                            onPressed: _openMessages,
                            icon: const Icon(
                              Icons.chat_bubble_outline,
                              size: 18,
                            ),
                            label: const Text('Messages'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: AppColors.accent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _postCount == null
                              ? 'Stars unavailable'
                              : '$_postCount contribution ${_postCount == 1 ? 'star' : 'stars'}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Text('1 per post'),
                    ],
                  ),
                ),
              ),
            ),
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

  Widget _profileDetailChip(IconData icon, String label) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 250),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
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
}
