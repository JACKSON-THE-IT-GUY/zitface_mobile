import 'package:flutter/foundation.dart';

class DemoChat {
  DemoChat({required this.name, required this.school});

  final String name;
  final String school;
  final List<Map<String, dynamic>> messages = [];
}

class DemoChats {
  DemoChats._();

  static final ValueNotifier<int> changes = ValueNotifier(0);
  static final Map<String, DemoChat> _chats = {};

  static Iterable<DemoChat> get chats => _chats.values;

  static List<Map<String, dynamic>> messagesFor(String name) =>
      List.of(_chats[name]?.messages ?? []);

  static void send(String name, String school, String text) {
    final chat = _chats.putIfAbsent(
      name,
      () => DemoChat(name: name, school: school),
    );
    chat.messages.add({'sender': 'me', 'text': text, 'time': 'Just now'});
    changes.value++;
  }
}
