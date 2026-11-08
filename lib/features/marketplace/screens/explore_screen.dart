import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/theme.dart';
import '../../../core/models/property_model.dart';
import '../../../core/providers/property_provider.dart';
import '../widgets/property_card.dart';
import '../../property/screens/property_detail_screen.dart';
import '../../../core/widgets/brand.dart';

/// Full list of properties (Explore tab). Used when user taps "See All" from Home.
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Use explorePropertyProvider for independent state
    Future.microtask(() => ref.read(explorePropertyProvider.notifier).loadInitial());
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
      ref.read(explorePropertyProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final propertyState = ref.watch(explorePropertyProvider);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                      eyebrow: 'Properties',
                      title: 'Explore',
                      subtitle: 'Browse every available listing from developers and agents.',
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      onSubmitted: (q) => ref.read(explorePropertyProvider.notifier).loadInitial(searchTerm: q),
                      decoration: InputDecoration(
                        hintText: 'Search properties...',
                        prefixIcon: const Icon(LucideIcons.search, color: AppTheme.textSecondary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(999)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: const BorderSide(color: AppTheme.borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (propertyState.error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error: ${propertyState.error}', style: const TextStyle(color: AppTheme.error)),
                ),
              ),
            if (propertyState.isLoading && propertyState.properties.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (propertyState.properties.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.home, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No properties found',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == propertyState.properties.length) {
                        if (propertyState.isFetchingMore) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return const SizedBox.shrink();
                      }
                      final property = propertyState.properties[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: PropertyCard(
                          property: property,
                          isHorizontal: false,
                          onTap: () => _navigateToDetail(context, property),
                        ),
                      );
                    },
                    childCount: propertyState.properties.length + (propertyState.isFetchingMore ? 1 : 0),
                  ),
                ),
              ),
          ],
        ),
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
