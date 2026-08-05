import 'package:flutter/material.dart';
import 'chat_detail_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
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
      'avatar': '👩‍🎓',
    },
    {
      'name': 'ICTAZ Tech Group',
      'school': 'SICT Official',
      'message': 'Kondwani: The hackathon submission deadline was extended!',
      'time': '10:15 AM',
      'unread': 5,
      'isOnline': false,
      'avatar': '💻',
    },
    {
      'name': 'Victor Mundia',
      'school': 'Computer Science',
      'message': 'Pushed the updated backend routes to GitHub.',
      'time': 'Yesterday',
      'unread': 0,
      'isOnline': true,
      'avatar': '👨‍💻',
    },
    {
      'name': 'Engineering Study Circle',
      'school': 'SOE Community',
      'message': 'Who has the past papers for Fluid Mechanics?',
      'time': 'Yesterday',
      'unread': 0,
      'isOnline': false,
      'avatar': '⚙️',
    },
    {
      'name': ' Jackson Nsonga.',
      'school': 'Built Environment',
      'message': 'Thanks for the architecture project notes!',
      'time': 'Monday',
      'unread': 0,
      'isOnline': false,
      'avatar': '🏗️',
    },
  ];

  @override
  Widget build(BuildContext context) {
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
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: Colors.white38, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Search messages or contacts...',
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Active Peers Story Tray
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _activePeers.length,
                itemBuilder: (context, index) {
                  final peer = _activePeers[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.08),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  peer['name'][0],
                                  style: const TextStyle(
                                    color: Colors.white,
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
                                      color: const Color(0xFF090A0F),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          peer['name'],
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),

            // Chat Threads
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _chatThreads.length,
                itemBuilder: (context, index) {
                  final chat = _chatThreads[index];
                  final bool hasUnread = chat['unread'] > 0;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatDetailScreen(
                            peerName: chat['name'],
                            peerHandle: chat['school'],
                            isOnline: chat['isOnline'],
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: hasUnread
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: hasUnread
                              ? Colors.white.withValues(alpha: 0.18)
                              : Colors.white.withValues(alpha: 0.06),
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
                                  color: Colors.white.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: Text(
                                    chat['avatar'],
                                    style: const TextStyle(fontSize: 22),
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
                                        color: const Color(0xFF090A0F),
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
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: hasUnread
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      chat['time'],
                                      style: TextStyle(
                                        color: hasUnread
                                            ? Colors.white
                                            : Colors.white38,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  chat['school'],
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        chat['message'],
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: hasUnread
                                              ? Colors.white70
                                              : Colors.white38,
                                          fontSize: 12,
                                          fontWeight: hasUnread
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    if (hasUnread)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.25),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '${chat['unread']}',
                                          style: const TextStyle(
                                            color: Colors.white,
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
