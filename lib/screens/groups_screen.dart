import 'package:zitface_mobile/theme/app_theme.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'group_hub_screen.dart';

class CbuGroup {
  final String name;
  final String members;
  final String category;
  final String description;
  final IconData icon;
  bool isJoined;

  CbuGroup({
    required this.name,
    required this.members,
    required this.category,
    required this.description,
    required this.icon,
    required this.isJoined,
  });
}

class _AcademicCohort {
  final String id;
  final String school;
  final String program;
  final int year;
  final String classRep;
  final List<_AcademicGroup> groups;

  _AcademicCohort({
    required this.id,
    required this.school,
    required this.program,
    required this.year,
    required this.classRep,
    required this.groups,
  });
}

class _AcademicGroup {
  final String id;
  final String name;
  final String type;
  final IconData icon;

  const _AcademicGroup({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
  });
}

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  static const String _cohortStorageKey = 'academic_cohorts';

  final TextEditingController _searchController = TextEditingController();
  final List<_AcademicCohort> _cohorts = [];
  List<_AcademicCohort> _filteredCohorts = [];
  bool _isLoadingCohorts = true;

  final List<CbuGroup> _allGroups = [
    CbuGroup(
      name: 'SICT (Computer Science)',
      members: '1.2k',
      category: 'School Hub',
      description:
          'Official portal for SICT updates, programming labs, and project teams.',
      icon: Icons.code_rounded,
      isJoined: true,
    ),
    CbuGroup(
      name: 'CBU Guild Union',
      members: '4.8k',
      category: 'Campus Life',
      description:
          'Student representation, campus announcements, and university politics.',
      icon: Icons.account_balance_rounded,
      isJoined: true,
    ),
    CbuGroup(
      name: 'School of Engineering',
      members: '2.1k',
      category: 'School Hub',
      description:
          'Civil, Electrical, and Mechanical engineering discussions and notes.',
      icon: Icons.engineering_rounded,
      isJoined: false,
    ),
    CbuGroup(
      name: 'Copperbelt Football Fanatics',
      members: '850',
      category: 'Sports & Recreation',
      description:
          'CBU sports fixtures, inter-school tournaments, and match chat.',
      icon: Icons.sports_soccer_rounded,
      isJoined: false,
    ),
    CbuGroup(
      name: 'Campus Developers & Tech',
      members: '640',
      category: 'Tech Community',
      description:
          'Flutter, Web, AI, and software dev collaboration across CBU.',
      icon: Icons.terminal_rounded,
      isJoined: true,
    ),
  ];

  List<CbuGroup> _filteredGroups = [];

  @override
  void initState() {
    super.initState();
    _filteredGroups = List.from(_allGroups);
    _filteredCohorts = List.from(_cohorts);
    _searchController.addListener(_filterGroups);
    _loadCohorts();
  }

  Future<void> _loadCohorts() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final storedCohorts = preferences.getString(_cohortStorageKey);
      final cohorts = storedCohorts == null
          ? <_AcademicCohort>[]
          : _decodeCohorts(storedCohorts);

      if (!mounted) return;
      _cohorts
        ..clear()
        ..addAll(cohorts);
      _isLoadingCohorts = false;
      _filterGroups();
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() => _isLoadingCohorts = false);
      _showCohortStorageError('load', error);
    }
  }

  List<_AcademicCohort> _decodeCohorts(String encoded) {
    final decoded = jsonDecode(encoded);
    if (decoded is! List<dynamic>) {
      throw const FormatException('Saved academic cohorts are not a list.');
    }

    return decoded.map((entry) {
      if (entry is! Map<String, dynamic>) {
        throw const FormatException('Saved academic cohort is invalid.');
      }
      final groups = entry['groups'];
      if (groups is! List<dynamic>) {
        throw const FormatException('Saved cohort groups are invalid.');
      }

      String readString(String key) {
        final value = entry[key];
        if (value is! String) {
          throw FormatException('Saved cohort field "$key" is invalid.');
        }
        return value;
      }

      final year = entry['year'];
      if (year is! int) {
        throw const FormatException('Saved academic year is invalid.');
      }

      return _AcademicCohort(
        id: readString('id'),
        school: readString('school'),
        program: readString('program'),
        year: year,
        classRep: readString('classRep'),
        groups: groups.map((groupEntry) {
          if (groupEntry is! Map<String, dynamic>) {
            throw const FormatException('Saved academic group is invalid.');
          }
          final id = groupEntry['id'];
          final name = groupEntry['name'];
          final type = groupEntry['type'];
          if (id is! String || name is! String || type is! String) {
            throw const FormatException('Saved academic group is incomplete.');
          }
          return _AcademicGroup(
            id: id,
            name: name,
            type: type,
            icon: _iconForGroupType(type),
          );
        }).toList(),
      );
    }).toList();
  }

  Map<String, Object> _cohortToJson(_AcademicCohort cohort) {
    return {
      'id': cohort.id,
      'school': cohort.school,
      'program': cohort.program,
      'year': cohort.year,
      'classRep': cohort.classRep,
      'groups': cohort.groups
          .map(
            (group) => {'id': group.id, 'name': group.name, 'type': group.type},
          )
          .toList(),
    };
  }

  IconData _iconForGroupType(String type) {
    return switch (type) {
      'Program group (data group)' => Icons.account_tree_outlined,
      'Class group' => Icons.groups_outlined,
      'Study group' => Icons.menu_book_outlined,
      'Lecture group' => Icons.co_present_outlined,
      'Tutorial group' => Icons.edit_note_outlined,
      _ => Icons.group_outlined,
    };
  }

  void _filterGroups() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredGroups = List.from(_allGroups);
        _filteredCohorts = List.from(_cohorts);
      } else {
        _filteredGroups = _allGroups.where((group) {
          return group.name.toLowerCase().contains(query) ||
              group.category.toLowerCase().contains(query) ||
              group.description.toLowerCase().contains(query);
        }).toList();
        _filteredCohorts = _cohorts.where((cohort) {
          final cohortMatches =
              cohort.school.toLowerCase().contains(query) ||
              cohort.program.toLowerCase().contains(query) ||
              cohort.classRep.toLowerCase().contains(query) ||
              'year ${cohort.year}'.contains(query);
          return cohortMatches ||
              cohort.groups.any(
                (group) =>
                    group.name.toLowerCase().contains(query) ||
                    group.type.toLowerCase().contains(query),
              );
        }).toList();
      }
    });
  }

  Future<void> _createAcademicCohort() async {
    final details = await showDialog<_CohortDetails>(
      context: context,
      builder: (context) => const _CreateCohortDialog(),
    );
    if (details == null || !mounted) return;

    final cohortId = DateTime.now().microsecondsSinceEpoch.toString();
    final programLabel = details.program.trim();
    final yearLabel = 'Year ${details.year}';
    final cohort = _AcademicCohort(
      id: cohortId,
      school: details.school.trim(),
      program: programLabel,
      year: details.year,
      classRep: details.classRep.trim(),
      groups: [
        _AcademicGroup(
          id: '${cohortId}_program',
          name: '$programLabel Program Group',
          type: 'Program group (data group)',
          icon: Icons.account_tree_outlined,
        ),
        _AcademicGroup(
          id: '${cohortId}_class',
          name: '$programLabel $yearLabel Class Group',
          type: 'Class group',
          icon: Icons.groups_outlined,
        ),
        _AcademicGroup(
          id: '${cohortId}_study',
          name: '$programLabel $yearLabel Study Group',
          type: 'Study group',
          icon: Icons.menu_book_outlined,
        ),
        _AcademicGroup(
          id: '${cohortId}_lecture',
          name: '$programLabel $yearLabel Lecture Group',
          type: 'Lecture group',
          icon: Icons.co_present_outlined,
        ),
        _AcademicGroup(
          id: '${cohortId}_tutorial',
          name: '$programLabel $yearLabel Tutorial Group',
          type: 'Tutorial group',
          icon: Icons.edit_note_outlined,
        ),
      ],
    );

    try {
      final preferences = await SharedPreferences.getInstance();
      final updatedCohorts = [cohort, ..._cohorts].map(_cohortToJson).toList();
      final saved = await preferences.setString(
        _cohortStorageKey,
        jsonEncode(updatedCohorts),
      );
      if (!saved) {
        _showCohortStorageError(
          'save',
          Exception('Device storage did not confirm the cohort update.'),
        );
        return;
      }
    } on Exception catch (error) {
      if (mounted) _showCohortStorageError('save', error);
      return;
    }

    if (!mounted) return;
    _cohorts.insert(0, cohort);
    _filterGroups();
  }

  void _showCohortStorageError(String action, Exception error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not $action academic cohorts: $error')),
    );
  }

  void _openAcademicGroup(_AcademicCohort cohort, _AcademicGroup group) {
    final classGroup = cohort.groups.firstWhere(
      (item) => item.type == 'Class group',
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupHubScreen(
          groupName: group.name,
          membersCount: '0',
          category: group.type,
          school: cohort.school,
          program: cohort.program,
          academicYear: cohort.year,
          classGroupName: classGroup.name,
          classRep: cohort.classRep,
          initiallyJoined: false,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // App Bar Title Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Campus Groups',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Connect with your school & student hubs',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      tooltip: 'Create academic cohort groups',
                      onPressed: _isLoadingCohorts
                          ? null
                          : _createAcademicCohort,
                      icon: const Icon(
                        Icons.group_add_outlined,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Search Bar Input
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.textPrimary.withValues(alpha: 0.08),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      icon: const Icon(
                        Icons.search,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      hintText: 'Search cohorts, programs, or groups...',
                      hintStyle: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: AppColors.textSecondary,
                                size: 18,
                              ),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ACADEMIC COHORTS',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _isLoadingCohorts
                          ? null
                          : _createAcademicCohort,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Create'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoadingCohorts)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              )
            else if (_filteredCohorts.isEmpty && _cohorts.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.textPrimary.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.textPrimary.withValues(alpha: 0.07),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.account_tree_outlined,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Create a cohort to link its school, program, year, class representative, and related groups.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (_filteredCohorts.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _buildCohortCard(_filteredCohorts[index]),
                    childCount: _filteredCohorts.length,
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: Text(
                  'CAMPUS & INTEREST GROUPS',
                  style: TextStyle(
                    color: AppColors.textPrimary.withValues(alpha: 0.55),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),

            // Empty Search State
            if (_filteredGroups.isEmpty && _filteredCohorts.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(
                    child: Text(
                      'No groups found matching your search.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),

            // List of Groups
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final group = _filteredGroups[index];

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GroupHubScreen(
                            groupName: group.name,
                            membersCount: group.members,
                            category: group.category,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.textPrimary.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.textPrimary.withValues(
                                    alpha: 0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppColors.textPrimary.withValues(
                                      alpha: 0.12,
                                    ),
                                  ),
                                ),
                                child: Icon(
                                  group.icon,
                                  color: AppColors.textPrimary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      group.name,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${group.members} members • ${group.category}',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    group.isJoined = !group.isJoined;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: group.isJoined
                                        ? AppColors.secondarySurface
                                        : AppColors.accent,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: group.isJoined
                                          ? AppColors.border
                                          : Colors.transparent,
                                    ),
                                  ),
                                  child: Text(
                                    group.isJoined ? 'Joined' : 'Join',
                                    style: TextStyle(
                                      color: group.isJoined
                                          ? AppColors.textSecondary
                                          : AppColors.onAccent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            group.description,
                            style: TextStyle(
                              color: AppColors.textPrimary.withValues(
                                alpha: 0.6,
                              ),
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }, childCount: _filteredGroups.length),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }

  Widget _buildCohortCard(_AcademicCohort cohort) {
    return Container(
      key: ValueKey(cohort.id),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.textPrimary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.09),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.textPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.school_outlined,
                  color: AppColors.textPrimary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cohort.program,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${cohort.school} · Year ${cohort.year}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Class representative: ${cohort.classRep}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final group in cohort.groups)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Material(
                color: AppColors.textPrimary.withValues(alpha: 0.035),
                borderRadius: BorderRadius.circular(12),
                child: ListTile(
                  key: ValueKey(group.id),
                  dense: true,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  leading: Icon(
                    group.icon,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  title: Text(
                    group.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    group.type,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary,
                    size: 19,
                  ),
                  onTap: () => _openAcademicGroup(cohort, group),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CohortDetails {
  final String school;
  final String program;
  final int year;
  final String classRep;

  const _CohortDetails({
    required this.school,
    required this.program,
    required this.year,
    required this.classRep,
  });
}

class _CreateCohortDialog extends StatefulWidget {
  const _CreateCohortDialog();

  @override
  State<_CreateCohortDialog> createState() => _CreateCohortDialogState();
}

class _CreateCohortDialogState extends State<_CreateCohortDialog> {
  final _formKey = GlobalKey<FormState>();
  final _schoolController = TextEditingController();
  final _programController = TextEditingController();
  final _classRepController = TextEditingController();
  int _year = 1;

  @override
  void dispose() {
    _schoolController.dispose();
    _programController.dispose();
    _classRepController.dispose();
    super.dispose();
  }

  String? _requiredField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text(
        'Create academic cohort',
        style: TextStyle(color: AppColors.textPrimary),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildField(_schoolController, 'School'),
              const SizedBox(height: 12),
              _buildField(_programController, 'Program'),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _year,
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _fieldDecoration('Academic year'),
                items: List.generate(
                  7,
                  (index) => DropdownMenuItem(
                    value: index + 1,
                    child: Text('Year ${index + 1}'),
                  ),
                ),
                onChanged: (year) {
                  if (year != null) setState(() => _year = year);
                },
              ),
              const SizedBox(height: 12),
              _buildField(_classRepController, 'Class representative name'),
              const SizedBox(height: 10),
              const Text(
                'This creates linked program, class, study, lecture, and tutorial groups for this cohort.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              _CohortDetails(
                school: _schoolController.text,
                program: _programController.text,
                year: _year,
                classRep: _classRepController.text,
              ),
            );
          },
          child: const Text('Create groups'),
        ),
      ],
    );
  }

  Widget _buildField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: _fieldDecoration(label),
      validator: _requiredField,
    );
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: AppColors.textPrimary.withValues(alpha: 0.14),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: AppColors.textPrimary.withValues(alpha: 0.6),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.redAccent),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.redAccent),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
