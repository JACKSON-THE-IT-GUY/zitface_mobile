import 'package:zitface_mobile/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'chat_detail_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showUnreadOnly = false;

  final List<Map<String, dynamic>> _activePeers = [
    {'name': 'SAM ', 'school': 'SICT', 'isOnline': true},
    {'name': 'JOE', 'school': 'SOE', 'isOnline': true},
    {'name': 'PHANSCIAH', 'school': 'SICT', 'isOnline': true},
    {'name': 'MATEO', 'school': 'SMNS', 'isOnline': true},
    {'name': 'PETER', 'school': 'SBE', 'isOnline': false},
  ];

  final List<Map<String, dynamic>> _chatThreads = [
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
      'message': 'Kondwani: The hackathon submission deadline was extended!',
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openChat({
    required String name,
    required String handle,
    required bool isOnline,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(
          peerName: name.trim(),
          peerHandle: handle,
          isOnline: isOnline,
        ),
      ),
    );
  }

  void _showNewMessageSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.pageBackground,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'New message',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ..._activePeers.map((peer) {
              final name = (peer['name'] as String).trim();
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.secondarySurface.withValues(
                    alpha: 0.08,
                  ),
                  child: Text(
                    name.isEmpty ? '?' : name[0].toUpperCase(),
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                ),
                title: Text(
                  name,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                subtitle: Text(
                  peer['school'] as String,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                trailing: const Icon(
                  Icons.chat_bubble_outline,
                  color: AppColors.textSecondary,
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openChat(
                    name: name,
                    handle: peer['school'] as String,
                    isOnline: peer['isOnline'] as bool,
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
                  const Text(
                    'Messages',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    tooltip: 'New message',
                    onPressed: _showNewMessageSheet,
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: AppColors.textPrimary,
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
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Search messages or contacts',
                  hintStyle: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.textSecondary,
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
                          icon: const Icon(
                            Icons.close,
                            color: AppColors.textSecondary,
                            size: 18,
                          ),
                        ),
                  filled: true,
                  fillColor: AppColors.textPrimary.withValues(alpha: 0.05),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppColors.textPrimary.withValues(alpha: 0.08),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppColors.textPrimary.withValues(alpha: 0.08),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppColors.textPrimary.withValues(alpha: 0.3),
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
                    selectedColor: AppColors.textPrimary.withValues(
                      alpha: 0.18,
                    ),
                    backgroundColor: AppColors.secondarySurface.withValues(
                      alpha: 0.04,
                    ),
                    labelStyle: TextStyle(
                      color: !_showUnreadOnly
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    side: BorderSide(
                      color: AppColors.textPrimary.withValues(alpha: 0.08),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(
                      'Unread ${_chatThreads.where((chat) => (chat['unread'] as int) > 0).length}',
                    ),
                    selected: _showUnreadOnly,
                    onSelected: (_) => setState(() => _showUnreadOnly = true),
                    selectedColor: AppColors.textPrimary.withValues(
                      alpha: 0.18,
                    ),
                    backgroundColor: AppColors.secondarySurface.withValues(
                      alpha: 0.04,
                    ),
                    labelStyle: TextStyle(
                      color: _showUnreadOnly
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    side: BorderSide(
                      color: AppColors.textPrimary.withValues(alpha: 0.08),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Active Peers Story Tray
            if (!_showUnreadOnly && query.isEmpty) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  'ACTIVE NOW',
                  style: TextStyle(
                    color: AppColors.textSecondary,
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
                        ),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.textPrimary.withValues(
                                      alpha: 0.08,
                                    ),
                                    border: Border.all(
                                      color: AppColors.textPrimary.withValues(
                                        alpha: 0.25,
                                      ),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      name.isEmpty
                                          ? '?'
                                          : name[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
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
                                          color: AppColors.textPrimary,
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
                              style: const TextStyle(
                                color: AppColors.textSecondary,
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
              child: filteredThreads.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.forum_outlined,
                              color: AppColors.textSecondary,
                              size: 32,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              query.isNotEmpty
                                  ? 'No conversations found'
                                  : 'No unread conversations',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Try another search or switch to All.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
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
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: hasUnread
                                  ? AppColors.textPrimary.withValues(
                                      alpha: 0.08,
                                    )
                                  : AppColors.textPrimary.withValues(
                                      alpha: 0.03,
                                    ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: hasUnread
                                    ? AppColors.textPrimary.withValues(
                                        alpha: 0.18,
                                      )
                                    : AppColors.textPrimary.withValues(
                                        alpha: 0.06,
                                      ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: AppColors.textPrimary.withValues(
                                          alpha: 0.06,
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          chat['avatarIcon'] as IconData,
                                          color: AppColors.textPrimary,
                                          size: 23,
                                        ),
                                      ),
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
                                              color: AppColors.textPrimary,
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
                                                color: AppColors.textPrimary,
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
                                                  ? AppColors.textPrimary
                                                  : AppColors.textSecondary,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        chat['school'] as String,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
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
                                                    ? AppColors.textSecondary
                                                    : AppColors.textSecondary,
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
                                                color: AppColors.textPrimary
                                                    .withValues(alpha: 0.25),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                '${chat['unread']}',
                                                style: const TextStyle(
                                                  color: AppColors.textPrimary,
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
