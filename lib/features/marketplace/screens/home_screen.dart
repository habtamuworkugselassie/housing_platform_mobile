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
import '../../../core/widgets/brand.dart';

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
                const SizedBox(height: 4),
                const ExhibitionInfoSection(),
                const SizedBox(height: 20),
                const SponsorCarouselWidget(height: 236, autoplaySeconds: 5),
                const SizedBox(height: 20),
                _buildLiveBanner(context),
                const SizedBox(height: 16),
                _buildMarketplaceEntry(context),
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
        child: BrandPanel(
          color: AppTheme.brandDeep,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const LivePill(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Live from the exhibition',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            )),
                    const SizedBox(height: 2),
                    Text('Watch live streams, or go live from your booth.',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12)),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                ),
                child: const Icon(LucideIcons.chevronRight, color: AppTheme.goldBright, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final auth = ref.watch(authProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Row(
        children: [
          Image.asset('assets/branding/ethio-build-connect-logo.png', height: 34, fit: BoxFit.contain),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Ethio Build Connect',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: AppTheme.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (auth.isAuthenticated)
            GestureDetector(
              onTap: () => ref.read(rootTabIndexProvider.notifier).state = 5,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.goldBright, width: 2),
                ),
                child: CircleAvatar(
                  radius: 19,
                  backgroundColor: AppTheme.brandPanel,
                  child: Text(
                    (auth.user?.firstName ?? 'U').isNotEmpty ? auth.user!.firstName[0].toUpperCase() : 'U',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ),
            )
          else
            TextButton.icon(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
              },
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColorDark,
                backgroundColor: AppTheme.violet50,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: const StadiumBorder(),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              icon: const Icon(LucideIcons.userCircle, size: 18),
              label: const Text('Sign in'),
            ),
        ],
      ),
    );
  }

  /// Marketplace entry: one card that opens the organizations-by-category screen.
  Widget _buildMarketplaceEntry(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const MarketplaceScreen()));
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(color: AppTheme.violet50, shape: BoxShape.circle),
                  child: const Icon(LucideIcons.store, color: AppTheme.primaryColorDark, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Marketplace',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      const Text('Banks, contractors, suppliers and more by category',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(LucideIcons.chevronRight, color: AppTheme.textSecondary, size: 20),
              ],
            ),
          ),
        ),
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
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppTheme.borderColor),
                boxShadow: AppTheme.cardShadow,
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
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
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
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 22),
            ),
          ),
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryColorDark,
              backgroundColor: AppTheme.violet50,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: const StadiumBorder(),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            child: const Text('See all'),
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
