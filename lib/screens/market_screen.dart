import 'package:zitface_mobile/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'create_listing_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  String _activeCategory = 'All';

  final List<String> _categories = [
    'All',
    'Textbooks',
    'Electronics',
    'Hostel Gear',
    'Apparel',
  ];

  final List<Map<String, String>> _listings = [
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

  void _openCreateListing() async {
    final newListing = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateListingScreen(),
    );

    if (newListing != null) {
      setState(() {
        _listings.insert(0, newListing);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredListings = _activeCategory == 'All'
        ? _listings
        : _listings
              .where((item) => item['category'] == _activeCategory)
              .toList();

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Campus Market',
                    style: TextStyle(
                      color: AppColors.textPrimary,
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
                  color: AppColors.textPrimary.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.textPrimary.withValues(alpha: 0.08),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search books, laptops, electronics...',
                          hintStyle: TextStyle(
                            color: AppColors.textSecondary,
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
                            ? AppColors.textPrimary
                            : AppColors.textPrimary.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.textPrimary
                              : AppColors.textPrimary.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.onAccent
                              : AppColors.textSecondary,
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
              child: filteredListings.isEmpty
                  ? const Center(
                      child: Text(
                        'No listings in this category yet.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
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
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.textPrimary.withValues(
                              alpha: 0.03,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: AppColors.textPrimary.withValues(
                                alpha: 0.06,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Placeholder Image Box
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: AppColors.textPrimary.withValues(
                                      alpha: 0.05,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.shopping_bag_outlined,
                                      color: AppColors.textSecondary,
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
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),

                              Text(
                                item['price']!,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
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
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 10,
                                    ),
                                  ),
                                  Text(
                                    item['time']!,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 9,
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
