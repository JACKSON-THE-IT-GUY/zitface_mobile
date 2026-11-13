import 'package:zitface_mobile/theme/app_theme.dart';
import 'package:zitface_mobile/services/zitface_backend.dart';
import 'package:zitface_mobile/widget/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/open_direct_chat.dart';
import '../widget/profile_avatar.dart';

class _StudentProfile {
  final String id;
  final String name;
  final String school;
  final String program;
  final int year;
  final String bio;
  final String avatarUrl;

  const _StudentProfile({
    required this.id,
    required this.name,
    required this.school,
    required this.program,
    required this.year,
    required this.bio,
    this.avatarUrl = '',
  });
}

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key, this.refreshSignal});

  final Listenable? refreshSignal;

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  static const String _requestsKey = 'friend_requests_sent';
  static const List<_StudentProfile> _demoStudents = [
    _StudentProfile(
      id: 'phanciah',
      name: 'Phanciah M.',
      school: 'SICT',
      program: 'Computer Science',
      year: 2,
      bio: 'Interested in software engineering and campus study groups.',
    ),
    _StudentProfile(
      id: 'victor',
      name: 'Victor Mundia',
      school: 'SICT',
      program: 'Computer Science',
      year: 3,
      bio: 'Building backend projects and sharing programming resources.',
    ),
    _StudentProfile(
      id: 'joe',
      name: 'Joe K.',
      school: 'School of Engineering',
      program: 'Electrical Engineering',
      year: 2,
      bio: 'Looking for project partners and fellow engineering students.',
    ),
    _StudentProfile(
      id: 'mateo',
      name: 'Mateo B.',
      school: 'SMNS',
      program: 'Mathematics',
      year: 1,
      bio: 'Enjoys problem-solving and collaborative revision.',
    ),
    _StudentProfile(
      id: 'peter',
      name: 'Peter C.',
      school: 'School of Built Environment',
      program: 'Architecture',
      year: 2,
      bio: 'Sharing design ideas, studio tips, and project feedback.',
    ),
    _StudentProfile(
      id: 'kabwe',
      name: 'Kabwe B.',
      school: 'School of Business',
      program: 'Business Administration',
      year: 3,
      bio: 'Connecting with students interested in entrepreneurship.',
    ),
  ];

  final TextEditingController _searchController = TextEditingController();
  final bool _cloudMode = ZitfaceBackend.isConfigured;
  List<_StudentProfile> _students = ZitfaceBackend.isConfigured
      ? []
      : [..._demoStudents];
  final Set<String> _sentRequests = {};
  bool _isLoadingRequests = true;

  @override
  void initState() {
    super.initState();
    widget.refreshSignal?.addListener(_refresh);
    _loadRequests();
  }

  void _refresh() {
    if (_cloudMode) _loadRequests();
  }

  Future<void> _loadRequests() async {
    try {
      if (_cloudMode) {
        final profiles = await ZitfaceBackend.loadDiscoverableProfiles();
        final requestIds = await ZitfaceBackend.loadSentFriendRequests();
        if (!mounted) return;
        setState(() {
          _students = profiles
              .map(
                (profile) => _StudentProfile(
                  id: profile['id'] as String,
                  name: profile['display_name'] as String,
                  school: profile['school'] as String? ?? '',
                  program: '',
                  year: 0,
                  bio: profile['bio'] as String? ?? '',
                  avatarUrl: profile['avatar_display_url'] as String? ?? '',
                ),
              )
              .toList();
          _sentRequests
            ..clear()
            ..addAll(requestIds);
          _isLoadingRequests = false;
        });
        return;
      }
      final preferences = await SharedPreferences.getInstance();
      final requestIds = preferences.getStringList(_requestsKey) ?? [];
      if (!mounted) return;
      setState(() {
        _sentRequests
          ..clear()
          ..addAll(requestIds);
        _isLoadingRequests = false;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() => _isLoadingRequests = false);
      _showStorageError(error);
    }
  }

  Future<void> _sendRequest(_StudentProfile student) async {
    if (_sentRequests.contains(student.id)) return;
    if (_cloudMode) {
      try {
        await ZitfaceBackend.sendFriendRequest(student.id);
        if (!mounted) return;
        setState(() => _sentRequests.add(student.id));
      } on Exception catch (error) {
        if (mounted) _showStorageError(error);
      }
      return;
    }
    final updatedRequests = {..._sentRequests, student.id};

    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = await preferences.setStringList(
        _requestsKey,
        updatedRequests.toList(),
      );
      if (!saved) {
        _showStorageError(
          Exception('Device storage did not confirm the friend request.'),
        );
        return;
      }
    } on Exception catch (error) {
      if (mounted) _showStorageError(error);
      return;
    }

    if (!mounted) return;
    setState(() {
      _sentRequests
        ..clear()
        ..addAll(updatedRequests);
    });
  }

  void _showStorageError(Exception error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not update friend requests: $error')),
    );
  }

  @override
  void dispose() {
    widget.refreshSignal?.removeListener(_refresh);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filteredStudents = _students.where((student) {
      return student.name.toLowerCase().contains(query) ||
          student.school.toLowerCase().contains(query) ||
          student.program.toLowerCase().contains(query) ||
          'year ${student.year}'.contains(query) ||
          student.bio.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Find students',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Discover fellow students by name, school, program, or year.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search students or programs',
                      hintStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      suffixIcon: query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                              icon: Icon(
                                Icons.close,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                      filled: true,
                      fillColor: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.08),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.08),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 15,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _cloudMode
                              ? 'Profiles visible to your account. Requests are sent to the recipient.'
                              : 'Sample student profiles. Friend requests are saved on this device.',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.45),
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoadingRequests
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        strokeWidth: 2,
                      ),
                    )
                  : filteredStudents.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person_search_outlined,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              size: 34,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'No students found',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Try a different name, school, or program.',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: filteredStudents.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final student = filteredStudents[index];
                        final requestSent = _sentRequests.contains(student.id);
                        return _StudentCard(
                          student: student,
                          requestSent: requestSent,
                          onAddFriend: () => _sendRequest(student),
                          onMessage: () => openDirectChat(
                            context,
                            name: student.name,
                            handle: student.school,
                            peerId: student.id,
                            avatarUrl: student.avatarUrl,
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

class _StudentCard extends StatelessWidget {
  final _StudentProfile student;
  final bool requestSent;
  final VoidCallback onAddFriend;
  final VoidCallback onMessage;

  const _StudentCard({
    required this.student,
    required this.requestSent,
    required this.onAddFriend,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      borderRadius: 18,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileAvatar(
            radius: 25,
            name: student.name,
            avatarUrl: student.avatarUrl,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  student.program.isEmpty
                      ? student.school
                      : '${student.program} · Year ${student.year}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                if (student.program.isNotEmpty)
                  Text(
                    student.school,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  student.bio,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: requestSent ? null : onAddFriend,
                  icon: Icon(
                    requestSent ? Icons.check : Icons.person_add_alt_1,
                    size: 16,
                  ),
                  label: Text(requestSent ? 'Request sent' : 'Add friend'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.onAccent,
                    disabledBackgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    disabledForegroundColor: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                TextButton.icon(
                  onPressed: onMessage,
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: const Text('Message'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
