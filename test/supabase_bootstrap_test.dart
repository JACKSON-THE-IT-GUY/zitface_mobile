import 'package:flutter_test/flutter_test.dart';
import 'package:zitface_mobile/services/supabase_bootstrap.dart';

void main() {
  group('SupabaseEnvironment', () {
    test('allows both values to be omitted for local demo mode', () {
      const environment = SupabaseEnvironment(
        projectUrl: '',
        publishableKey: '',
      );

      expect(environment.isConfigured, isFalse);
      expect(environment.validate, returnsNormally);
    });

    test('requires URL and anon key to be configured together', () {
      const environment = SupabaseEnvironment(
        projectUrl: 'https://example.supabase.co',
        publishableKey: '',
      );

      expect(environment.validate, throwsStateError);
    });

    test('requires an absolute HTTP or HTTPS project URL', () {
      const environment = SupabaseEnvironment(
        projectUrl: 'example.supabase.co',
        publishableKey: 'public-publishable-key',
      );

      expect(environment.validate, throwsFormatException);
    });

    test('accepts a configured project URL and anon key', () {
      const environment = SupabaseEnvironment(
        projectUrl: 'https://example.supabase.co',
        publishableKey: 'public-publishable-key',
      );

      expect(environment.isConfigured, isTrue);
      expect(environment.validate, returnsNormally);
    });

    test('requires HTTPS when validating production configuration', () {
      const environment = SupabaseEnvironment(
        projectUrl: 'http://example.supabase.co',
        publishableKey: 'public-publishable-key',
      );

      expect(
        () => environment.validate(requireHttps: true),
        throwsFormatException,
      );
    });
  });
}
