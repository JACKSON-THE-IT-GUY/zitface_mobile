import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseEnvironment {
  const SupabaseEnvironment({
    required this.projectUrl,
    required this.publishableKey,
  });

  static const fromCompileTime = SupabaseEnvironment(
    projectUrl: String.fromEnvironment('SUPABASE_URL'),
    publishableKey: String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
  );

  final String projectUrl;
  final String publishableKey;

  bool get isConfigured =>
      projectUrl.trim().isNotEmpty && publishableKey.trim().isNotEmpty;

  void validate({bool requireHttps = false}) {
    final normalizedUrl = projectUrl.trim();
    final normalizedKey = publishableKey.trim();

    if (normalizedUrl.isEmpty && normalizedKey.isEmpty) return;
    if (normalizedUrl.isEmpty || normalizedKey.isEmpty) {
      throw StateError(
        'Configure both SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY, or leave both unset.',
      );
    }

    final uri = Uri.tryParse(normalizedUrl);
    if (uri == null ||
        !uri.hasAuthority ||
        (requireHttps ? uri.scheme != 'https' :
            uri.scheme != 'https' && uri.scheme != 'http')) {
      throw const FormatException(
        'SUPABASE_URL must be an absolute HTTPS URL in production.',
      );
    }
  }
}

Future<bool> initializeSupabase({
  SupabaseEnvironment environment = SupabaseEnvironment.fromCompileTime,
  bool requireHttps = false,
}) async {
  environment.validate(requireHttps: requireHttps);
  if (!environment.isConfigured) return false;

  await Supabase.initialize(
    url: environment.projectUrl.trim(),
    publishableKey: environment.publishableKey.trim(),
  );
  return true;
}
