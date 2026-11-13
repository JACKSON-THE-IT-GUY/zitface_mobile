import 'package:flutter/material.dart';

class LegalInformationScreen extends StatelessWidget {
  const LegalInformationScreen({super.key});

  Widget _section(BuildContext context, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          Text(
            body,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy and Terms')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.tertiaryContainer,
            child: Text(
              'MVP draft: the app operator must review and publish final policies, contact details, jurisdiction, and retention periods before public launch.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Privacy summary',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _section(
            context,
            'Information used',
            'ZITFACE uses your account email and profile details. If you apply for campus membership, your student or staff identifier is stored separately from your public profile for the membership workflow. The app also stores content and interactions you submit, including posts, messages, stories, and marketplace listings.',
          ),
          _section(
            context,
            'Visibility and hosting',
            'Profile privacy and each feature’s audience setting determine what other signed-in members can see. Supabase hosts account and app data. Your email and membership identifier are not intended to appear on your public profile.',
          ),
          _section(
            context,
            'Retention and deletion',
            'Stories stop appearing after 24 hours. Account deletion is designed to remove the account, related records, and uploaded files. The operator must publish a complete retention schedule before launch.',
          ),
          _section(
            context,
            'Your choices',
            'You can make your profile private, choose audiences for supported content, sign out other sessions, and request account deletion from Account & Privacy settings.',
          ),
          const Divider(height: 32),
          Text('Terms summary', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _section(
            context,
            'Respectful use',
            'Use the service lawfully and respectfully. Do not impersonate others, expose another person’s private information, harass members, or upload content you do not have permission to use.',
          ),
          _section(
            context,
            'Campus and marketplace features',
            'A student identifier format check does not verify enrollment with CBU. Marketplace payments are not handled by ZITFACE; users arrange transactions independently.',
          ),
          _section(
            context,
            'Before public launch',
            'These summaries are not a substitute for complete legal terms or a privacy notice. The operator must confirm the responsible legal entity, contact address, applicable law, age requirements, retention schedule, and user-rights process.',
          ),
        ],
      ),
    );
  }
}
