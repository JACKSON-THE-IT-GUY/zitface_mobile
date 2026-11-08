import 'package:zitface_mobile/theme/app_theme.dart';
import 'package:zitface_mobile/widget/glass_card.dart';
import 'package:flutter/material.dart';
import '../services/zitface_backend.dart';

class GroupHubScreen extends StatefulWidget {
  final String groupName;
  final String membersCount;
  final String category;
  final String? school;
  final String? program;
  final int? academicYear;
  final String? classGroupName;
  final String? classRep;
  final String? groupId;
  final bool initiallyJoined;

  const GroupHubScreen({
    super.key,
    required this.groupName,
    required this.membersCount,
    required this.category,
    this.school,
    this.program,
    this.academicYear,
    this.classGroupName,
    this.classRep,
    this.groupId,
    this.initiallyJoined = true,
  });

  @override
  State<GroupHubScreen> createState() => _GroupHubScreenState();
}

class _GroupHubScreenState extends State<GroupHubScreen> {
  late bool _isJoined;
  bool _isLoadingMembership = false;
  bool _isChangingMembership = false;

  @override
  void initState() {
    super.initState();
    _isJoined = widget.initiallyJoined;
    if (ZitfaceBackend.isConfigured && widget.groupId != null) {
      _loadMembership();
    }
  }

  Future<void> _loadMembership() async {
    setState(() => _isLoadingMembership = true);
    try {
      final isJoined = await ZitfaceBackend.isGroupMember(widget.groupId!);
      if (mounted) setState(() => _isJoined = isJoined);
    } on Exception catch (error) {
      if (mounted) _showMembershipError('load', error);
    } finally {
      if (mounted) setState(() => _isLoadingMembership = false);
    }
  }

  Future<void> _toggleMembership() async {
    if (_isChangingMembership || _isLoadingMembership) return;
    final shouldJoin = !_isJoined;
    setState(() => _isChangingMembership = true);
    try {
      if (ZitfaceBackend.isConfigured && widget.groupId != null) {
        await ZitfaceBackend.setGroupMembership(
          groupId: widget.groupId!,
          joined: shouldJoin,
        );
      }
      if (mounted) setState(() => _isJoined = shouldJoin);
    } on Exception catch (error) {
      if (mounted) _showMembershipError('update', error);
    } finally {
      if (mounted) setState(() => _isChangingMembership = false);
    }
  }

  void _showMembershipError(String action, Exception error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not $action group membership: $error')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.06),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 16,
                      ),
                    ),
                  ),
                  Text(
                    widget.category,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.more_horiz,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Group Banner Header Card
                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      borderRadius: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  Icons.groups_outlined,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  size: 28,
                                ),
                              ),
                              ElevatedButton(
                                onPressed:
                                    _isChangingMembership ||
                                        _isLoadingMembership
                                    ? null
                                    : _toggleMembership,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isJoined
                                      ? Theme.of(context).colorScheme.onSurface
                                            .withValues(alpha: 0.1)
                                      : Theme.of(context).colorScheme.onSurface,
                                  foregroundColor: _isJoined
                                      ? Theme.of(context).colorScheme.onSurface
                                      : AppColors.onAccent,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Text(
                                  _isChangingMembership
                                      ? 'Updating...'
                                      : _isLoadingMembership
                                      ? 'Loading...'
                                      : _isJoined
                                      ? 'Joined'
                                      : 'Join Group',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.groupName,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.membersCount} Members • Active Hub',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (widget.school != null &&
                        widget.program != null &&
                        widget.academicYear != null) ...[
                      const SizedBox(height: 14),
                      GlassCard(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        borderRadius: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'COHORT CONNECTION',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildCohortDetail('School', widget.school!),
                            _buildCohortDetail('Program', widget.program!),
                            _buildCohortDetail(
                              'Academic year',
                              'Year ${widget.academicYear}',
                            ),
                            if (widget.classGroupName != null)
                              _buildCohortDetail(
                                'Class group',
                                widget.classGroupName!,
                              ),
                            if (widget.classRep != null)
                              _buildCohortDetail(
                                'Class representative',
                                widget.classRep!,
                              ),
                            const SizedBox(height: 4),
                            Text(
                              'This group is linked to the same school, program, year, and class cohort.',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontSize: 11,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    if (!ZitfaceBackend.isConfigured) ...[
                      // Pinned Announcement
                      GlassCard(
                      padding: const EdgeInsets.all(14),
                      borderRadius: 16,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.push_pin_outlined,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pinned Announcement',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'End of semester project submission deadlines and lab hours updated for SICT students.',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                      const SizedBox(height: 24),
                    ],

                    // Feed Section Title
                    Text(
                      'Group Discussion Feed',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Sample Feed Items
                    if (ZitfaceBackend.isConfigured)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'Group discussions are not available yet.',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    else ...[
                      _buildGroupPostCard(
                        author: 'Chileshe M.',
                        time: '2h ago',
                        text:
                            'Anyone free to revise CS150 data structures before tomorrow afternoon?',
                      ),
                      _buildGroupPostCard(
                        author: 'Kabwe T.',
                        time: '5h ago',
                        text:
                            'Lab 3 submission portal is now open on the portal. Make sure to attach your source files.',
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupPostCard({
    required String author,
    required String time,
    required String text,
  }) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
                child: Icon(
                  Icons.person,
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                author,
              ),
              const Spacer(),
              Text(
                time,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCohortDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
