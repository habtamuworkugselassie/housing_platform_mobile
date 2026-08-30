import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/theme.dart';
import '../../../core/models/property_model.dart';
import '../../../core/providers/property_provider.dart';
import '../../../core/providers/root_tab_provider.dart';
import '../widgets/property_card.dart';
import '../widgets/category_selector.dart';
import '../widgets/sponsor_carousel_widget.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../screens/marketplace_screen.dart';
import '../../property/screens/property_detail_screen.dart';
import '../../auth/screens/auth_screen.dart';
import '../../exhibition/widgets/exhibition_info_section.dart';

import '../../../core/providers/auth_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final List<String> categories = [
    'All',
    'House',
    'Apartment',
    'Villa',
    'Condo',
    'Land',
  ];

  String selectedCategory = 'All';
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(propertyProvider.notifier).loadInitial(category: selectedCategory));
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(propertyProvider.notifier).loadMore();
    }
  }

  void _performSearch(String query) {
    ref.read(propertyProvider.notifier).loadInitial(
      searchTerm: query.isEmpty ? null : query,
      category: selectedCategory,
    );
  }

  void _showFilterBottomSheet() {
    final currentState = ref.read(propertyProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: FilterBottomSheet(
          initialMinPrice: currentState.minPrice,
          initialMaxPrice: currentState.maxPrice,
          initialBedrooms: currentState.bedrooms,
          initialBathrooms: currentState.bathrooms,
          onApply: (minPrice, maxPrice, bedrooms, bathrooms) {
            ref.read(propertyProvider.notifier).loadInitial(
              searchTerm: _searchController.text.trim().isEmpty ? null : _searchController.text,
              category: selectedCategory,
              minPrice: minPrice,
              maxPrice: maxPrice,
              bedrooms: bedrooms,
              bathrooms: bathrooms,
            );
          },
        ),
      ),
    );
  }

  void _goToExploreTab() {
    ref.read(rootTabIndexProvider.notifier).state = 1;
  }

  @override
  Widget build(BuildContext context) {
    final propertyState = ref.watch(propertyProvider);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(propertyProvider.notifier).loadInitial(
            searchTerm: _searchController.text.trim().isEmpty ? null : _searchController.text,
            category: selectedCategory,
          ),
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SponsorCarouselWidget(height: 220, autoplaySeconds: 5),
                const SizedBox(height: 24),
                const ExhibitionInfoSection(),
                const SizedBox(height: 16),
                _buildLiveBanner(context),
                const SizedBox(height: 24),
                CategorySelector(
                  categories: categories,
                  onCategorySelected: (category) {
                    setState(() {
                      selectedCategory = category;
                    });
                    ref.read(propertyProvider.notifier).loadInitial(
                      searchTerm: _searchController.text.trim().isEmpty ? null : _searchController.text,
                      category: category,
                    );
                  },
                ),
                const SizedBox(height: 24),
                _buildSearchBar(context),
                const SizedBox(height: 24),
                if (propertyState.error != null)
                   Padding(
                     padding: const EdgeInsets.all(16.0),
                     child: Text(
                       'Error: ${propertyState.error}',
                       style: const TextStyle(color: Colors.red),
                     ),
                   ),

                if (propertyState.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else ...[
                  _buildSectionHeader(
                    _searchController.text.isNotEmpty ? 'Search Results' : 'Featured Properties',
                    onSeeAll: _goToExploreTab,
                  ),
                  const SizedBox(height: 16),
                  if (propertyState.properties.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: Text('No properties found')),
                    )
                  else
                    _buildPropertyList(
                      context,
                      propertyState.properties,
                      propertyState.isFetchingMore,
                      propertyState.hasMore,
                      () => ref.read(propertyProvider.notifier).loadMore(),
                    ),
                ],
                const SizedBox(height: 24), // Bottom padding
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLiveBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => ref.read(rootTabIndexProvider.notifier).state = 3,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor),
            gradient: const LinearGradient(
              colors: [Color(0xFF3B1D5E), Color(0xFF241A4A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.error,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.radio, color: Colors.white, size: 14),
                    SizedBox(width: 6),
                    Text('LIVE',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Live from the exhibition',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            )),
                    const SizedBox(height: 2),
                    const Text('Watch live streams, or go live from your booth.',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronRight, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MarketplaceScreen(),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Marketplace',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(LucideIcons.store,
                        size: 16, color: AppTheme.primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      'Browse by category',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Icon(LucideIcons.chevronRight, size: 20),
                  ],
                ),
              ],
            ),
          ),
          if (ref.watch(authProvider).isAuthenticated)
            GestureDetector(
              onTap: () => ref.read(rootTabIndexProvider.notifier).state = 5,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.borderColor, width: 2),
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primaryColor,
                  child: Text(
                    (ref.watch(authProvider).user?.firstName ?? 'U').isNotEmpty
                        ? (ref.watch(authProvider).user!.firstName[0].toUpperCase())
                        : 'U',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(LucideIcons.userCircle, size: 32, color: AppTheme.primaryColor),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const Icon(LucideIcons.search, color: AppTheme.textSecondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onSubmitted: _performSearch,
                      textInputAction: TextInputAction.search,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Search for properties...',
                        hintStyle: TextStyle(color: AppTheme.textSecondary),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: IconButton(
              icon: const Icon(LucideIcons.slidersHorizontal, color: Colors.white),
              onPressed: _showFilterBottomSheet,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {required VoidCallback onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          GestureDetector(
            onTap: onSeeAll,
            child: const Text(
              'See All',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyList(
      BuildContext context,
      List<PropertyModel> properties,
      bool isFetchingMore,
      bool hasMore,
      VoidCallback onLoadMore) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          ...properties.map((prop) => PropertyCard(
                property: prop,
                isHorizontal: false,
                onTap: () => _navigateToDetail(context, prop),
              )),
          if (isFetchingMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (hasMore && properties.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onLoadMore,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: const BorderSide(color: AppTheme.primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Load more'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _navigateToDetail(BuildContext context, PropertyModel property) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PropertyDetailScreen(property: property),
      ),
    );
  }
}
