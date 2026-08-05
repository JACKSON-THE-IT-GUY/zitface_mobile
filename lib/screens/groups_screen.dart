import 'package:flutter/material.dart';
import 'group_hub_screen.dart';

// 1. Group Model Class
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

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<CbuGroup> _allGroups = [
    CbuGroup(
      name: 'SICT (Computer Science)',
      members: '1.2k',
      category: 'School Hub',
      description: 'Official portal for SICT updates, programming labs, and project teams.',
      icon: Icons.code_rounded,
      isJoined: true,
    ),
    CbuGroup(
      name: 'CBU Guild Union',
      members: '4.8k',
      category: 'Campus Life',
      description: 'Student representation, campus announcements, and university politics.',
      icon: Icons.account_balance_rounded,
      isJoined: true,
    ),
    CbuGroup(
      name: 'School of Engineering',
      members: '2.1k',
      category: 'School Hub',
      description: 'Civil, Electrical, and Mechanical engineering discussions and notes.',
      icon: Icons.engineering_rounded,
      isJoined: false,
    ),
    CbuGroup(
      name: 'Copperbelt Football Fanatics',
      members: '850',
      category: 'Sports & Recreation',
      description: 'CBU sports fixtures, inter-school tournaments, and match chat.',
      icon: Icons.sports_soccer_rounded,
      isJoined: false,
    ),
    CbuGroup(
      name: 'Campus Developers & Tech',
      members: '640',
      category: 'Tech Community',
      description: 'Flutter, Web, AI, and software dev collaboration across CBU.',
      icon: Icons.terminal_rounded,
      isJoined: true,
    ),
  ];

  List<CbuGroup> _filteredGroups = [];

  @override
  void initState() {
    super.initState();
    _filteredGroups = List.from(_allGroups);
    _searchController.addListener(_filterGroups);
  }

  void _filterGroups() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredGroups = List.from(_allGroups);
      } else {
        _filteredGroups = _allGroups.where((group) {
          return group.name.toLowerCase().contains(query) ||
              group.category.toLowerCase().contains(query) ||
              group.description.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090A0F),
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
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Connect with your school & student hubs',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: const Icon(
                        Icons.group_add_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Search Bar Input
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      icon: const Icon(Icons.search, color: Colors.white38, size: 20),
                      hintText: 'Search CBU schools or clubs...',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                      border: InputBorder.none,
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.white38, size: 18),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Empty Search State
            if (_filteredGroups.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(
                    child: Text(
                      'No groups found matching your search.',
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                  ),
                ),
              ),

            // List of Groups
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
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
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
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
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.12),
                                    ),
                                  ),
                                  child: Icon(
                                    group.icon,
                                    color: Colors.white,
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
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${group.members} members • ${group.category}',
                                        style: const TextStyle(
                                          color: Colors.white38,
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
                                          ? Colors.white.withValues(alpha: 0.1)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: group.isJoined
                                            ? Colors.white.withValues(alpha: 0.2)
                                            : Colors.transparent,
                                      ),
                                    ),
                                    child: Text(
                                      group.isJoined ? 'Joined' : 'Join',
                                      style: TextStyle(
                                        color: group.isJoined
                                            ? Colors.white
                                            : const Color(0xFF090A0F),
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
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: _filteredGroups.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }
}