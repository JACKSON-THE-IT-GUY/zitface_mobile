import 'package:flutter/material.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupName;
  final String category;
  final String memberCount;
  final bool isJoined;

  const GroupDetailScreen({
    super.key,
    required this.groupName,
    required this.category,
    required this.memberCount,
    this.isJoined = false,
  });

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  late bool _joined;

  final List<Map<String, String>> _groupPosts = [
    {
      'author': 'Phanciah C.',
      'time': '1 hour ago',
      'content': 'Reminder: The CS150 lab quiz is moved to Thursday at 14:00 hrs in Riverside Computer Lab 2.',
      'likes': '14',
    },
    {
      'author': 'David M.',
      'time': '3 hours ago',
      'content': 'Does anyone have the past papers for MA110 linear algebra? Please drop a link or send a DM.',
      'likes': '8',
    },
  ];

  @override
  void initState() {
    super.initState();
    _joined = widget.isJoined;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1016),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.groupName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white70, size: 20),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Group Hero Header Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      child: Text(
                        widget.groupName.isNotEmpty ? widget.groupName[0] : 'G',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.groupName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.category} • ${widget.memberCount} Members',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _joined = !_joined;
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _joined
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: _joined
                              ? Border.all(color: Colors.white.withValues(alpha: 0.1))
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            _joined ? 'Joined' : 'Join Group',
                            style: TextStyle(
                              color: _joined
                                  ? Colors.white
                                  : const Color(0xFF090A0F),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Group Feed Header
              const Text(
                'Group Discussions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Posts List
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _groupPosts.length,
                itemBuilder: (context, index) {
                  final post = _groupPosts[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              post['author']!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              post['time']!,
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          post['content']!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.thumb_up_alt_outlined,
                              color: Colors.white.withValues(alpha: 0.5),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              post['likes']!,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}