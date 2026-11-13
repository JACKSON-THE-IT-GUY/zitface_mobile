import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_bootstrap.dart';

class CloudProfile {
  const CloudProfile({
    required this.displayName,
    required this.handle,
    required this.school,
    required this.program,
    required this.yearOfStudy,
    required this.interests,
    required this.website,
    required this.bio,
    required this.avatarUrl,
  });

  factory CloudProfile.fromJson(Map<String, dynamic> json) {
    return CloudProfile(
      displayName: json['display_name'] as String,
      handle: json['handle'] as String,
      school: json['school'] as String,
      program: json['program'] as String? ?? '',
      yearOfStudy: json['year_of_study'] as String? ?? '',
      interests: json['interests'] as String? ?? '',
      website: json['website'] as String? ?? '',
      bio: json['bio'] as String,
      avatarUrl: json['avatar_url'] as String? ?? '',
    );
  }

  final String displayName;
  final String handle;
  final String school;
  final String program;
  final String yearOfStudy;
  final String interests;
  final String website;
  final String bio;
  final String avatarUrl;
}

class ZitfaceBackend {
  ZitfaceBackend._();

  static bool get isConfigured =>
      SupabaseEnvironment.fromCompileTime.isConfigured;

  static SupabaseClient get client => Supabase.instance.client;

  static String avatarStoragePath(String? avatar) {
    if (avatar == null || avatar.isEmpty) return '';
    final uri = Uri.tryParse(avatar);
    if (uri?.hasAuthority == true) {
      final segments = uri!.pathSegments;
      final bucketIndex = segments.indexOf('avatars');
      if (bucketIndex < 0 || bucketIndex == segments.length - 1) return '';
      return segments.skip(bucketIndex + 1).join('/');
    }
    return avatar;
  }

  static Future<String> avatarUrlFor(Map<String, dynamic> profile) async {
    final avatar = avatarStoragePath(profile['avatar_url'] as String?);
    if (avatar.isEmpty) return '';
    final url = await client.storage
        .from('avatars')
        .createSignedUrl(avatar, 300);
    final updatedAt = profile['updated_at'] as String?;
    if (updatedAt == null) return url;
    final signedUri = Uri.parse(url);
    return signedUri
        .replace(
          queryParameters: {...signedUri.queryParameters, 'v': updatedAt},
        )
        .toString();
  }

