import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widget/glass_card.dart';

class _CbuSchool {
  final String name;
  final String abbreviation;
  final IconData icon;

  const _CbuSchool({
    required this.name,
    required this.abbreviation,
    required this.icon,
  });
}

class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({super.key});

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  static const List<_CbuSchool> _schools = [
    _CbuSchool(
      name: 'School of Business',
      abbreviation: 'SOB',
      icon: Icons.business_center_outlined,
    ),
    _CbuSchool(
      name: 'School of Built Environment',
      abbreviation: 'SOBE',
      icon: Icons.architecture_outlined,
    ),
    _CbuSchool(
      name: 'School of Engineering',
      abbreviation: 'SOE',
      icon: Icons.engineering_outlined,
    ),
    _CbuSchool(
      name: 'School of Humanities and Social Sciences',
      abbreviation: 'SHSS',
      icon: Icons.public_outlined,
    ),
    _CbuSchool(
      name: 'School of Information and Communication Technology',
      abbreviation: 'SICT',
      icon: Icons.computer_outlined,
    ),
    _CbuSchool(
      name: 'School of Mathematics and Natural Sciences',
      abbreviation: 'SMNS',
      icon: Icons.science_outlined,
    ),
    _CbuSchool(
      name: 'School of Mines and Mineral Sciences',
      abbreviation: 'SMMS',
      icon: Icons.landscape_outlined,
    ),
    _CbuSchool(
      name: 'School of Natural Resources',
      abbreviation: 'SNR',
      icon: Icons.eco_outlined,
    ),
    _CbuSchool(
      name: 'School of Medicine',
      abbreviation: 'SOM',
      icon: Icons.medical_services_outlined,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.toLowerCase();
    final schools = _schools.where((school) {
      return school.name.toLowerCase().contains(query) ||
          school.abbreviation.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Study Materials',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Find notes and resources by CBU school and program.',
                      style: TextStyle(
                        color: AppColors.textPrimary.withValues(alpha: 0.65),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _searchController,
                      onChanged: (value) =>
                          setState(() => _query = value.trim()),
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search schools',
                        hintStyle: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.textSecondary,
                        ),
                        filled: true,
                        fillColor: AppColors.textPrimary.withValues(
                          alpha: 0.07,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: AppColors.textPrimary.withValues(
                              alpha: 0.08,
                            ),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: AppColors.textPrimary.withValues(
                              alpha: 0.08,
                            ),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: AppColors.accent.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'ALL SCHOOLS',
                      style: TextStyle(
                        color: AppColors.textPrimary.withValues(alpha: 0.55),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (schools.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No schools match "$_query".',
                      style: const TextStyle(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildSchoolCard(schools[index]),
                    ),
                    childCount: schools.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolCard(_CbuSchool school) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            splashColor: AppColors.textPrimary.withValues(alpha: 0.04),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(school.icon, color: AppColors.textPrimary, size: 21),
            ),
            title: Text(
              school.name,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              '${school.abbreviation} · Programs and materials',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
            iconColor: AppColors.textSecondary,
            collapsedIconColor: AppColors.textSecondary,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.textPrimary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.menu_book_outlined,
                      color: AppColors.textSecondary,
                      size: 26,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Materials are being collected',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Program-specific notes, past papers, and study guides will appear here once added.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
