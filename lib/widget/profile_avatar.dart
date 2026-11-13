import 'dart:convert';

import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    this.name = '',
    this.avatarUrl = '',
    this.photoData = '',
    this.radius = 20,
  });

  final String name;
  final String avatarUrl;
  final String photoData;
  final double radius;

  @override
  Widget build(BuildContext context) {
    ImageProvider? image;
    if (photoData.isNotEmpty) {
      try {
        image = MemoryImage(base64Decode(photoData));
      } on FormatException catch (error) {
        debugPrint('Invalid saved profile photo: $error');
      }
    } else if (avatarUrl.isNotEmpty) {
      image = NetworkImage(avatarUrl);
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      foregroundImage: image,
      onForegroundImageError: image == null
          ? null
          : (error, stackTrace) =>
                debugPrint('Could not load profile photo: $error'),
      child: name.trim().isEmpty
          ? const Icon(Icons.person_outline)
          : Text(name.trim()[0].toUpperCase()),
    );
  }
}
