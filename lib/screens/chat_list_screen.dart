import 'package:zitface_mobile/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final List<Map<String, dynamic>> _chats = [
    {
      'name': 'Phanciah',
      'handle': '@ciah',
      'lastMessage': 'Are you attending the lab session at Riverside later?',
      'time': '10:45 AM',
      'unread': 2,
      'isOnline': true,
    },
    {
      'name': 'CBU CS Group',
      'handle': '#cs150',
      'lastMessage': 'David: Can someone reshare the assignment PDF?',
      'time': '09:12 AM',
      'unread': 0,
      'isOnline': false,
    },
    {
      'name': 'Kabwe B.',
      'handle': '@kabwe',
      'lastMessage': 'Thanks for the HP laptop deal on the market!',
      'time': 'Yesterday',
      'unread': 0,
      'isOnline': true,
    },
    {
      'name': 'SICT Hackathon Team',
      'handle': '#hackathon',
      'lastMessage': 'Repository updated, push your local commits.',
      'time': 'Jul 31',
      'unread': 5,
      'isOnline': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
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
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.textPrimary.withValues(alpha: 0.06),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.textPrimary.withValues(alpha: 0.08),
                      ),
                    ),
                    child: const Icon(
                      Icons.edit_note_rounded,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.textPrimary.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.textPrimary.withValues(alpha: 0.08),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search conversations...',
                          hintStyle: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Active Chats List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _chats.length,
                itemBuilder: (context, index) {
                  final chat = _chats[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatDetailScreen(
                            peerName: chat['name'],
                            peerHandle: chat['handle'],
                            isOnline: chat['isOnline'],
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.textPrimary.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.secondarySurface
                                    .withValues(alpha: 0.08),
                                child: Text(
                                  chat['name'][0],
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (chat['isOnline'])
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 12,
                                    height: 12,
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      chat['name'],
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      chat['time'],
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        chat['lastMessage'],
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: chat['unread'] > 0
                                              ? AppColors.textPrimary
                                              : AppColors.textSecondary,
                                          fontSize: 13,
                                          fontWeight: chat['unread'] > 0
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    if (chat['unread'] > 0) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.textPrimary,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          '${chat['unread']}',
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
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
