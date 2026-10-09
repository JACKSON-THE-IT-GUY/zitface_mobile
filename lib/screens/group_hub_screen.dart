import 'package:zitface_mobile/theme/app_theme.dart';
import 'package:flutter/material.dart';

class GroupHubScreen extends StatefulWidget {
  final String groupName;
  final String membersCount;
  final String category;
  final String? school;
  final String? program;
  final int? academicYear;
  final String? classGroupName;
  final String? classRep;
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
    this.initiallyJoined = true,
  });

  @override
  State<GroupHubScreen> createState() => _GroupHubScreenState();
}

class _GroupHubScreenState extends State<GroupHubScreen> {
  late bool _isJoined;

  @override
  void initState() {
    super.initState();
    _isJoined = widget.initiallyJoined;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
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
                        color: AppColors.textPrimary.withValues(alpha: 0.06),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.textPrimary.withValues(alpha: 0.08),
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: AppColors.textPrimary,
                        size: 16,
                      ),
                    ),
                  ),
                  Text(
                    widget.category,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.more_horiz,
                      color: AppColors.textSecondary,
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
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.textPrimary.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.textPrimary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.groups_outlined,
                                  color: AppColors.textPrimary,
                                  size: 28,
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _isJoined = !_isJoined;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isJoined
                                      ? AppColors.textPrimary.withValues(
                                          alpha: 0.1,
                                        )
                                      : AppColors.textPrimary,
                                  foregroundColor: _isJoined
                                      ? AppColors.textPrimary
                                      : AppColors.onAccent,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Text(
                                  _isJoined ? 'Joined' : 'Join Group',
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
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.membersCount} Members • Active Hub',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
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
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.textPrimary.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.textPrimary.withValues(
                              alpha: 0.08,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'COHORT CONNECTION',
                              style: TextStyle(
                                color: AppColors.textSecondary,
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
                            const Text(
                              'This group is linked to the same school, program, year, and class cohort.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Pinned Announcement
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.textPrimary.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.push_pin_outlined,
                            color: AppColors.textSecondary,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pinned Announcement',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'End of semester project submission deadlines and lab hours updated for SICT students.',
                                  style: TextStyle(
                                    color: AppColors.textPrimary.withValues(
                                      alpha: 0.6,
                                    ),
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

                    // Feed Section Title
                    const Text(
                      'Group Discussion Feed',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Sample Feed Items
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.textPrimary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.secondarySurface.withValues(
                  alpha: 0.1,
                ),
                child: const Icon(
                  Icons.person,
                  color: AppColors.textPrimary,
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                author,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                time,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
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
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
