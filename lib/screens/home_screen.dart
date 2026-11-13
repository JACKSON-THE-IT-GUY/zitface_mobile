import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import '../theme/app_theme.dart';
import '../services/zitface_backend.dart';
import '../widget/glass_card.dart';
import '../widget/unavailable_feature.dart';
import '../widget/profile_avatar.dart';
import '../services/profile_identity.dart';
import 'menu_screen.dart';
import 'create_post_screen.dart';
import 'story_composer_sheet.dart';

const _homeActionColor = Color(0xFFC62828);

class HomeScreen extends StatefulWidget {
  final VoidCallback? onProfileTap;
  final VoidCallback? onPostPublished;
  final ValueChanged<int>? onNavigate;
  final ValueChanged<ProfileIdentity>? onProfileChanged;
  final ValueListenable<ProfileIdentity>? profile;
  final Listenable? refreshSignal;

  const HomeScreen({
    super.key,
    this.onProfileTap,
    this.onPostPublished,
    this.onNavigate,
    this.onProfileChanged,
    this.profile,
    this.refreshSignal,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const List<_StoryTrack> _storyMusicLibrary = [
    _StoryTrack(title: 'Paper Skies', artist: 'Mira Sol'),
    _StoryTrack(title: 'Soft Focus', artist: 'Jules Avery'),
    _StoryTrack(title: 'Late Train', artist: 'Noah Vale'),
    _StoryTrack(title: 'Sunny Side', artist: 'Lena Hart'),
    _StoryTrack(title: 'Neon Streets', artist: 'Kai Rivers'),
  ];

  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _storyImageBytes;
  _StoryTrack? _storyTrack;
  final List<Map<String, dynamic>> _cloudStories = [];
  bool _isLoadingCloudStories = ZitfaceBackend.isConfigured;
  bool _isPublishingStory = false;
  String? _cloudStoryError;
  final List<_HomePost> _createdPosts = [];
  final List<String> _sampleComments = [];
  String? _sampleReaction;
  int _sampleCommentCount = 300;
  bool _isLoadingCloudFeed = ZitfaceBackend.isConfigured;
  String? _cloudFeedError;
  final Map<String, int> _sampleReactionCounts = {
    'Love': 15360,
    'Like': 0,
    'Laugh': 0,
    'Wow': 0,
    'Sad': 0,
  };

  static const List<String> _reactionOptions = [
    'Love',
    'Like',
    'Laugh',
    'Wow',
    'Sad',
    'Angry',
  ];
  static final Map<String, String> _reactionEmojis = {
    'Love': String.fromCharCodes([0x2764, 0xfe0f]),
    'Like': String.fromCharCode(0x1f44d),
    'Laugh': String.fromCharCode(0x1f602),
    'Wow': String.fromCharCode(0x1f62e),
    'Sad': String.fromCharCode(0x1f622),
    'Angry': String.fromCharCode(0x1f621),
  };

  @override
  void initState() {
    super.initState();
    widget.refreshSignal?.addListener(_refresh);
    if (ZitfaceBackend.isConfigured) {
      unawaited(_loadCloudFeed());
      unawaited(_loadCloudStories());
    }
  }

  void _refresh() {
    if (ZitfaceBackend.isConfigured) {
      unawaited(_loadCloudFeed());
      unawaited(_loadCloudStories());
    }
  }

  @override
  void dispose() {
    widget.refreshSignal?.removeListener(_refresh);
    super.dispose();
  }

  Future<void> _loadCloudStories() async {
    setState(() {
      _isLoadingCloudStories = true;
      _cloudStoryError = null;
    });
    try {
      final rows = await ZitfaceBackend.loadStories();
      if (!mounted) return;
      setState(() {
        _cloudStories
          ..clear()
          ..addAll(rows);
        _isLoadingCloudStories = false;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _cloudStoryError = 'Could not load stories: $error';
        _isLoadingCloudStories = false;
      });
    }
  }

  Future<void> _loadCloudFeed() async {
    setState(() {
      _isLoadingCloudFeed = true;
      _cloudFeedError = null;
    });
    try {
      final rows = await ZitfaceBackend.loadFeed();
      if (!mounted) return;
      setState(() {
        _createdPosts
          ..clear()
          ..addAll(rows.map(_HomePost.fromCloudRow));
        _isLoadingCloudFeed = false;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _cloudFeedError = 'Could not load posts: $error';
        _isLoadingCloudFeed = false;
      });
    }
  }

  void _openMenu(BuildContext context) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close menu',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (context, _, _) => Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.88,
          height: double.infinity,
          child: Material(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: MenuScreen(
              onNavigate: widget.onNavigate,
              profile: widget.profile,
              onProfileChanged: widget.onProfileChanged,
            ),
          ),
        ),
      ),
      transitionBuilder: (context, animation, _, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
        child: child,
      ),
    );
  }

  Future<void> _openCreatePost(BuildContext context) async {
    final post = await showModalBottomSheet<Map<String, Object?>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreatePostScreen(profile: widget.profile?.value),
    );
    if (post == null || !mounted) return;
    if (ZitfaceBackend.isConfigured) {
      try {
        await ZitfaceBackend.createPost(
          body: post['text']! as String,
          visibility: post['visibility']! as String,
          imageBytes: post['imageBytes'] as Uint8List?,
          imageContentType: post['imageContentType'] as String? ?? 'image/jpeg',
        );
        widget.onPostPublished?.call();
        await _loadCloudFeed();
      } on Exception catch (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not publish post: $error')),
        );
      }
      return;
    }
    setState(() {
      _createdPosts.insert(
        0,
        _HomePost(
          text: post['text']! as String,
          audience: post['audience']! as String,
          imageBytes: post['imageBytes'] as Uint8List?,
        ),
      );
    });
    widget.onPostPublished?.call();
  }

  void _setSampleReaction(String? reaction) {
    setState(() {
      if (reaction == null || _sampleReaction == reaction) {
        final previousReaction = _sampleReaction;
        if (previousReaction != null) {
          _sampleReactionCounts[previousReaction] =
              (_sampleReactionCounts[previousReaction] ?? 1) - 1;
        }
        _sampleReaction = null;
      } else {
        if (_sampleReaction != null) {
          _sampleReactionCounts[_sampleReaction!] =
              (_sampleReactionCounts[_sampleReaction!] ?? 1) - 1;
        }
        _sampleReactionCounts[reaction] =
            (_sampleReactionCounts[reaction] ?? 0) + 1;
        _sampleReaction = reaction;
      }
    });
  }

  void _applyPostReaction(_HomePost post, String? reaction) {
    setState(() {
      if (reaction == null || post.myReaction == reaction) {
        final previousReaction = post.myReaction;
        if (previousReaction != null) {
          post.reactions[previousReaction] =
              (post.reactions[previousReaction] ?? 1) - 1;
        }
        post.myReaction = null;
      } else {
        if (post.myReaction != null) {
          post.reactions[post.myReaction!] =
              (post.reactions[post.myReaction!] ?? 1) - 1;
        }
        post.reactions[reaction] = (post.reactions[reaction] ?? 0) + 1;
        post.myReaction = reaction;
      }
    });
  }

  Future<void> _setPostReaction(_HomePost post, String? reaction) async {
    final previousReaction = post.myReaction;
    _applyPostReaction(post, reaction);
    if (post.id == null) return;

    try {
      await ZitfaceBackend.setPostReaction(
        postId: post.id!,
        reaction: post.myReaction,
      );
    } on Exception catch (error) {
      if (!mounted) return;
      _applyPostReaction(post, previousReaction);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save reaction: $error')),
      );
    }
  }

  Future<void> _chooseReaction({
    required String? selected,
    required ValueChanged<String> onSelected,
  }) async {
    final reaction = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (final reaction in _reactionOptions)
                IconButton(
                  tooltip: reaction,
                  onPressed: () => Navigator.pop(context, reaction),
                  icon: Text(
                    _reactionEmojis[reaction]!,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (reaction != null && mounted) onSelected(reaction);
  }

  Future<void> _openComments(
    List<String> comments, {
    bool isSamplePost = false,
    _HomePost? post,
  }) async {
    final comment = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CommentsSheet(comments: comments),
    );
    if (comment == null || !mounted) return;
    if (post?.id != null) {
      try {
        await ZitfaceBackend.addPostComment(postId: post!.id!, body: comment);
        await _loadCloudFeed();
      } on Exception catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not add comment: $error')),
        );
      }
      return;
    }
    setState(() {
      comments.add(comment);
      if (isSamplePost) _sampleCommentCount++;
    });
  }

  Future<void> _sharePost(String text) async {
    try {
      await SharePlus.instance.share(ShareParams(text: text));
    } on Exception catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not share post: $error')));
    }
  }

  Future<void> _pickStoryImage() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (image == null) return;

      final imageBytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() => _storyImageBytes = imageBytes);
    } on Exception catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not select a story image: $error')),
      );
    }
  }

  Future<void> _publishStory() async {
    if (_isPublishingStory) return;
    final story = await showModalBottomSheet<Map<String, Object?>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const StoryComposerSheet(),
    );
    if (story == null || !mounted) return;

    setState(() => _isPublishingStory = true);
    try {
      await ZitfaceBackend.createStory(
        mediaBytes: story['mediaBytes']! as Uint8List,
        mediaType: story['mediaType']! as String,
        contentType: story['contentType']! as String,
        durationSeconds: story['durationSeconds'] as int?,
        caption: story['caption'] as String? ?? '',
        visibility: story['visibility']! as String,
        audioBytes: story['audioBytes'] as Uint8List?,
        audioContentType: story['audioContentType'] as String?,
        audioRightsConfirmed: story['audioRightsConfirmed'] as bool? ?? false,
      );
      if (!mounted) return;
      await _loadCloudStories();
    } on Exception catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not publish story: $error')),
      );
    } finally {
      if (mounted) setState(() => _isPublishingStory = false);
    }
  }

  Future<void> _openCloudStory(Map<String, dynamic> story) async {
    try {
      await ZitfaceBackend.recordStoryView(
        storyId: story['id'] as String,
        authorId: story['author_id'] as String,
      );
    } on Exception catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not record story view: $error')),
      );
      return;
    }
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(dialogContext).size.height * 0.85,
            maxWidth: 440,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: MediaQuery.of(dialogContext).size.height * 0.68,
                width: double.infinity,
                child: story['media_type'] == 'video'
                    ? _CloudStoryVideoPlayer(url: story['image_url'] as String)
                    : Image.network(
                        story['image_url'] as String,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                size: 40,
                              ),
                            ),
                      ),
              ),
              ListTile(
                title: Text(story['author_name'] as String),
                subtitle: Text(
                  [
                    (story['caption'] as String?) ?? '',
                    if (story['author_id'] ==
                        ZitfaceBackend.client.auth.currentUser?.id)
                      '${story['views_count'] ?? 0} views',
                  ].where((text) => text.isNotEmpty).join(' · '),
                ),
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    if (story['author_id'] ==
                        ZitfaceBackend.client.auth.currentUser?.id)
                      IconButton(
                        tooltip: 'Delete story',
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await ZitfaceBackend.deleteStory(
                              storyId: story['id'] as String,
                              storagePath: story['storage_path'] as String,
                            );
                            if (!dialogContext.mounted) return;
                            Navigator.pop(dialogContext);
                            await _loadCloudStories();
                          } on Exception catch (error) {
                            if (!mounted) return;
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Could not delete story: $error'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.delete_outline),
                      ),
                    IconButton(
                      tooltip: 'Close story',
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              if (story['audio_url'] is String)
                _CloudStoryAudioPlayer(url: story['audio_url'] as String),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _chooseStoryMusic() async {
    final selectedTrack = await showModalBottomSheet<_StoryTrack>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Add music to your story',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final track in _storyMusicLibrary)
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.music_note,
                            color: AppColors.accent,
                          ),
                        ),
                        title: Text(
                          track.title,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          track.artist,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        onTap: () => Navigator.pop(context, track),
                      ),
                    ListTile(
                      leading: Icon(
                        Icons.music_off,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      title: Text(
                        'Continue without music',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      onTap: () => Navigator.pop(
                        context,
                        const _StoryTrack(title: '', artist: ''),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selectedTrack == null || !mounted) return;
    setState(
      () => _storyTrack = selectedTrack.title.isEmpty ? null : selectedTrack,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        final isDark = currentMode == ThemeMode.dark;
        final surfaceColor = isDark
            ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.05);
        final mutedText = Theme.of(context).colorScheme.onSurfaceVariant;
        final bodyText = Theme.of(context).colorScheme.onSurface;
        final softSurface = isDark
            ? Colors.black.withValues(alpha: 0.3)
            : Theme.of(context).colorScheme.surfaceContainerHighest;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 0,
                    vertical: 14,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _CircleIconButton(
                            icon: Icons.menu,
                            tooltip: 'Open menu',
                            onTap: () => _openMenu(context),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ZITFACE',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _CircleIconButton(
                            icon: Icons.search,
                            onTap: () => showUnavailableFeature(
                              context,
                              'Global search',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Tooltip(
                            message: 'Profile',
                            child: InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onTap: widget.onProfileTap,
                              child: _myAvatar(radius: 21),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.zero,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: Colors.transparent,
                        child: Row(
                          children: [
                            _myAvatar(radius: 21),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
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
                                          style: TextStyle(
                                            color: mutedText,
                                            fontSize: 13,
                                          ),
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
                      if (ZitfaceBackend.isConfigured && _isLoadingCloudFeed)
                        const LinearProgressIndicator(),
                      if (ZitfaceBackend.isConfigured &&
                          _cloudFeedError != null)
                        ListTile(
                          title: Text(_cloudFeedError!),
                          trailing: IconButton(
                            tooltip: 'Retry loading posts',
                            onPressed: _loadCloudFeed,
                            icon: const Icon(Icons.refresh),
                          ),
                        ),
                      if (ZitfaceBackend.isConfigured &&
                          !_isLoadingCloudFeed &&
                          _cloudFeedError == null &&
                          _createdPosts.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: Text('No posts yet.')),
                        ),
                      if (ZitfaceBackend.isConfigured && _isLoadingCloudStories)
                        const LinearProgressIndicator(),
                      if (ZitfaceBackend.isConfigured &&
                          _cloudStoryError != null)
                        ListTile(
                          title: Text(_cloudStoryError!),
                          trailing: IconButton(
                            tooltip: 'Retry loading stories',
                            onPressed: _loadCloudStories,
                            icon: const Icon(Icons.refresh),
                          ),
                        ),
                      SizedBox(
                        height: 166,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          children: [
                            _buildCreateStoryCard(),
                            if (ZitfaceBackend.isConfigured)
                              ..._cloudStories.map(_buildCloudStoryCard)
                            else ...[
                              _buildStoryCard('Jennifer'),
                              _buildStoryCard('Benjamin'),
                              _buildStoryCard('Edison'),
                            ],
                          ],
                        ),
                      ),
                      if (!ZitfaceBackend.isConfigured)
                        const SizedBox(height: 16),
                      for (final post in _createdPosts) ...[
                        _buildCreatedPost(
                          post,
                          bodyText: bodyText,
                          mutedText: mutedText,
                          surfaceColor: surfaceColor,
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (!ZitfaceBackend.isConfigured)
                        Container(
                          color: Colors.transparent,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest
                                          .withValues(alpha: 0.1),
                                      child: Icon(
                                        Icons.person,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                          style: TextStyle(
                                            color: mutedText,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
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
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: surfaceColor,
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.image_outlined,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                    size: 36,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  12,
                                  16,
                                  4,
                                ),
                                child: Text(
                                  'Liked by marina and 15,360 others',
                                  style: TextStyle(
                                    color: mutedText,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  8,
                                  12,
                                  0,
                                ),
                                child: _buildPostSummary(
                                  _sampleReactionCounts,
                                  _sampleCommentCount,
                                ),
                              ),
                              _buildPostActions(
                                selected: _sampleReaction,
                                onLike: () => _setSampleReaction(
                                  _sampleReaction == 'Like' ? null : 'Like',
                                ),
                                onChooseReaction: () => _chooseReaction(
                                  selected: _sampleReaction,
                                  onSelected: _setSampleReaction,
                                ),
                                onComment: () => _openComments(
                                  _sampleComments,
                                  isSamplePost: true,
                                ),
                                onShare: () => _sharePost(
                                  'Check out this post on ZitFace!',
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (!ZitfaceBackend.isConfigured)
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
    return GestureDetector(
      onTap: ZitfaceBackend.isConfigured ? _publishStory : _pickStoryImage,
      child: Container(
        width: 85,
        margin: const EdgeInsets.only(right: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_storyImageBytes != null)
                Image.memory(
                  _storyImageBytes!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                const GlassCard(
                  padding: EdgeInsets.zero,
                  child: SizedBox.expand(),
                ),
              if (_storyImageBytes != null)
                Container(color: Colors.black.withValues(alpha: 0.3)),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: _homeActionColor,
                    child: Icon(
                      _storyImageBytes == null
                          ? Icons.add
                          : Icons.edit_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isPublishingStory
                        ? 'Publishing...'
                        : _storyImageBytes == null
                        ? 'Create story'
                        : 'Change photo',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              if (_storyTrack != null)
                Positioned(
                  left: 4,
                  right: 4,
                  bottom: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.music_note,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            _storyTrack!.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (!ZitfaceBackend.isConfigured)
                Positioned(
                  top: 4,
                  right: 4,
                  child: IconButton(
                    tooltip: _storyTrack == null
                        ? 'Add story music'
                        : 'Change story music',
                    onPressed: _chooseStoryMusic,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.accent,
                      minimumSize: const Size(30, 30),
                      padding: const EdgeInsets.all(4),
                    ),
                    icon: const Icon(Icons.music_note, size: 18),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreatedPost(
    _HomePost post, {
    required Color bodyText,
    required Color mutedText,
    required Color surfaceColor,
  }) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                post.isMine && widget.profile != null
                    ? _myAvatar()
                    : ProfileAvatar(
                        name: post.authorName,
                        avatarUrl: post.avatarUrl,
                        radius: 18,
                      ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (post.isMine && widget.profile != null)
                        ValueListenableBuilder<ProfileIdentity>(
                          valueListenable: widget.profile!,
                          builder: (_, identity, _) => Text(
                            identity.name.isEmpty
                                ? post.authorName
                                : identity.name,
                            style: TextStyle(
                              color: bodyText,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        )
                      else
                        Text(
                          post.authorName,
                          style: TextStyle(
                            color: bodyText,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      Text(
                        '${post.audience} • ${post.createdAt == null ? 'Just now' : _relativeTime(post.createdAt!)}',
                        style: TextStyle(
                          color: mutedText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (post.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                post.text,
                style: TextStyle(color: bodyText, fontSize: 14, height: 1.4),
              ),
            ),
          if (post.imageBytes != null)
            Image.memory(
              post.imageBytes!,
              width: double.infinity,
              fit: BoxFit.fitWidth,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 220,
                color: surfaceColor,
                child: Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 36,
                  ),
                ),
              ),
            ),
          if (post.imageUrl != null)
            Image.network(
              post.imageUrl!,
              width: double.infinity,
              fit: BoxFit.fitWidth,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 220,
                color: surfaceColor,
                child: Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 36,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: _buildPostSummary(post.reactions, post.comments.length),
          ),
          _buildPostActions(
            selected: post.myReaction,
            onLike: () => _setPostReaction(
              post,
              post.myReaction == 'Like' ? null : 'Like',
            ),
            onChooseReaction: () => _chooseReaction(
              selected: post.myReaction,
              onSelected: (reaction) => _setPostReaction(post, reaction),
            ),
            onComment: () => _openComments(post.comments, post: post),
            onShare: () => _sharePost(
              post.text.isEmpty ? 'Check out this post on ZitFace!' : post.text,
            ),
          ),
        ],
      ),
    );
  }

  String _relativeTime(DateTime createdAt) {
    final age = DateTime.now().difference(createdAt);
    if (age.inMinutes < 1) return 'Just now';
    if (age.inHours < 1) return '${age.inMinutes} minutes ago';
    if (age.inDays < 1) return '${age.inHours} hours ago';
    return '${age.inDays} days ago';
  }

  Widget _buildPostSummary(Map<String, int> reactions, int commentCount) {
    final reactionTotal = reactions.values.fold<int>(
      0,
      (sum, count) => sum + count,
    );
    final activeReactions = _reactionOptions
        .where((reaction) => (reactions[reaction] ?? 0) > 0)
        .take(3)
        .toList();
    if (reactionTotal == 0 && commentCount == 0) {
      return const SizedBox(height: 8);
    }

    return Row(
      children: [
        ...activeReactions.map(
          (reaction) => Padding(
            padding: const EdgeInsets.only(right: 3),
            child: Text(
              _reactionEmojis[reaction]!,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
        if (reactionTotal > 0)
          Text(
            '$reactionTotal',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        const Spacer(),
        if (commentCount > 0)
          Text(
            '$commentCount ${commentCount == 1 ? 'comment' : 'comments'}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  Widget _buildPostActions({
    required String? selected,
    required VoidCallback onLike,
    required VoidCallback onChooseReaction,
    required VoidCallback onComment,
    required VoidCallback onShare,
  }) {
    final isSelected = selected != null;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Divider(
            height: 1,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.1),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: onLike,
                onLongPress: onChooseReaction,
                child: _postAction(
                  icon: isSelected
                      ? Text(
                          _reactionEmojis[selected]!,
                          style: const TextStyle(fontSize: 19),
                        )
                      : const Icon(Icons.thumb_up_alt_outlined),
                  label: isSelected ? selected : 'Like',
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: onComment,
                child: _postAction(
                  icon: const Icon(Icons.mode_comment_outlined),
                  label: 'Comment',
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: onShare,
                child: _postAction(
                  icon: const Icon(Icons.share_outlined),
                  label: 'Share',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _postAction({required String label, required Widget icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconTheme(
            data: const IconThemeData(size: 18, color: _homeActionColor),
            child: icon,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: _homeActionColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryCard(String name) {
    return Container(
      width: 112,
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
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCloudStoryCard(Map<String, dynamic> story) {
    return GestureDetector(
      onTap: () => _openCloudStory(story),
      child: Container(
        width: 112,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.accent, width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (story['media_type'] == 'video')
                Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Center(
                    child: Icon(Icons.play_circle_outline, size: 34),
                  ),
                )
              else
                Image.network(
                  story['image_url'] as String,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              Positioned(
                left: 4,
                top: 4,
                child: ProfileAvatar(
                  name: story['author_name'] as String,
                  avatarUrl: story['author_avatar_url'] as String? ?? '',
                  radius: 14,
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(5, 14, 5, 5),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black87],
                    ),
                  ),
                  child: Text(
                    story['author_name'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _myAvatar({double radius = 18}) {
    final profile = widget.profile;
    if (profile == null) return ProfileAvatar(radius: radius);
    return ValueListenableBuilder<ProfileIdentity>(
      valueListenable: profile,
      builder: (_, identity, _) => ProfileAvatar(
        name: identity.name,
        avatarUrl: identity.avatarUrl,
        photoData: identity.photoData,
        radius: radius,
      ),
    );
  }
}

class _HomePost {
  _HomePost({
    required this.text,
    required this.audience,
    required this.imageBytes,
    this.id,
    this.authorName = 'You',
    this.avatarUrl = '',
    this.isMine = true,
    this.createdAt,
    this.imageUrl,
    Map<String, int>? reactions,
    List<String>? comments,
    this.myReaction,
  }) : reactions = reactions ?? {},
       comments = comments ?? [];

  factory _HomePost.fromCloudRow(Map<String, dynamic> row) {
    final visibility = row['visibility'] as String;
    return _HomePost(
      text: row['body'] as String,
      id: row['id'] as String,
      audience: switch (visibility) {
        'public' => 'Public',
        'private' => 'Only me',
        _ => 'Friends',
      },
      imageBytes: null,
      authorName: row['author_name'] as String,
      avatarUrl: row['author_avatar_url'] as String? ?? '',
      isMine: row['author_id'] == ZitfaceBackend.client.auth.currentUser?.id,
      createdAt: DateTime.tryParse(row['created_at'] as String),
      imageUrl: row['image_url'] as String?,
      reactions: Map<String, int>.from(row['reactions'] as Map),
      comments: List<String>.from(row['comments'] as List),
      myReaction: row['my_reaction'] as String?,
    );
  }

  final String? id;
  final String text;
  final String audience;
  final Uint8List? imageBytes;
  final String authorName;
  final String avatarUrl;
  final bool isMine;
  final DateTime? createdAt;
  final String? imageUrl;
  final Map<String, int> reactions;
  final List<String> comments;
  String? myReaction;
}

class _StoryTrack {
  const _StoryTrack({required this.title, required this.artist});

  final String title;
  final String artist;
}

class _CloudStoryVideoPlayer extends StatefulWidget {
  const _CloudStoryVideoPlayer({required this.url});

  final String url;

  @override
  State<_CloudStoryVideoPlayer> createState() => _CloudStoryVideoPlayerState();
}

class _CloudStoryVideoPlayerState extends State<_CloudStoryVideoPlayer> {
  late final VideoPlayerController _controller;
  String? _errorMessage;
  bool _isMuted = true;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      await _controller.initialize();
      await _controller.setLooping(false);
      await _controller.setVolume(0);
      await _controller.play();
      if (mounted) setState(() {});
    } on Exception catch (error) {
      if (mounted) {
        setState(() => _errorMessage = 'Could not play video: $error');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    if (_controller.value.isPlaying) {
      await _controller.pause();
    } else {
      await _controller.play();
    }
    if (mounted) setState(() {});
  }

  Future<void> _toggleMute() async {
    _isMuted = !_isMuted;
    await _controller.setVolume(_isMuted ? 0 : 1);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!, textAlign: TextAlign.center));
    }
    if (!_controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
        ),
        IconButton.filledTonal(
          tooltip: _controller.value.isPlaying ? 'Pause story' : 'Play story',
          onPressed: _togglePlayback,
          icon: Icon(
            _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
          ),
        ),
        Positioned(
          left: 8,
          right: 8,
          bottom: 8,
          child: Row(
            children: [
              IconButton(
                tooltip: _isMuted ? 'Unmute story' : 'Mute story',
                onPressed: _toggleMute,
                icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up),
                color: Colors.white,
              ),
              Expanded(
                child: VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: Colors.white,
                    bufferedColor: Colors.white54,
                    backgroundColor: Colors.white24,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CloudStoryAudioPlayer extends StatefulWidget {
  const _CloudStoryAudioPlayer({required this.url});

  final String url;

  @override
  State<_CloudStoryAudioPlayer> createState() => _CloudStoryAudioPlayerState();
}

class _CloudStoryAudioPlayerState extends State<_CloudStoryAudioPlayer> {
  late final AudioPlayer _player;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    unawaited(_loadAudio());
  }

  Future<void> _loadAudio() async {
    try {
      await _player.setUrl(widget.url);
      await _player.setVolume(0.75);
    } on Exception catch (error) {
      if (mounted) setState(() => _errorMessage = 'Audio unavailable: $error');
    }
  }

  @override
  void dispose() {
    unawaited(_player.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(_errorMessage!, maxLines: 2),
      );
    }
    return StreamBuilder<PlayerState>(
      stream: _player.playerStateStream,
      initialData: _player.playerState,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data?.playing ?? false;
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Row(
            children: [
              IconButton(
                tooltip: isPlaying ? 'Pause soundtrack' : 'Play soundtrack',
                onPressed: () => isPlaying ? _player.pause() : _player.play(),
                icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
              ),
              const Expanded(child: Text('Story soundtrack')),
              StreamBuilder<Duration>(
                stream: _player.positionStream,
                initialData: Duration.zero,
                builder: (context, positionSnapshot) {
                  final duration = _player.duration ?? Duration.zero;
                  final position = positionSnapshot.data ?? Duration.zero;
                  return Text(
                    '${_formatAudioTime(position)} / ${_formatAudioTime(duration)}',
                    style: Theme.of(context).textTheme.labelSmall,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatAudioTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _CommentsSheet extends StatefulWidget {
  const _CommentsSheet({required this.comments});

  final List<String> comments;

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submitComment() {
    final comment = _controller.text.trim();
    if (comment.isEmpty) return;
    Navigator.pop(context, comment);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Comments',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final comment in widget.comments)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        radius: 16,
                        child: Icon(Icons.person, size: 16),
                      ),
                      title: Text(
                        comment,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  if (widget.comments.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'Be the first to comment.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Write a comment...',
                      hintStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      filled: true,
                      fillColor: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _submitComment(),
                  ),
                ),
                IconButton(
                  tooltip: 'Send comment',
                  onPressed: _submitComment,
                  style: IconButton.styleFrom(
                    backgroundColor: _homeActionColor,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip ?? '',
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _homeActionColor,
              shape: BoxShape.circle,
              border: Border.all(color: _homeActionColor),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}
