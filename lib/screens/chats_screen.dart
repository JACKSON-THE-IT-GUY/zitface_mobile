import 'dart:async';

import 'package:flutter/material.dart';
import '../services/zitface_backend.dart';
import '../services/demo_chats.dart';
import '../widget/profile_avatar.dart';
import 'chat_detail_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key, this.refreshSignal});

  final Listenable? refreshSignal;

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final bool _cloudMode = ZitfaceBackend.isConfigured;
  bool _showUnreadOnly = false;
  bool _isLoadingCloudChats = ZitfaceBackend.isConfigured;

  final List<Map<String, dynamic>> _activePeers = ZitfaceBackend.isConfigured
      ? []
      : [
          {'name': 'SAM ', 'school': 'SICT', 'isOnline': true},
          {'name': 'JOE', 'school': 'SOE', 'isOnline': true},
          {'name': 'PHANSCIAH', 'school': 'SICT', 'isOnline': true},
          {'name': 'MATEO', 'school': 'SMNS', 'isOnline': true},
          {'name': 'PETER', 'school': 'SBE', 'isOnline': false},
        ];

  final List<Map<String, dynamic>> _chatThreads = ZitfaceBackend.isConfigured
      ? []
      : [
          {
            'name': 'Phanciah M.',
            'school': 'Computer Science',
            'message': 'Are we meeting at the main library later?',
            'time': '12:42 PM',
            'unread': 2,
            'isOnline': true,
            'avatarIcon': Icons.person_outline,
          },
          {
            'name': 'ICTAZ Tech Group',
            'school': 'SICT Official',
            'message':
                'Kondwani: The hackathon submission deadline was extended!',
            'time': '10:15 AM',
            'unread': 5,
            'isOnline': false,
            'avatarIcon': Icons.groups_outlined,
          },
          {
            'name': 'Victor Mundia',
            'school': 'Computer Science',
            'message': 'Pushed the updated backend routes to GitHub.',
            'time': 'Yesterday',
            'unread': 0,
            'isOnline': true,
            'avatarIcon': Icons.code_rounded,
          },
          {
            'name': 'Engineering Study Circle',
            'school': 'SOE Community',
            'message': 'Who has the past papers for Fluid Mechanics?',
            'time': 'Yesterday',
            'unread': 0,
            'isOnline': false,
            'avatarIcon': Icons.engineering_outlined,
          },
          {
            'name': 'Jackson Nsonga',
            'school': 'Built Environment',
            'message': 'Thanks for the architecture project notes!',
            'time': 'Monday',
            'unread': 0,
            'isOnline': false,
            'avatarIcon': Icons.architecture_outlined,
          },
        ];

  @override
  void initState() {
    super.initState();
    widget.refreshSignal?.addListener(_refresh);
    if (!_cloudMode) {
      DemoChats.changes.addListener(_loadDemoChats);
      _loadDemoChats();
    }
    if (_cloudMode) unawaited(_loadCloudChats());
  }

  void _refresh() {
    if (_cloudMode) unawaited(_loadCloudChats());
  }

  void _loadDemoChats() {
    setState(() {
      for (final chat in DemoChats.chats) {
        _chatThreads.removeWhere((thread) => thread['name'] == chat.name);
        _chatThreads.insert(0, {
          'name': chat.name,
          'school': chat.school,
          'message': chat.messages.last['text'],
          'time': 'Just now',
          'unread': 0,
          'isOnline': false,
          'avatarIcon': Icons.person_outline,
        });
      }
    });
  }

  Future<void> _loadCloudChats() async {
    try {
      final threads = await ZitfaceBackend.loadConversations();
      final profiles = await ZitfaceBackend.loadDiscoverableProfiles();
      if (!mounted) return;
      setState(() {
        _chatThreads
          ..clear()
          ..addAll(
            threads.map(
              (thread) => {
                ...thread,
                'avatarIcon': thread['avatarIcon'] == 'group'
                    ? Icons.groups_outlined
                    : Icons.person_outline,
                'time': _formatTime(thread['time'] as String?),
              },
            ),
          );
        _activePeers
          ..clear()
          ..addAll(
            profiles.map(
              (profile) => {
                'id': profile['id'],
                'name': profile['display_name'],
                'school': profile['school'] ?? '',
                'avatar_url': profile['avatar_display_url'] ?? '',
                'isOnline': false,
              },
            ),
          );
        _isLoadingCloudChats = false;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() => _isLoadingCloudChats = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load messages: $error')),
      );
    }
  }

  String _formatTime(String? value) {
    final date = value == null ? null : DateTime.tryParse(value)?.toLocal();
    if (date == null) return '';
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
      return '$hour:${date.minute.toString().padLeft(2, '0')} ${date.hour < 12 ? 'AM' : 'PM'}';
    }
    return '${date.month}/${date.day}';
  }

  @override
  void dispose() {
    widget.refreshSignal?.removeListener(_refresh);
    if (!_cloudMode) DemoChats.changes.removeListener(_loadDemoChats);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openChat({
    required String name,
    required String handle,
    required bool isOnline,
    String? peerId,
    String? conversationId,
    String avatarUrl = '',
  }) async {
    if (_cloudMode) {
      try {
        if (conversationId == null) {
          if (peerId == null) {
            throw StateError(
              'The selected member is unavailable for messaging.',
            );
          }
          conversationId = await ZitfaceBackend.openDirectConversation(peerId);
        }
      } on Exception catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open conversation: $error')),
        );
        return;
      }
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(
          peerName: name.trim(),
          peerHandle: handle,
          isOnline: isOnline,
          conversationId: conversationId,
          peerAvatarUrl: avatarUrl,
        ),
      ),
    );
    if (mounted && _cloudMode) await _loadCloudChats();
  }

  void _showNewMessageSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'New message',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ..._activePeers.map((peer) {
              final name = (peer['name'] as String).trim();
              return ListTile(
                leading: ProfileAvatar(
                  name: name,
                  avatarUrl: peer['avatar_url'] as String? ?? '',
                ),
                title: Text(
                  name,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  peer['school'] as String,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: Icon(
                  Icons.chat_bubble_outline,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openChat(
                    name: name,
                    handle: peer['school'] as String,
                    isOnline: peer['isOnline'] as bool,
                    peerId: peer['id'] as String?,
                    avatarUrl: peer['avatar_url'] as String? ?? '',
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filteredThreads = _chatThreads.where((chat) {
      final matchesUnread = !_showUnreadOnly || (chat['unread'] as int) > 0;
      final matchesQuery =
          query.isEmpty ||
          (chat['name'] as String).toLowerCase().contains(query) ||
          (chat['school'] as String).toLowerCase().contains(query) ||
          (chat['message'] as String).toLowerCase().contains(query);
      return matchesUnread && matchesQuery;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header & Action
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Messages',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    tooltip: 'New message',
                    onPressed: _showNewMessageSheet,
                    icon: Icon(
                      Icons.edit_outlined,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Search messages or contacts',
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          icon: Icon(
                            Icons.close,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            size: 18,
                          ),
                        ),
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.05),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.08),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.08),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  ChoiceChip(
                    label: Text('All ${_chatThreads.length}'),
                    selected: !_showUnreadOnly,
                    onSelected: (_) => setState(() => _showUnreadOnly = false),
                    selectedColor: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.18),
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.04),
                    labelStyle: TextStyle(
                      color: !_showUnreadOnly
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                    side: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.08),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!_cloudMode)
                    ChoiceChip(
                      label: Text(
                        'Unread ${_chatThreads.where((chat) => (chat['unread'] as int) > 0).length}',
                      ),
                      selected: _showUnreadOnly,
                      onSelected: (_) => setState(() => _showUnreadOnly = true),
                      selectedColor: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.18),
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.04),
                      labelStyle: TextStyle(
                        color: _showUnreadOnly
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                      side: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.08),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Active Peers Story Tray
            if (!_cloudMode && !_showUnreadOnly && query.isEmpty) ...[
              Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  'ACTIVE NOW',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _activePeers.length,
                  itemBuilder: (context, index) {
                    final peer = _activePeers[index];
                    final name = (peer['name'] as String).trim();
                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: GestureDetector(
                        onTap: () => _openChat(
                          name: name,
                          handle: peer['school'] as String,
                          isOnline: peer['isOnline'] as bool,
                          peerId: peer['id'] as String?,
                          avatarUrl: peer['avatar_url'] as String? ?? '',
                        ),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                ProfileAvatar(
                                  radius: 26,
                                  name: name,
                                  avatarUrl:
                                      peer['avatar_url'] as String? ?? '',
                                ),
                                if (peer['isOnline'])
                                  Positioned(
                                    right: 2,
                                    bottom: 2,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF10B981,
                                        ), // Active online indicator
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              name,
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 10),

            // Chat Threads
            Expanded(
              child: _isLoadingCloudChats
                  ? const Center(child: CircularProgressIndicator())
                  : filteredThreads.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.forum_outlined,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              size: 32,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              query.isNotEmpty
                                  ? 'No conversations found'
                                  : _showUnreadOnly
                                  ? 'No unread conversations'
                                  : 'No conversations yet',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _cloudMode
                                  ? 'Start a new message to begin a conversation.'
                                  : 'Try another search or switch to All.',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredThreads.length,
                      itemBuilder: (context, index) {
                        final chat = filteredThreads[index];
                        final bool hasUnread = chat['unread'] > 0;

                        return GestureDetector(
                          onTap: () {
                            setState(() => chat['unread'] = 0);
                            _openChat(
                              name: chat['name'] as String,
                              handle: chat['school'] as String,
                              isOnline: chat['isOnline'] as bool,
                              peerId: chat['peer_id'] as String?,
                              conversationId: chat['id'] as String?,
                              avatarUrl: chat['avatar_url'] as String? ?? '',
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: hasUnread
                                  ? Theme.of(context).colorScheme.onSurface
                                        .withValues(alpha: 0.08)
                                  : Theme.of(context).colorScheme.onSurface
                                        .withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Stack(
                                  children: [
                                    chat['avatarIcon'] == Icons.groups_outlined
                                        ? Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(alpha: 0.06),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            child: Center(
                                              child: Icon(
                                                chat['avatarIcon'] as IconData,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                                size: 23,
                                              ),
                                            ),
                                          )
                                        : ProfileAvatar(
                                            radius: 24,
                                            name: chat['name'] as String,
                                            avatarUrl:
                                                chat['avatar_url'] as String? ??
                                                '',
                                          ),
                                    if (chat['isOnline'])
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          width: 11,
                                          height: 11,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF10B981),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              chat['name'] as String,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                                fontWeight: hasUnread
                                                    ? FontWeight.bold
                                                    : FontWeight.w500,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            chat['time'] as String,
                                            style: TextStyle(
                                              color: hasUnread
                                                  ? Theme.of(
                                                      context,
                                                    ).colorScheme.onSurface
                                                  : Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        chat['school'] as String,
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                          fontSize: 10,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              chat['message'] as String,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: hasUnread
                                                    ? Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant
                                                    : Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                fontSize: 12,
                                                fontWeight: hasUnread
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                          if (hasUnread)
                                            Container(
                                              margin: const EdgeInsets.only(
                                                left: 8,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 7,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.25),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                '${chat['unread']}',
                                                style: TextStyle(
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.onSurface,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
