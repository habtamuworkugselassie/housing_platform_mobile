import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/review_model.dart';
import '../services/property_service.dart';
import 'property_provider.dart';

class ReviewState {
  final bool isLoading;
  final List<ReviewModel> reviews;
  final String? error;

  const ReviewState({
    this.isLoading = false,
    this.reviews = const [],
    this.error,
  });

  ReviewState copyWith({
    bool? isLoading,
    List<ReviewModel>? reviews,
    String? error,
    bool clearError = false,
  }) {
    return ReviewState(
      isLoading: isLoading ?? this.isLoading,
      reviews: reviews ?? this.reviews,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ReviewNotifier extends StateNotifier<ReviewState> {
  final PropertyService _service;
  final String propertyId;

  ReviewNotifier(this._service, this.propertyId) : super(const ReviewState()) {
    loadReviews();
  }

  Future<void> loadReviews() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final reviews = await _service.getReviews(propertyId);
      state = state.copyWith(
        isLoading: false,
        reviews: reviews,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> submitReview(int rating, String comment,
      {String? userId}) async {
    try {
      await _service.submitReview(
        propertyId,
        rating,
        comment,
        userId: userId,
      );
      // Refresh reviews after submission
      await loadReviews();
    } catch (e) {
      // Re-throw to let UI handle specific error messages (e.g. toast)
      rethrow;
    }
  }
}

final reviewProvider =
    StateNotifierProvider.family<ReviewNotifier, ReviewState, String>(
        (ref, propertyId) {
  final service = ref.watch(propertyServiceProvider);
  return ReviewNotifier(service, propertyId);
});
