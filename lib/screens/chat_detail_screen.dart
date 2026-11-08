import 'dart:async';

import 'package:zitface_mobile/theme/app_theme.dart';
import 'package:flutter/material.dart';
import '../services/zitface_backend.dart';

class ChatDetailScreen extends StatefulWidget {
  final String peerName;
  final String peerHandle;
  final bool isOnline;
  final String? conversationId;

  const ChatDetailScreen({
    super.key,
    required this.peerName,
    required this.peerHandle,
    this.isOnline = true,
    this.conversationId,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = ZitfaceBackend.isConfigured
      ? []
      : [
    {
      'sender': 'peer',
      'text': 'Hey! Is the CS150 study guide still available on your profile?',
      'time': '10:42 AM',
    },
    {
      'sender': 'me',
      'text': 'Yeah man, uploaded it yesterday! Check under my latest posts.',
      'time': '10:44 AM',
    },
    {
      'sender': 'peer',
      'text':
          'Awesome, got it. Are you attending the lab session at Riverside later?',
      'time': '10:45 AM',
    },
        ];
  StreamSubscription<List<Map<String, dynamic>>>? _messagesSubscription;

  @override
  void initState() {
    super.initState();
    if (ZitfaceBackend.isConfigured && widget.conversationId != null) {
      _messagesSubscription = ZitfaceBackend.watchMessages(
        widget.conversationId!,
      ).listen(
        (rows) {
          if (!mounted) return;
          setState(() {
            _messages
              ..clear()
              ..addAll(rows.map(_messageFromRemote));
          });
          _scrollToBottom();
        },
        onError: (Object error) {
          if (mounted) _showMessageError('load', error);
        },
      );
    }
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    if (ZitfaceBackend.isConfigured) {
      final conversationId = widget.conversationId;
      if (conversationId == null) {
        _showMessageError(
          'send',
          StateError('The conversation is not available.'),
        );
        return;
      }
      try {
        await ZitfaceBackend.sendMessage(
          conversationId: conversationId,
          body: text,
        );
        if (mounted) _messageController.clear();
      } on Exception catch (error) {
        if (mounted) _showMessageError('send', error);
      }
      return;
    }

    setState(() {
      _messages.add({'sender': 'me', 'text': text, 'time': 'Just now'});
    });

    _messageController.clear();
    _scrollToBottom();
  }

  Map<String, dynamic> _messageFromRemote(Map<String, dynamic> row) {
    final createdAt = DateTime.parse(row['created_at'] as String).toLocal();
    final hour = createdAt.hour % 12 == 0 ? 12 : createdAt.hour % 12;
    final time =
        '$hour:${createdAt.minute.toString().padLeft(2, '0')} ${createdAt.hour < 12 ? 'AM' : 'PM'}';
    return {
      'sender': row['sender_id'] == ZitfaceBackend.client.auth.currentUser?.id
          ? 'me'
          : 'peer',
      'text': row['body'] as String,
      'time': time,
    };
  }

  void _showMessageError(String action, Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not $action messages: $error')),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Theme.of(context).colorScheme.onSurface,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
                  child: Text(
                    widget.peerName.isNotEmpty ? widget.peerName[0] : 'U',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (widget.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.surface,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.peerName,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.isOnline ? 'Online' : widget.peerHandle,
                  style: TextStyle(
                    color: widget.isOnline
                        ? const Color(0xFF10B981)
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isMe = msg['sender'] == 'me';

                  return Align(
                    alignment: isMe
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isMe
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: Radius.circular(isMe ? 18 : 4),
                          bottomRight: Radius.circular(isMe ? 4 : 18),
                        ),
                        border: isMe
                            ? null
                            : Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.08),
                              ),
                      ),
                      child: Column(
                        crossAxisAlignment: isMe
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          Text(
                            msg['text'],
                            style: TextStyle(
                              color: isMe
                                  ? AppColors.onAccent
                                  : Theme.of(context).colorScheme.onSurface,
                              fontSize: 14,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            msg['time'],
                            style: TextStyle(
                              color: isMe
                                  ? Colors.black45
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Message Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.08),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.08),
                        ),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Send message',
                    onPressed: _sendMessage,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.onAccent,
                    ),
                    icon: const Icon(Icons.send_rounded, size: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
