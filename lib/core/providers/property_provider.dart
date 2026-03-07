import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/property_model.dart';
import '../services/property_service.dart';
import 'auth_provider.dart';

final propertyServiceProvider = Provider<PropertyService>((ref) {
  return PropertyService(ref.read(apiClientProvider));
});

class PropertyState {
  final bool isLoading;
  final bool isFetchingMore;
  final List<PropertyModel> properties;
  final List<PropertyModel> featuredProperties;
  final String? error;
  final bool hasMore;
  final int currentPage;

  const PropertyState({
    this.isLoading = false,
    this.isFetchingMore = false,
    this.properties = const [],
    this.featuredProperties = const [],
    this.error,
    this.hasMore = true,
    this.currentPage = 0,
  });

  PropertyState copyWith({
    bool? isLoading,
    bool? isFetchingMore,
    List<PropertyModel>? properties,
    List<PropertyModel>? featuredProperties,
    String? error,
    bool? hasMore,
    int? currentPage,
    bool clearError = false,
  }) {
    return PropertyState(
      isLoading: isLoading ?? this.isLoading,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      properties: properties ?? this.properties,
      featuredProperties: featuredProperties ?? this.featuredProperties,
      error: clearError ? null : (error ?? this.error),
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

/// Map UI category label to backend property type (GET /properties?type=).
/// Returns null for "All" or unknown so no type filter is applied.
String? _categoryToBackendType(String? category) {
  if (category == null || category.isEmpty) return null;
  switch (category) {
    case 'All': return null;
    case 'House': return 'HOUSE';
    case 'Apartment': return 'APARTMENT';
    case 'Villa': return 'VILLA';
    case 'Condo': return 'CONDOMINIUM';
    case 'Land': return 'LAND';
    default: return category.toUpperCase();
  }
}

/// Sort so sponsored and verified properties come first (for Featured Properties list).
List<PropertyModel> _sortSponsoredAndVerifiedFirst(List<PropertyModel> list) {
  final sorted = List<PropertyModel>.from(list);
  int sortRank(PropertyModel p) {
    if (p.isSponsored && p.showVerificationBadge) return 0;
    if (p.isSponsored) return 1;
    if (p.showVerificationBadge) return 2;
    return 3;
  }
  sorted.sort((a, b) => sortRank(a).compareTo(sortRank(b)));
  return sorted;
}

class PropertyNotifier extends StateNotifier<PropertyState> {
  final PropertyService _propertyService;
  static const int pageSize = 10;
  
  // Current active filters
  String? _currentCity;
  String? _currentSearchTerm;
  String? _currentType;

  PropertyNotifier(this._propertyService) : super(const PropertyState());

  Future<void> loadInitial({String? city, String? searchTerm, String? category}) async {
    if (state.isLoading) return;
    
    _currentCity = city;
    _currentSearchTerm = searchTerm;
    _currentType = _categoryToBackendType(category);
    
    state = state.copyWith(isLoading: true, clearError: true, currentPage: 0, properties: []);
    
    try {
      if (_currentSearchTerm != null && _currentSearchTerm!.isNotEmpty) {
        // Use generic search endpoint; filter by type client-side; sort sponsored/verified first
        final results = await _propertyService.searchProperties(
          title: _currentSearchTerm,
          city: _currentCity,
        );
        var list = results;
        if (_currentType != null) {
          list = results.where((p) => p.type.toUpperCase() == _currentType).toList();
        }
        state = state.copyWith(
          isLoading: false,
          properties: _sortSponsoredAndVerifiedFirst(list),
          hasMore: false, // Search doesn't paginate in backend (returns top 50)
        );
      } else {
        // Use paginated list with optional type filter; sort so sponsored and verified come first
        final pagedData = await _propertyService.getProperties(
          page: 0,
          size: pageSize,
          city: _currentCity,
          type: _currentType,
        );
        final sorted = _sortSponsoredAndVerifiedFirst(pagedData.content);
        final featured = sorted.where((p) => p.isFeatured).toList();
        
        state = state.copyWith(
          isLoading: false,
          properties: sorted,
          featuredProperties: featured,
          hasMore: pagedData.hasMore,
          currentPage: 0,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    // Prevent concurrent fetches or fetching when exhausted
    if (state.isLoading || state.isFetchingMore || !state.hasMore) return;
    
    // Don't paginate search results since search endpoint limits to 50
    if (_currentSearchTerm != null && _currentSearchTerm!.isNotEmpty) return;

    state = state.copyWith(isFetchingMore: true);
    final nextPage = state.currentPage + 1;
    
    try {
      final pagedData = await _propertyService.getProperties(
        page: nextPage,
        size: pageSize,
        city: _currentCity,
        type: _currentType,
      );
      
      final featured = pagedData.content.where((p) => p.isFeatured).toList();
      
      // Merge unique featured properties
      final updatedFeatured = [...state.featuredProperties];
      for (var p in featured) {
        if (!updatedFeatured.any((existing) => existing.id == p.id)) {
          updatedFeatured.add(p);
        }
      }
      
      // Append new page and re-sort so sponsored/verified stay first
      final merged = [...state.properties, ...pagedData.content];
      state = state.copyWith(
        isFetchingMore: false,
        properties: _sortSponsoredAndVerifiedFirst(merged),
        featuredProperties: updatedFeatured,
        hasMore: pagedData.hasMore,
        currentPage: nextPage,
      );
    } catch (e) {
      state = state.copyWith(
        isFetchingMore: false,
        error: e.toString(),
      );
    }
  }
}

// Global Provider
final propertyProvider = StateNotifierProvider<PropertyNotifier, PropertyState>((ref) {
  return PropertyNotifier(ref.read(propertyServiceProvider));
});
