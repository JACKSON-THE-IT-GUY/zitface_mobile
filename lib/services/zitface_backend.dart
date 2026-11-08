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
    required this.bio,
    required this.avatarUrl,
  });

  factory CloudProfile.fromJson(Map<String, dynamic> json) {
    return CloudProfile(
      displayName: json['display_name'] as String,
      handle: json['handle'] as String,
      school: json['school'] as String,
      bio: json['bio'] as String,
      avatarUrl: json['avatar_url'] as String? ?? '',
    );
  }

  final String displayName;
  final String handle;
  final String school;
  final String bio;
  final String avatarUrl;
}

class ZitfaceBackend {
  ZitfaceBackend._();

  static bool get isConfigured =>
      SupabaseEnvironment.fromCompileTime.isConfigured;

  static SupabaseClient get client => Supabase.instance.client;

  static Future<CloudProfile> loadMyProfile() async {
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('Sign in before loading a profile.');
    }

    final row = await client
        .from('profiles')
        .select('display_name, handle, school, bio, avatar_url')
        .eq('id', user.id)
        .maybeSingle();
    if (row == null) {
      throw StateError(
        'Your profile was not created. Check that the social foundation '
        'migration has been applied.',
      );
    }

    final profile = CloudProfile.fromJson(row);
    final avatar = profile.avatarUrl;
    return CloudProfile(
      displayName: profile.displayName,
      handle: profile.handle,
      school: profile.school,
      bio: profile.bio,
      avatarUrl: avatar.isEmpty || Uri.tryParse(avatar)?.hasAuthority == true
          ? avatar
          : client.storage.from('avatars').getPublicUrl(avatar),
    );
  }

  static Future<CloudProfile> saveMyProfile({
    required String displayName,
    required String handle,
    required String school,
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
      newAvatarPath = '${user.id}/avatar.jpg';
      await client.storage
          .from('avatars')
          .uploadBinary(
            newAvatarPath,
            Uint8List.fromList(bytes),
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
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
        .select('display_name, handle, school, bio, avatar_url')
        .single();

    if (removeAvatar && newAvatarPath == null) {
      final oldAvatar = current['avatar_url'] as String?;
      if (oldAvatar != null && oldAvatar.isNotEmpty && !oldAvatar.startsWith('http')) {
        await client.storage.from('avatars').remove([oldAvatar]);
      }
    }

    final profile = CloudProfile.fromJson(row);
    return CloudProfile(
      displayName: profile.displayName,
      handle: profile.handle,
      school: profile.school,
      bio: profile.bio,
      avatarUrl: profile.avatarUrl.isEmpty
          ? ''
          : client.storage.from('avatars').getPublicUrl(profile.avatarUrl),
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
        .select('id, display_name')
        .inFilter('id', authorIds);
    final namesById = {
      for (final profile in profiles)
        profile['id'] as String: profile['display_name'] as String,
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

    return posts
        .map(
          (post) => {
            ...post,
            'author_name': namesById[post['author_id']] ?? 'ZitFace member',
            'image_url': mediaByPost[post['id']],
            'reactions': reactionsByPost[post['id']] ?? <String, int>{},
            'my_reaction': myReactionsByPost[post['id']],
            'comments': commentsByPost[post['id']] ?? <String>[],
          },
        )
        .toList();
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
        !const {'image/jpeg', 'image/png', 'image/webp'}.contains(
          imageContentType,
        )) {
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
        .select('id, author_id, storage_path, caption, created_at, expires_at')
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
        .select('id, display_name')
        .inFilter('id', authorIds);
    final namesById = {
      for (final profile in profiles)
        profile['id'] as String: profile['display_name'] as String,
    };

    final stories = <Map<String, dynamic>>[];
    for (final row in rows) {
      try {
        final imageUrl = await client.storage
            .from('story-media')
            .createSignedUrl(row['storage_path'] as String, 3600);
        stories.add({
          ...row,
          'author_name': namesById[row['author_id']] ?? 'ZitFace member',
          'image_url': imageUrl,
        });
      } on Exception {
        // Skip unavailable media without hiding other stories.
      }
    }
    return stories;
  }

  static Future<void> createStory({
    required Uint8List imageBytes,
    required String contentType,
    String caption = '',
  }) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Sign in before creating a story.');
    }
    if (imageBytes.isEmpty || imageBytes.lengthInBytes > 10485760) {
      throw const FormatException('Story images must be between 1 byte and 10 MB.');
    }
    if (!const {'image/jpeg', 'image/png', 'image/webp'}.contains(contentType)) {
      throw const FormatException('Choose a JPEG, PNG, or WebP story image.');
    }
    final normalizedCaption = caption.trim();
    if (normalizedCaption.length > 240) {
      throw const FormatException('Story captions must be 240 characters or less.');
    }

    final randomSuffix = Random.secure().nextInt(1 << 32);
    final storagePath =
        '$userId/${DateTime.now().toUtc().microsecondsSinceEpoch}_$randomSuffix';
    final row = await client
        .from('stories')
        .insert({
          'author_id': userId,
          'storage_path': storagePath,
          'media_type': 'image',
          'caption': normalizedCaption,
          'visibility': 'friends',
        })
        .select('id')
        .single();
    final storyId = row['id'] as String;

    try {
      await client.storage
          .from('story-media')
          .uploadBinary(
            storagePath,
            imageBytes,
            fileOptions: FileOptions(contentType: contentType, upsert: false),
          );
    } on Exception {
      try {
        await client.from('stories').delete().eq('id', storyId);
      } on Exception {
        // Preserve the upload error if cleanup also fails.
      }
      rethrow;
    }
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
        .select('id, display_name, school, bio')
        .neq('id', userId)
        .order('display_name')
        .limit(100);
    return List<Map<String, dynamic>>.from(rows);
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
                .select('id, display_name, school')
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

    return conversations.map((conversation) {
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
        'message': latest?['body'] as String? ?? 'No messages yet',
        'time': latest?['created_at'] as String? ?? conversation['created_at'],
        'unread': 0,
        'isOnline': false,
        'avatarIcon': type == 'group' ? 'group' : 'person',
      };
    }).toList();
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
        .select('id, seller_id, title, price, category, description, created_at')
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
        .select('id, display_name')
        .inFilter('id', sellerIds);
    final sellerNames = {
      for (final seller in sellers)
        seller['id'] as String: seller['display_name'] as String,
    };

    return rows
        .map(
          (row) => {
            ...row,
            'seller': sellerNames[row['seller_id']] ?? 'ZitFace member',
          },
        )
        .toList();
  }

  static Future<Map<String, dynamic>> createMarketListing({
    required String title,
    required String price,
    required String category,
    required String description,
  }) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Sign in before creating a listing.');
    }
    final normalizedTitle = title.trim();
    final normalizedDescription = description.trim();
    final normalizedPrice = double.tryParse(price.trim());
    if (normalizedTitle.isEmpty || normalizedTitle.length > 120) {
      throw const FormatException('Title must be between 1 and 120 characters.');
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
      throw const FormatException('Description must be 2000 characters or less.');
    }

    final row = await client
        .from('market_listings')
        .insert({
          'seller_id': userId,
          'title': normalizedTitle,
          'price': normalizedPrice,
          'category': category,
          'description': normalizedDescription,
        })
        .select('id, seller_id, title, price, category, description, created_at')
        .single();
    return {...row, 'seller': 'You'};
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
