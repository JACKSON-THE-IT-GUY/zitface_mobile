import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';
import '../widget/glass_card.dart';
import 'menu_screen.dart';
import 'create_post_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onProfileTap;

  const HomeScreen({super.key, this.onProfileTap});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _storyImageBytes;
  final List<_HomePost> _createdPosts = [];
  final List<String> _sampleComments = [];
  String? _sampleReaction;
  int _sampleCommentCount = 300;
  final Map<String, int> _sampleReactionCounts = {
    '❤️': 15360,
    '👍': 0,
    '😂': 0,
    '😮': 0,
    '😢': 0,
  };

  static const List<String> _reactionOptions = ['❤️', '👍', '😂', '😮', '😢'];

  void _openMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.pageBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.88,
        child: const MenuScreen(),
      ),
    );
  }

  Future<void> _openCreatePost(BuildContext context) async {
    final post = await showModalBottomSheet<Map<String, Object?>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreatePostScreen(),
    );
    if (post == null || !mounted) return;
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

  void _setPostReaction(_HomePost post, String? reaction) {
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

  Future<void> _chooseReaction({
    required String? selected,
    required ValueChanged<String> onSelected,
  }) async {
    final reaction = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (final reaction in _reactionOptions)
                IconButton(
                  tooltip: _reactionNames[reaction],
                  onPressed: () => Navigator.pop(context, reaction),
                  icon: Text(reaction, style: const TextStyle(fontSize: 28)),
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
  }) async {
    final comment = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CommentsSheet(comments: comments),
    );
    if (comment == null || !mounted) return;
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

  static const Map<String, String> _reactionNames = {
    '❤️': 'Love',
    '👍': 'Like',
    '😂': 'Laugh',
    '😮': 'Wow',
    '😢': 'Sad',
  };

  Future<void> _pickStoryImage() async {
    try {
      final image = await _imagePicker.pickImage(source: ImageSource.gallery);
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        final isDark = currentMode == ThemeMode.dark;
        final surfaceColor = isDark
            ? AppColors.textPrimary.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.05);
        final mutedText = isDark ? AppColors.textSecondary : Colors.black54;
        final bodyText = isDark ? AppColors.textPrimary : Colors.black87;
        final softSurface = isDark
            ? Colors.black.withValues(alpha: 0.3)
            : AppColors.secondarySurface;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ZITFACE',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Row(
                        children: [
                          _CircleIconButton(icon: Icons.search, onTap: () {}),
                          const SizedBox(width: 10),
                          // Facebook-style Menu Trigger
                          _CircleIconButton(
                            icon: Icons.menu,
                            onTap: () => _openMenu(context),
                          ),
                          const SizedBox(width: 10),
                          _CircleIconButton(
                            icon: Icons.person_outline,
                            tooltip: 'Profile',
                            onTap:
                                widget.onProfileTap ??
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ProfileScreen(),
                                    ),
                                  );
                                },
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
                              backgroundColor: AppColors.secondarySurface
                                  .withValues(alpha: 0.1),
                              child: const Icon(
                                Icons.person,
                                color: AppColors.textPrimary,
                                size: 18,
                              ),
                            ),
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
                      for (final post in _createdPosts) ...[
                        _buildCreatedPost(
                          post,
                          bodyText: bodyText,
                          mutedText: mutedText,
                          surfaceColor: surfaceColor,
                        ),
                        const SizedBox(height: 16),
                      ],
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
                                    backgroundColor: AppColors.secondarySurface
                                        .withValues(alpha: 0.1),
                                    child: const Icon(
                                      Icons.person,
                                      color: AppColors.textPrimary,
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
                                          fontSize: 11,
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
                              child: const Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  color: AppColors.textSecondary,
                                  size: 36,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                              child: Text(
                                'Liked by marina and 15,360 others',
                                style: TextStyle(
                                  color: mutedText,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                              child: _buildPostSummary(
                                _sampleReactionCounts,
                                _sampleCommentCount,
                              ),
                            ),
                            _buildPostActions(
                              selected: _sampleReaction,
                              mutedText: mutedText,
                              onLike: () => _setSampleReaction(
                                _sampleReaction == '👍' ? null : '👍',
                              ),
                              onChooseReaction: () => _chooseReaction(
                                selected: _sampleReaction,
                                onSelected: _setSampleReaction,
                              ),
                              onComment: () => _openComments(
                                _sampleComments,
                                isSamplePost: true,
                              ),
                              onShare: () =>
                                  _sharePost('Check out this post on ZitFace!'),
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
    return GestureDetector(
      onTap: _pickStoryImage,
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
                    color: AppColors.secondarySurface,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.textSecondary,
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
                    backgroundColor: AppColors.secondarySurface.withValues(
                      alpha: 0.16,
                    ),
                    child: Icon(
                      _storyImageBytes == null
                          ? Icons.add
                          : Icons.edit_outlined,
                      color: AppColors.textPrimary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _storyImageBytes == null ? 'Create story' : 'Change photo',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
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
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0x337C3AED),
                  child: Icon(
                    Icons.person,
                    color: AppColors.textPrimary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You',
                        style: TextStyle(
                          color: bodyText,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${post.audience} • Just now',
                        style: TextStyle(color: mutedText, fontSize: 11),
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
              height: 220,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 220,
                color: surfaceColor,
                child: const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.textSecondary,
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
            mutedText: mutedText,
            onLike: () =>
                _setPostReaction(post, post.myReaction == '👍' ? null : '👍'),
            onChooseReaction: () => _chooseReaction(
              selected: post.myReaction,
              onSelected: (reaction) => _setPostReaction(post, reaction),
            ),
            onComment: () => _openComments(post.comments),
            onShare: () => _sharePost(
              post.text.isEmpty ? 'Check out this post on ZitFace!' : post.text,
            ),
          ),
        ],
      ),
    );
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
            child: Text(reaction, style: const TextStyle(fontSize: 14)),
          ),
        ),
        if (reactionTotal > 0)
          Text(
            '$reactionTotal',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        const Spacer(),
        if (commentCount > 0)
          Text(
            '$commentCount ${commentCount == 1 ? 'comment' : 'comments'}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
      ],
    );
  }

  Widget _buildPostActions({
    required String? selected,
    required Color mutedText,
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
            color: AppColors.textPrimary.withValues(alpha: 0.1),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: onLike,
                onLongPress: onChooseReaction,
                child: _postAction(
                  icon: isSelected ? null : Icons.thumb_up_alt_outlined,
                  reaction: selected,
                  label: isSelected ? _reactionNames[selected]! : 'Like',
                  selected: isSelected,
                  mutedText: mutedText,
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: onComment,
                child: _postAction(
                  icon: Icons.mode_comment_outlined,
                  label: 'Comment',
                  mutedText: mutedText,
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: onShare,
                child: _postAction(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  mutedText: mutedText,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _postAction({
    required String label,
    required Color mutedText,
    IconData? icon,
    String? reaction,
    bool selected = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (reaction != null)
            Text(reaction, style: const TextStyle(fontSize: 17))
          else
            Icon(
              icon,
              size: 18,
              color: selected ? AppColors.accent : mutedText,
            ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.accent : mutedText,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
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
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
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
}

class _HomePost {
  _HomePost({
    required this.text,
    required this.audience,
    required this.imageBytes,
  });

  final String text;
  final String audience;
  final Uint8List? imageBytes;
  final Map<String, int> reactions = {};
  final List<String> comments = [];
  String? myReaction;
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
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Comments',
              style: TextStyle(
                color: AppColors.textPrimary,
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
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                    ),
                  if (widget.comments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'Be the first to comment.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
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
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Write a comment...',
                      hintStyle: const TextStyle(
                        color: AppColors.textSecondary,
                      ),
                      filled: true,
                      fillColor: AppColors.textPrimary.withValues(alpha: 0.08),
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
                  icon: const Icon(Icons.send, color: AppColors.textPrimary),
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
              color: AppColors.textPrimary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.textPrimary.withValues(alpha: 0.05),
              ),
            ),
            child: Icon(icon, color: AppColors.textPrimary, size: 18),
          ),
        ),
      ),
    );
  }
}
