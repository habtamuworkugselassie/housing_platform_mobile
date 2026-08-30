import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/theme.dart';
import '../../../core/models/property_model.dart';
import '../../../core/widgets/property_image.dart';
import '../../../core/providers/review_provider.dart';
import '../../../core/providers/auth_provider.dart';

class PropertyDetailScreen extends ConsumerWidget {
  final PropertyModel property;

  const PropertyDetailScreen({Key? key, required this.property})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: _buildTransparentAppBar(context, ref),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImageHeader(context),
                _buildContentBody(context, ref),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomActionBar(context),
          )
        ],
      ),
    );
  }

  bool _checkAuth(BuildContext context, WidgetRef ref) {
    final authState = ref.read(authProvider);
    if (authState.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to perform this action.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return false;
    }
    return true;
  }

  AppBar _buildTransparentAppBar(BuildContext context, WidgetRef ref) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 4,
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(LucideIcons.arrowLeft,
                color: AppTheme.textPrimary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 4,
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(LucideIcons.share2,
                  color: AppTheme.textPrimary, size: 20),
              onPressed: () {
                Share.share('Check out this property: ${property.title}');
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 4,
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(LucideIcons.heart,
                  color: AppTheme.textPrimary, size: 20),
              onPressed: () {
                if (_checkAuth(context, ref)) {
                  // TODO: Toggle favorite
                }
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildImageHeader(BuildContext context) {
    return SizedBox(
      height: 350,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PropertyImage(
            imageUrl: property.imageUrl,
            propertyType: property.type,
            height: 350,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.4),
                  Colors.transparent,
                  Colors.transparent,
                  AppTheme.scaffoldBackgroundColor,
                ],
                stops: const [0.0, 0.3, 0.8, 1.0],
              ),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                property.type,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildContentBody(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      transform: Matrix4.translationValues(0, -20, 0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    property.title,
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                ),
                Text(
                  property.priceETB > 0
                      ? 'ETB ${property.price.toStringAsFixed(0)}'
                      : '\$${property.price.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: AppTheme.primaryColor,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(LucideIcons.mapPin,
                    size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 6),
                Text(
                  property.location,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSpecsRow(context),
            const SizedBox(height: 24),
            Text(
              'Description',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              property.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.5,
                  ),
            ),
            if (property.latitude != null && property.longitude != null) ...[
              const SizedBox(height: 24),
              Text(
                'Location',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _buildMapSection(context),
            ],
            const SizedBox(height: 24),
            Text(
              'Listing Agent',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _buildAgentCard(context),
            const SizedBox(height: 24),
            Text(
              'Reviews',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _buildReviewSection(context, ref),
          ],
        ),
      ),
    );
  }

  Future<void> _openInMapsForRouting(double lat, double lng) async {
    final String url = Platform.isIOS
        ? 'http://maps.apple.com/?daddr=$lat,$lng'
        : 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildMapSection(BuildContext context) {
    final lat = property.latitude!;
    final lng = property.longitude!;
    final center = LatLng(lat, lng);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 220,
            width: double.infinity,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: 15,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.drag |
                      InteractiveFlag.pinchZoom |
                      InteractiveFlag.doubleTapZoom,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.housingplatform.mobile',
                  subdomains: const ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: center,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        LucideIcons.mapPin,
                        color: AppTheme.primaryColor,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 44,
          child: OutlinedButton.icon(
            onPressed: () => _openInMapsForRouting(lat, lng),
            icon: const Icon(LucideIcons.navigation,
                size: 20, color: AppTheme.primaryColor),
            label: const Text('Navigate'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              side: const BorderSide(color: AppTheme.primaryColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildSpecItem(
              context, LucideIcons.bed, '${property.bedrooms} Beds'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSpecItem(
              context, LucideIcons.bath, '${property.bathrooms} Baths'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSpecItem(
              context, LucideIcons.maximize, '${property.area} Sqft'),
        ),
      ],
    );
  }

  Widget _buildSpecItem(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryColor),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          AgentAvatarImage(
            imageUrl: property.agent.imageUrl,
            size: 56,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  property.agent.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        property.agent.organization,
                        style: Theme.of(context).textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (property.showVerificationBadge &&
                        property.verificationBadgeLabel != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              AppTheme.verifiedBadgeBlue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppTheme.verifiedBadgeBlue
                                  .withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.badgeCheck,
                                size: 12, color: AppTheme.verifiedBadgeBlue),
                            const SizedBox(width: 4),
                            Text(
                              property.verificationBadgeLabel!,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: AppTheme.verifiedBadgeBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () {
              // TODO: Implement chat functionality
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.messageCircle,
                  color: AppTheme.primaryColor, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () async {
              final Uri launchUri = Uri(
                scheme: 'tel',
                path: property.agent.phone,
              );
              if (await canLaunchUrl(launchUri)) {
                await launchUrl(launchUri);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.phoneCall,
                  color: AppTheme.success, size: 20),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildReviewSection(BuildContext context, WidgetRef ref) {
    final reviewState = ref.watch(reviewProvider(property.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (reviewState.isLoading)
          const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor))
        else if (reviewState.error != null)
          Text(
            'Failed to load reviews.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.error,
                ),
          )
        else if (reviewState.reviews.isEmpty)
          Text(
            'No reviews yet.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reviewState.reviews.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final review = reviewState.reviews[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: review.userImageUrl != null
                              ? NetworkImage(review.userImageUrl!)
                              : null,
                          child: review.userImageUrl == null
                              ? const Icon(LucideIcons.user, size: 16)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            review.userName,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        Row(
                          children: List.generate(5, (starIndex) {
                            return Icon(
                              starIndex < review.rating
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 14,
                              color: AppTheme.primaryColor,
                            );
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      review.comment,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              );
            },
          ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () {
            if (_checkAuth(context, ref)) {
              _showReviewDialog(context, ref);
            }
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primaryColor,
            side: const BorderSide(color: AppTheme.primaryColor),
          ),
          child: const Text('Write a Review'),
        ),
      ],
    );
  }

  void _showReviewDialog(BuildContext context, WidgetRef ref) {
    int rating = 5;
    final commentController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceColor,
              title: const Text('Write a Review',
                  style: TextStyle(color: AppTheme.textPrimary)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: AppTheme.primaryColor,
                          size: 32,
                        ),
                        onPressed: () {
                          setState(() {
                            rating = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentController,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Enter your review here...',
                      hintStyle: TextStyle(color: AppTheme.textSecondary),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppTheme.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppTheme.primaryColor),
                      ),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text('Cancel',
                      style: TextStyle(color: AppTheme.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final comment = commentController.text.trim();
                          if (comment.isEmpty) return;

                          final authState = ref.read(authProvider);
                          final userId = authState.user?.userId;

                          setState(() {
                            isSubmitting = true;
                          });

                          try {
                            await ref
                                .read(reviewProvider(property.id).notifier)
                                .submitReview(
                                  rating,
                                  comment,
                                  userId: (userId != null && userId.isNotEmpty)
                                      ? userId
                                      : null,
                                );

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Review submitted successfully!'),
                                  backgroundColor: AppTheme.success,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              setState(() {
                                isSubmitting = false;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to submit review: $e'),
                                  backgroundColor: AppTheme.error,
                                ),
                              );
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildBottomActionBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: const Border(top: BorderSide(color: AppTheme.borderColor)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  final Uri launchUri = Uri(
                    scheme: 'tel',
                    path: property.agent.phone,
                  );
                  if (await canLaunchUrl(launchUri)) {
                    await launchUrl(launchUri);
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: const BorderSide(color: AppTheme.primaryColor),
                ),
                child: const Text('Contact Agent'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Book a Tour'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
