import 'package:flutter/material.dart';

import '../screens/chat_detail_screen.dart';
import 'zitface_backend.dart';

Future<void> openDirectChat(
  BuildContext context, {
  required String name,
  required String handle,
  required String? peerId,
  String avatarUrl = '',
}) async {
  String? conversationId;
  if (ZitfaceBackend.isConfigured) {
    if (peerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This member is unavailable for messaging.'),
        ),
      );
      return;
    }
    try {
      conversationId = await ZitfaceBackend.openDirectConversation(peerId);
    } on Exception catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open conversation: $error')),
        );
      }
      return;
    }
  }
  if (!context.mounted) return;
  await Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => ChatDetailScreen(
        peerName: name,
        peerHandle: handle,
        isOnline: false,
        conversationId: conversationId,
        peerAvatarUrl: avatarUrl,
      ),
    ),
  );
}