  static String avatarContentType(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff) {
      return 'image/jpeg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0d &&
        bytes[5] == 0x0a &&
        bytes[6] == 0x1a &&
        bytes[7] == 0x0a) {
      return 'image/png';
    }
    if (bytes.length >= 12 &&
        ascii.decode(bytes.sublist(0, 4), allowInvalid: true) == 'RIFF' &&
        ascii.decode(bytes.sublist(8, 12), allowInvalid: true) == 'WEBP') {
      return 'image/webp';
    }
    throw const FormatException('Choose a JPEG, PNG, or WebP profile photo.');
  }

  static Future<CloudProfile> loadMyProfile() async {
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('Sign in before loading a profile.');
    }

    final row = await client
        .from('profiles')
        .select(
          'display_name, handle, school, program, year_of_study, interests, '
          'website, bio, avatar_url, updated_at',
        )
        .eq('id', user.id)
        .maybeSingle();
    if (row == null) {
      throw StateError(
        'Your profile was not created. Check that the social foundation '
        'migration has been applied.',
      );
    }

    final profile = CloudProfile.fromJson(row);
    return CloudProfile(
      displayName: profile.displayName,
      handle: profile.handle,
      school: profile.school,
      program: profile.program,
      yearOfStudy: profile.yearOfStudy,
      interests: profile.interests,
      website: profile.website,
      bio: profile.bio,
      avatarUrl: await avatarUrlFor(row),
    );
  }

  static Future<CloudProfile> saveMyProfile({
    required String displayName,
    required String handle,
    required String school,
    String program = '',
    String yearOfStudy = '',
    String interests = '',
    String website = '',
    required String bio,
    String photoData = '',
    bool removeAvatar = false,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('Sign in before saving a profile.');
    }

    final normalizedHandle = handle
        .trim()
        .replaceFirst(RegExp(r'^@'), '')
        .toLowerCase();
    if (!RegExp(r'^[a-z0-9_]{3,30}$').hasMatch(normalizedHandle)) {
      throw const FormatException(
        'Handle must be 3–30 characters using lowercase letters, numbers, '
        'or underscores.',
      );
    }

    String? newAvatarPath;
    if (photoData.isNotEmpty) {
      final bytes = base64Decode(photoData);
      final contentType = avatarContentType(bytes);
      newAvatarPath = '${user.id}/avatar.jpg';
      await client.storage
          .from('avatars')
          .uploadBinary(
            newAvatarPath,
            Uint8List.fromList(bytes),
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );
    }

    final current = await client
        .from('profiles')
        .select('avatar_url')
        .eq('id', user.id)
        .maybeSingle();
    if (current == null) {
      throw StateError(
        'Your profile was not created. Check that the social foundation '
        'migration has been applied.',
      );
    }

    final update = <String, dynamic>{
      'display_name': displayName.trim(),
      'school': school.trim(),
      'program': program.trim(),
      'year_of_study': yearOfStudy.trim(),
      'interests': interests.trim(),
      'website': website.trim(),
      'bio': bio.trim(),
    };
    if (normalizedHandle.isNotEmpty) {
      update['handle'] = normalizedHandle;
    }
    if (newAvatarPath != null) {
      update['avatar_url'] = newAvatarPath;
    } else if (removeAvatar) {
      update['avatar_url'] = null;
    }

    final row = await client
        .from('profiles')
        .update(update)
        .eq('id', user.id)
        .select(
          'display_name, handle, school, program, year_of_study, interests, '
          'website, bio, avatar_url, updated_at',
        )
        .single();

    if (removeAvatar && newAvatarPath == null) {
      final oldAvatar = current['avatar_url'] as String?;
      if (oldAvatar != null &&
          oldAvatar.isNotEmpty &&
          !oldAvatar.startsWith('http')) {
        await client.storage.from('avatars').remove([oldAvatar]);
      }
    }

    final profile = CloudProfile.fromJson(row);
    return CloudProfile(
      displayName: profile.displayName,
      handle: profile.handle,
      school: profile.school,
      program: profile.program,
      yearOfStudy: profile.yearOfStudy,
      interests: profile.interests,
      website: profile.website,
      bio: profile.bio,
      avatarUrl: await avatarUrlFor(row),
    );
  }

  static Future<void> updateMyDisplayName(String displayName) async {
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('Sign in before changing your display name.');
    }
    final normalizedName = displayName.trim();
    if (normalizedName.isEmpty || normalizedName.length > 80) {
      throw const FormatException(
        'Display name must be between 1 and 80 characters.',
      );
    }

    await client
        .from('profiles')
        .update({'display_name': normalizedName})
        .eq('id', user.id);
  }

  static Future<void> changeMyPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final email = client.auth.currentUser?.email;
    if (email == null || email.isEmpty) {
      throw StateError('A password-based account is required.');
    }
    await client.auth.signInWithPassword(
      email: email,
      password: currentPassword,
    );
    await client.auth.updateUser(UserAttributes(password: newPassword));
  }

  static Future<bool> loadMyProfilePrivacy() async {
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('Sign in before loading privacy settings.');
    }
    final row = await client
        .from('profiles')
        .select('is_private')
        .eq('id', user.id)
        .single();
    return row['is_private'] as bool;
  }

  static Future<void> setMyProfilePrivacy(bool isPrivate) async {
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('Sign in before changing privacy settings.');
    }
    await client
        .from('profiles')
        .update({'is_private': isPrivate})
        .eq('id', user.id);
  }

  static Future<void> deleteMyAccount({required String password}) async {
    await client.functions.invoke(
      'delete-account',
      body: {'password': password},
    );
  }

  static Future<List<Map<String, dynamic>>> loadAcademicCohorts() async {
    final rows = await client
        .from('academic_cohorts')
        .select(
          'id, school, program, academic_year, class_rep_name, '
          'campus_groups(id, name, group_type)',
        )
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  static Future<List<Map<String, dynamic>>> loadFeed() async {
    final posts = await client
        .from('posts')
        .select('id, author_id, body, visibility, created_at')
        .order('created_at', ascending: false)
        .limit(30);
    if (posts.isEmpty) return [];

    final authorIds = posts
        .map((post) => post['author_id'] as String)
        .toSet()
        .toList();
    final profiles = await client
        .from('profiles')
        .select('id, display_name, avatar_url, updated_at')
        .inFilter('id', authorIds);
    final profilesById = {
      for (final profile in profiles) profile['id'] as String: profile,
    };

    final postIds = posts.map((post) => post['id'] as String).toList();
    final media = await client
        .from('post_media')
        .select('post_id, storage_path')
        .inFilter('post_id', postIds)
        .order('position');
    final mediaByPost = <String, String>{};
    for (final item in media) {
      try {
        mediaByPost[item['post_id'] as String] = await client.storage
            .from('post-media')
            .createSignedUrl(item['storage_path'] as String, 3600);
      } on Exception {
        // A missing or expired media object should not hide the rest of the feed.
      }
    }

    final reactionRows = await client
        .from('reactions')
        .select('post_id, user_id, reaction_type')
        .inFilter('post_id', postIds);
    final commentRows = await client
        .from('comments')
        .select('post_id, body')
        .inFilter('post_id', postIds)
        .order('created_at');
    const reactionLabels = {
      'like': 'Like',
      'love': 'Love',
      'haha': 'Laugh',
      'wow': 'Wow',
      'sad': 'Sad',
      'angry': 'Angry',
    };
    final reactionsByPost = <String, Map<String, int>>{};
    final myReactionsByPost = <String, String>{};
    final currentUserId = client.auth.currentUser?.id;
    for (final row in reactionRows) {
      final postId = row['post_id'] as String;
      final reaction = reactionLabels[row['reaction_type'] as String];
      if (reaction == null) continue;
      final counts = reactionsByPost.putIfAbsent(postId, () => {});
      counts[reaction] = (counts[reaction] ?? 0) + 1;
      if (row['user_id'] == currentUserId) {
        myReactionsByPost[postId] = reaction;
      }
    }
    final commentsByPost = <String, List<String>>{};
    for (final row in commentRows) {
      commentsByPost
          .putIfAbsent(row['post_id'] as String, () => [])
          .add(row['body'] as String);
    }

    return Future.wait(
      posts.map(
        (post) async => {
          ...post,
          'author_name':
              profilesById[post['author_id']]?['display_name'] ??
              'ZitFace member',
          'author_avatar_url': profilesById[post['author_id']] == null
              ? ''
              : await avatarUrlFor(profilesById[post['author_id']]!),
          'image_url': mediaByPost[post['id']],
          'reactions': reactionsByPost[post['id']] ?? <String, int>{},
          'my_reaction': myReactionsByPost[post['id']],
          'comments': commentsByPost[post['id']] ?? <String>[],
        },
      ),
    );
  }

  static Future<void> createPost({
    required String body,
    required String visibility,
    Uint8List? imageBytes,
    String imageContentType = 'image/jpeg',
  }) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Sign in before creating a post.');
    }
    if (body.trim().isEmpty && imageBytes == null) {
      throw const FormatException('Write something before posting.');
    }
    if (!const {'public', 'friends', 'private'}.contains(visibility)) {
      throw const FormatException('Choose a valid post audience.');
    }
    if (imageBytes != null && imageBytes.lengthInBytes > 10485760) {
      throw const FormatException('Post images must be 10 MB or smaller.');
    }
    if (imageBytes != null &&
        !const {
          'image/jpeg',
          'image/png',
          'image/webp',
        }.contains(imageContentType)) {
      throw const FormatException('Choose a JPEG, PNG, or WebP image.');
    }

    final row = await client
        .from('posts')
        .insert({
          'author_id': userId,
          'body': body.trim(),
          'visibility': visibility,
        })
        .select('id')
        .single();
    if (imageBytes == null) return;

    final postId = row['id'] as String;
    final storagePath = '$userId/$postId/image';
    try {
      await client.storage
          .from('post-media')
          .uploadBinary(
            storagePath,
            imageBytes,
            fileOptions: FileOptions(
              contentType: imageContentType,
              upsert: false,
            ),
          );
      await client.from('post_media').insert({
        'post_id': postId,
        'storage_path': storagePath,
        'media_type': 'image',
        'content_type': imageContentType,
        'position': 0,
      });
    } on Exception {
      try {
        await client.storage.from('post-media').remove([storagePath]);
      } on Exception {
        // Keep the original publish error if storage cleanup also fails.
      }
      try {
        await client.from('posts').delete().eq('id', postId);
      } on Exception {
        // Keep the original publish error if post cleanup also fails.
      }
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> loadStories() async {
    final rows = await client
        .from('stories')
        .select(
          'id, author_id, storage_path, media_type, duration_seconds, '
          'caption, visibility, audio_path, audio_content_type, created_at, '
          'expires_at, story_views(count)',
        )
        .gt('expires_at', DateTime.now().toUtc().toIso8601String())
        .order('created_at', ascending: false)
        .limit(50);
    if (rows.isEmpty) return [];

    final authorIds = rows
        .map((row) => row['author_id'] as String)
        .toSet()
        .toList();
    final profiles = await client
        .from('profiles')
        .select('id, display_name, avatar_url, updated_at')
        .inFilter('id', authorIds);
    final profilesById = {
      for (final profile in profiles) profile['id'] as String: profile,
    };

    final stories = <Map<String, dynamic>>[];
    for (final row in rows) {
      try {
        final imageUrl = await client.storage
            .from('story-media')
            .createSignedUrl(row['storage_path'] as String, 3600);
        String? audioUrl;
        final audioPath = row['audio_path'] as String?;
        if (audioPath != null) {
          try {
            audioUrl = await client.storage
                .from('story-audio')
                .createSignedUrl(audioPath, 3600);
          } on Exception {
            audioUrl = null;
          }
        }
        stories.add({
          ...row,
          'author_name':
              profilesById[row['author_id']]?['display_name'] ??
              'ZitFace member',
          'author_avatar_url': profilesById[row['author_id']] == null
              ? ''
              : await avatarUrlFor(profilesById[row['author_id']]!),
          'image_url': imageUrl,
          'audio_url': audioUrl,
          'views_count':
              ((row['story_views'] as List?)?.firstOrNull
                      as Map<String, dynamic>?)?['count']
                  as int? ??
              0,
        });
      } on Exception {
        // Skip unavailable media without hiding other stories.
      }
    }
    return stories;
  }

  static Future<void> createStory({
    required Uint8List mediaBytes,
    required String mediaType,
    required String contentType,
    int? durationSeconds,
    String caption = '',
    String visibility = 'friends',
    Uint8List? audioBytes,
    String? audioContentType,
    bool audioRightsConfirmed = false,
  }) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Sign in before creating a story.');
    }
    if (mediaBytes.isEmpty || mediaBytes.lengthInBytes > 52428800) {
      throw const FormatException(
        'Story media must be between 1 byte and 50 MB.',
      );
    }
    if (mediaType != 'image' && mediaType != 'video') {
      throw const FormatException('Choose a photo or video story.');
    }
    final allowedTypes = mediaType == 'image'
        ? const {'image/jpeg', 'image/png', 'image/webp'}
        : const {'video/mp4', 'video/quicktime'};
    if (!allowedTypes.contains(contentType)) {
      throw FormatException(
        mediaType == 'image'
            ? 'Choose a JPEG, PNG, or WebP story image.'
            : 'Choose an MP4 or MOV video.',
      );
    }
    if ((mediaType == 'image' && durationSeconds != null) ||
        (mediaType == 'video' &&
            (durationSeconds == null ||
                durationSeconds < 1 ||
                durationSeconds > 60))) {
      throw const FormatException('Story videos must be 1 to 60 seconds long.');
    }
    if (!const {'public', 'friends'}.contains(visibility)) {
      throw const FormatException('Choose who can view this story.');
    }
    const allowedAudioTypes = {
      'audio/mpeg',
      'audio/mp4',
      'audio/aac',
      'audio/wav',
      'audio/ogg',
    };
    if (audioBytes != null &&
        (audioBytes.isEmpty ||
            audioBytes.lengthInBytes > 10485760 ||
            audioContentType == null ||
            !allowedAudioTypes.contains(audioContentType))) {
      throw const FormatException(
        'Choose an MP3, M4A, AAC, WAV, or OGG soundtrack up to 10 MB.',
      );
    }
    if (audioBytes != null && !audioRightsConfirmed) {
      throw const FormatException(
        'Confirm that you have rights to use this soundtrack.',
      );
    }
    if (audioBytes == null &&
        (audioContentType != null || audioRightsConfirmed)) {
      throw const FormatException(
        'Select a soundtrack before confirming rights.',
      );
    }
    if (mediaType == 'image' &&
        !const {
          'image/jpeg',
          'image/png',
          'image/webp',
        }.contains(contentType)) {
      throw const FormatException('Choose a valid story image.');
    }
    final normalizedCaption = caption.trim();
    if (normalizedCaption.length > 240) {
      throw const FormatException(
        'Story captions must be 240 characters or less.',
      );
    }

    final randomSuffix = Random.secure().nextInt(1 << 32);
    final storagePath =
        '$userId/${DateTime.now().toUtc().microsecondsSinceEpoch}_$randomSuffix';
    final audioPath = audioBytes == null ? null : '$storagePath/audio';
    final row = await client
        .from('stories')
        .insert({
          'author_id': userId,
          'storage_path': storagePath,
          'media_type': mediaType,
          'duration_seconds': durationSeconds,
          'caption': normalizedCaption,
          'visibility': visibility,
          'audio_path': audioPath,
          'audio_content_type': audioBytes == null ? null : audioContentType,
          'audio_rights_confirmed': audioBytes != null && audioRightsConfirmed,
        })
        .select('id')
        .single();
    final storyId = row['id'] as String;

    try {
      await client.storage
          .from('story-media')
          .uploadBinary(
            storagePath,
            mediaBytes,
            fileOptions: FileOptions(contentType: contentType, upsert: false),
          );
      if (audioBytes != null && audioPath != null && audioContentType != null) {
        await client.storage
            .from('story-audio')
            .uploadBinary(
              audioPath,
              audioBytes,
              fileOptions: FileOptions(
                contentType: audioContentType,
                upsert: false,
              ),
            );
      }
    } on Exception {
      try {
        if (audioPath != null) {
          await client.storage.from('story-audio').remove([audioPath]);
        }
      } on Exception {
        // Preserve the original upload error if cleanup also fails.
      }
      try {
        await client.from('stories').delete().eq('id', storyId);
      } on Exception {
        // Preserve the upload error if cleanup also fails.
      }
      rethrow;
    }
  }

  static Future<void> deleteStory({
    required String storyId,
    required String storagePath,
  }) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Sign in before deleting a story.');
    }
    final story = await client
        .from('stories')
        .select('id, audio_path')
        .eq('id', storyId)
        .eq('author_id', userId)
        .maybeSingle();
    if (story == null) return;

    await client.storage.from('story-media').remove([storagePath]);
    final audioPath = story['audio_path'] as String?;
    if (audioPath != null) {
      await client.storage.from('story-audio').remove([audioPath]);
    }
    await client.from('stories').delete().eq('id', storyId);
  }

  static Future<void> recordStoryView({
    required String storyId,
    required String authorId,
  }) async {
    final viewerId = client.auth.currentUser?.id;
    if (viewerId == null) {
      throw StateError('Sign in before viewing stories.');
    }
    if (viewerId == authorId) return;

    final existing = await client
        .from('story_views')
        .select('story_id')
        .eq('story_id', storyId)
        .eq('viewer_id', viewerId)
        .maybeSingle();
    if (existing != null) return;

    await client.from('story_views').insert({
      'story_id': storyId,
      'viewer_id': viewerId,
    });
  }

  static Future<void> setPostReaction({
    required String postId,
    required String? reaction,
  }) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Sign in before reacting to a post.');
    }
    const reactionTypes = {
      'Like': 'like',
      'Love': 'love',
      'Laugh': 'haha',
      'Wow': 'wow',
      'Sad': 'sad',
      'Angry': 'angry',
    };
    final reactionType = reaction == null ? null : reactionTypes[reaction];
    if (reaction != null && reactionType == null) {
      throw const FormatException('Choose a valid reaction.');
    }

    final existing = await client
        .from('reactions')
        .select('reaction_type')
        .eq('post_id', postId)
        .eq('user_id', userId)
        .maybeSingle();
    if (reactionType == null) {
      if (existing != null) {
        await client
            .from('reactions')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', userId);
      }
      return;
    }
    if (existing?['reaction_type'] == reactionType) return;
    if (existing != null) {
      await client
          .from('reactions')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId);
    }
    await client.from('reactions').insert({
      'post_id': postId,
      'user_id': userId,
      'reaction_type': reactionType,
    });
  }

  static Future<void> addPostComment({
    required String postId,
    required String body,
  }) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Sign in before commenting on a post.');
    }
    final normalizedBody = body.trim();
    if (normalizedBody.isEmpty) {
      throw const FormatException('Write a comment before sending.');
    }
    await client.from('comments').insert({
      'post_id': postId,
      'author_id': userId,
      'body': normalizedBody,
    });
  }

  static Future<List<Map<String, dynamic>>> loadDiscoverableProfiles() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Sign in before discovering profiles.');
    }
    final rows = await client
        .from('profiles')
        .select('id, display_name, school, bio, avatar_url, updated_at')
        .neq('id', userId)
        .order('display_name')
        .limit(100);
    return Future.wait(
      rows.map(
        (row) async => <String, dynamic>{
          ...row,
          'avatar_display_url': await avatarUrlFor(row),
        },
      ),
    );
  }

  static Future<int> loadMyPostCount() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Sign in before loading contributions.');
    }
    return await client.from('posts').count().eq('author_id', userId);
  }

  static Future<Set<String>> loadSentFriendRequests() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Sign in before loading friend requests.');
    }
    final rows = await client
        .from('friend_requests')
        .select('recipient_id, status')
        .eq('sender_id', userId)
        .eq('status', 'pending');
    return rows.map((row) => row['recipient_id'] as String).toSet();
  }

  static Future<void> sendFriendRequest(String recipientId) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Sign in before sending friend requests.');
    }
    await client.from('friend_requests').insert({
      'sender_id': userId,
      'recipient_id': recipientId,
    });
  }

  static Future<String> openDirectConversation(String peerId) async {
    final conversationId = await client.rpc(
      'open_direct_conversation',
      params: {'p_peer_id': peerId},
    );
    if (conversationId is! String) {
      throw StateError('The conversation could not be opened.');
    }
    return conversationId;
  }

  static Future<List<Map<String, dynamic>>> loadConversations() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Sign in before loading conversations.');
    }
    final memberships = await client
        .from('conversation_members')
        .select('conversation_id')
        .eq('user_id', userId);
    final conversationIds = memberships
        .map((row) => row['conversation_id'] as String)
        .toList();
    if (conversationIds.isEmpty) return [];

    final conversations = await client
        .from('conversations')
        .select('id, title, conversation_type, created_at')
        .inFilter('id', conversationIds)
        .order('created_at', ascending: false);
    final members = await client
        .from('conversation_members')
        .select('conversation_id, user_id')
        .inFilter('conversation_id', conversationIds);
    final peerIds = members
        .map((row) => row['user_id'] as String)
        .where((id) => id != userId)
        .toSet()
        .toList();
    final profiles = peerIds.isEmpty
        ? <Map<String, dynamic>>[]
        : List<Map<String, dynamic>>.from(
            await client
                .from('profiles')
                .select('id, display_name, school, avatar_url, updated_at')
                .inFilter('id', peerIds),
          );
    final profilesById = {
      for (final profile in profiles) profile['id'] as String: profile,
    };
    final messages = await client
        .from('messages')
        .select('conversation_id, sender_id, body, created_at')
        .inFilter('conversation_id', conversationIds)
        .order('created_at', ascending: false)
        .limit(200);
    final latestMessageByConversation = <String, Map<String, dynamic>>{};
    for (final message in messages) {
      latestMessageByConversation.putIfAbsent(
        message['conversation_id'] as String,
        () => Map<String, dynamic>.from(message),
      );
    }

    return Future.wait(
      conversations.map((conversation) async {
        final conversationId = conversation['id'] as String;
        final type = conversation['conversation_type'] as String;
        final member = members.cast<Map<String, dynamic>?>().firstWhere(
          (row) =>
              row?['conversation_id'] == conversationId &&
              row?['user_id'] != userId,
          orElse: () => null,
        );
        final peer = profilesById[member?['user_id']];
        final latest = latestMessageByConversation[conversationId];
        return <String, dynamic>{
          'id': conversationId,
          'peer_id': member?['user_id'],
          'name': type == 'group'
              ? conversation['title'] as String? ?? 'Group conversation'
              : peer?['display_name'] as String? ?? 'ZitFace member',
          'school': type == 'group'
              ? 'Group conversation'
              : peer?['school'] as String? ?? '',
          'avatar_url': type == 'direct' && peer != null
              ? await avatarUrlFor(peer)
              : '',
          'message': latest?['body'] as String? ?? 'No messages yet',
          'time':
              latest?['created_at'] as String? ?? conversation['created_at'],
          'unread': 0,
          'isOnline': false,
          'avatarIcon': type == 'group' ? 'group' : 'person',
        };
      }),
    );
  }

  static Stream<List<Map<String, dynamic>>> watchMessages(
    String conversationId,
  ) {
    return client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at');
  }

  static Future<void> sendMessage({
    required String conversationId,
    required String body,
  }) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Sign in before sending a message.');
    }
    final normalizedBody = body.trim();
    if (normalizedBody.isEmpty) {
      throw const FormatException('Write a message before sending.');
    }
    await client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': userId,
      'body': normalizedBody,
    });
  }

  static Future<List<Map<String, dynamic>>> loadMarketListings() async {
    final rows = await client
        .from('market_listings')
        .select(
          'id, seller_id, title, price, category, description, created_at, image_path',
        )
        .eq('status', 'active')
        .order('created_at', ascending: false)
        .limit(100);
    if (rows.isEmpty) return [];

    final sellerIds = rows
        .map((row) => row['seller_id'] as String)
        .toSet()
        .toList();
    final sellers = await client
        .from('profiles')
        .select('id, display_name, avatar_url, updated_at')
        .inFilter('id', sellerIds);
    final sellersById = {
      for (final seller in sellers) seller['id'] as String: seller,
    };

    return Future.wait(
      rows.map((row) async {
        final path = row['image_path'] as String?;
        return <String, dynamic>{
          ...row,
          'seller':
              sellersById[row['seller_id']]?['display_name'] ??
              'ZitFace member',
          'seller_avatar_url': sellersById[row['seller_id']] == null
              ? ''
              : await avatarUrlFor(sellersById[row['seller_id']]!),
          if (path != null)
            'image_url': await client.storage
                .from('market-media')
                .createSignedUrl(path, 3600),
        };
      }),
    );
  }

  static Future<Map<String, dynamic>> createMarketListing({
    required String title,
    required String price,
    required String category,
    required String description,
    Uint8List? imageBytes,
    String? imageContentType,
  }) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Sign in before creating a listing.');
    }
    final normalizedTitle = title.trim();
    final normalizedDescription = description.trim();
    final normalizedPrice = double.tryParse(price.trim());
    if (normalizedTitle.isEmpty || normalizedTitle.length > 120) {
      throw const FormatException(
        'Title must be between 1 and 120 characters.',
      );
    }
    if (normalizedPrice == null ||
        !normalizedPrice.isFinite ||
        normalizedPrice < 0) {
      throw const FormatException('Enter a valid ZMW price.');
    }
    if (!const {
      'Textbooks',
      'Electronics',
      'Hostel Gear',
      'Apparel',
      'Services',
    }.contains(category)) {
      throw const FormatException('Choose a valid listing category.');
    }
    if (normalizedDescription.length > 2000) {
      throw const FormatException(
        'Description must be 2000 characters or less.',
      );
    }
    if (imageBytes != null &&
        (imageBytes.isEmpty || imageBytes.lengthInBytes > 10485760)) {
      throw const FormatException(
        'Listing images must be between 1 byte and 10 MB.',
      );
    }
    if (imageBytes != null &&
        !const {
          'image/jpeg',
          'image/png',
          'image/webp',
        }.contains(imageContentType)) {
      throw const FormatException('Choose a JPEG, PNG, or WebP image.');
    }

    final profile = await loadMyProfile();
    String? imagePath;
    if (imageBytes != null) {
      final random = Random.secure();
      final token = List.generate(
        16,
        (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join();
      imagePath = '$userId/$token/image';
      await client.storage
          .from('market-media')
          .uploadBinary(
            imagePath,
            imageBytes,
            fileOptions: FileOptions(
              contentType: imageContentType,
              upsert: false,
            ),
          );
    }
    try {
      final imageUrl = imagePath == null
          ? null
          : await client.storage
                .from('market-media')
                .createSignedUrl(imagePath, 3600);
      final row = await client
          .from('market_listings')
          .insert({
            'seller_id': userId,
            'title': normalizedTitle,
            'price': normalizedPrice,
            'category': category,
            'description': normalizedDescription,
            'image_path': imagePath,
          })
          .select(
            'id, seller_id, title, price, category, description, created_at, image_path',
          )
          .single();
      return {
        ...row,
        'seller': profile.displayName,
        'seller_avatar_url': profile.avatarUrl,
        'image_url': ?imageUrl,
      };
    } on Exception catch (error) {
      if (imagePath != null) {
        try {
          await client.storage.from('market-media').remove([imagePath]);
        } on Exception catch (cleanupError) {
          throw StateError(
            'Could not publish listing: $error. Image cleanup failed: $cleanupError',
          );
        }
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> createAcademicCohort({
    required String school,
    required String program,
    required int academicYear,
    required String classRepName,
  }) async {
    final id = await client.rpc(
      'create_academic_cohort',
      params: {
        'p_school': school.trim(),
        'p_program': program.trim(),
        'p_academic_year': academicYear,
        'p_class_rep_name': classRepName.trim(),
      },
    );
    return await client
        .from('academic_cohorts')
        .select(
          'id, school, program, academic_year, class_rep_name, '
          'campus_groups(id, name, group_type)',
        )
        .eq('id', id as String)
        .single();
  }

  static Future<bool> isGroupMember(String groupId) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Sign in before viewing group membership.');
    }
    final membership = await client
        .from('group_members')
        .select('group_id')
        .eq('group_id', groupId)
        .eq('user_id', userId)
        .maybeSingle();
    return membership != null;
  }

  static Future<void> setGroupMembership({
    required String groupId,
    required bool joined,
  }) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Sign in before changing group membership.');
    }

    if (joined) {
      await client.from('group_members').insert({
        'group_id': groupId,
        'user_id': userId,
      });
    } else {
      await client
          .from('group_members')
          .delete()
          .eq('group_id', groupId)
          .eq('user_id', userId);
    }
  }
}
