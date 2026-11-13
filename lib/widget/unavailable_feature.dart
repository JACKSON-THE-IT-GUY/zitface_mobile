import 'package:flutter/material.dart';

void showUnavailableFeature(BuildContext context, String feature) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text('$feature is not available yet.')));
}
