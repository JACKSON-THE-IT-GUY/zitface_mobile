import 'package:zitface_mobile/theme/app_theme.dart';
import 'package:zitface_mobile/widget/glass_card.dart';
import 'package:flutter/material.dart';
import '../services/zitface_backend.dart';
import 'create_listing_screen.dart';
import 'market_detail_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  String _activeCategory = 'All';
  final bool _cloudMode = ZitfaceBackend.isConfigured;
  final TextEditingController _searchController = TextEditingController();
  bool _isLoadingListings = ZitfaceBackend.isConfigured;

  final List<String> _categories = [
    'All',
    'Textbooks',
    'Electronics',
    'Hostel Gear',
    'Apparel',
    'Services',
  ];

  final List<Map<String, dynamic>> _listings = ZitfaceBackend.isConfigured
      ? []
      : [
    {
      'title': 'Engineering Maths Vol 1',
      'price': 'K150',
      'category': 'Textbooks',
      'seller': 'Phanciah C.',
      'time': '3 hours ago',
    },
    {
      'title': 'HP EliteBook 840 G3 (8GB/256GB)',
      'price': 'K3,800',
      'category': 'Electronics',
      'seller': 'Kabwe B.',
      'time': '5 hours ago',
    },
    {
      'title': 'Single Mattress + Cover',
      'price': 'K450',
      'category': 'Hostel Gear',
      'seller': 'David M.',
      'time': '1 day ago',
    },
    {
      'title': 'CBU SICT Hoodie (XL)',
      'price': 'K250',
      'category': 'Apparel',
      'seller': 'Jackson N.',
      'time': '2 days ago',
    },
        ];

  @override
  void initState() {
    super.initState();
    if (_cloudMode) _loadListings();
  }

  Future<void> _loadListings() async {
    try {
      final rows = await ZitfaceBackend.loadMarketListings();
      if (!mounted) return;
      setState(() {
        _listings
          ..clear()
          ..addAll(rows.map(_formatListing));
        _isLoadingListings = false;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() => _isLoadingListings = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load listings: $error')),
      );
    }
  }

  Map<String, dynamic> _formatListing(Map<String, dynamic> row) {
    final price = (row['price'] as num).toDouble();
    final createdAt = DateTime.tryParse(row['created_at'] as String)?.toLocal();
    final age = createdAt == null ? null : DateTime.now().difference(createdAt);
    final time = age == null || age.inMinutes < 1
        ? 'Just now'
        : age.inHours < 1
        ? '${age.inMinutes} min ago'
        : age.inDays < 1
        ? '${age.inHours} hr ago'
        : '${age.inDays} days ago';
    return {
      ...row,
      'price': 'K${price.toStringAsFixed(price == price.roundToDouble() ? 0 : 2)}',
      'seller': row['seller'] as String? ?? 'ZitFace member',
      'time': time,
    };
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCreateListing() async {
    final newListing = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateListingScreen(),
    );

    if (newListing == null) return;
    if (_cloudMode) {
      try {
        final row = await ZitfaceBackend.createMarketListing(
          title: newListing['title']!,
          price: newListing['priceAmount']!,
          category: newListing['category']!,
          description: newListing['description']!,
        );
        if (!mounted) return;
        setState(() => _listings.insert(0, _formatListing(row)));
      } on Exception catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not publish listing: $error')),
        );
      }
      return;
    }
    setState(() => _listings.insert(0, newListing));
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filteredListings = _listings.where((item) {
      final matchesCategory =
        _activeCategory == 'All' || item['category'] == _activeCategory;
      final matchesQuery =
        query.isEmpty ||
        (item['title'] as String).toLowerCase().contains(query) ||
        (item['seller'] as String).toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Campus Market',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: _openCreateListing,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add, color: AppColors.onAccent, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Sell Item',
                            style: TextStyle(
                              color: AppColors.onAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search books, laptops, electronics...',
                          hintStyle: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Categories Row
            SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = cat == _activeCategory;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _activeCategory = cat;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.onAccent
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Marketplace Grid
            Expanded(
                child: _isLoadingListings
                  ? const Center(child: CircularProgressIndicator())
                  : filteredListings.isEmpty
                  ? Center(
                      child: Text(
                        'No listings in this category yet.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.8,
                          ),
                      itemCount: filteredListings.length,
                      itemBuilder: (context, index) {
                        final item = filteredListings[index];
                        return InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MarketDetailScreen(
                                title: item['title'] as String,
                                price: item['price'] as String,
                                seller: item['seller'] as String,
                                sellerId: item['seller_id'] as String?,
                                location: 'Location not provided',
                                imageTag: 'No photo added',
                                description:
                                    item['description'] as String? ?? '',
                              ),
                            ),
                          ),
                          child: GlassCard(
                            padding: const EdgeInsets.all(12),
                            borderRadius: 18,
                            child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Placeholder Image Box
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.shopping_bag_outlined,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                      size: 32,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),

                              Text(
                                item['title']!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),

                              Text(
                                item['price']!,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    item['seller']!,
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                      fontSize: 10,
                                    ),
                                  ),
                                  Text(
                                    item['time']!,
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                      fontSize: 9,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            ),
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
