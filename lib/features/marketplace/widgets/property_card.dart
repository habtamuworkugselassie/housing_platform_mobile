import 'package:flutter/material.dart';
import '../../../../core/models/property_model.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/property_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PropertyCard extends StatelessWidget {
  final PropertyModel property;
  final bool isHorizontal;
  final VoidCallback onTap;

  const PropertyCard({
    Key? key,
    required this.property,
    this.isHorizontal = false,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isHorizontal) {
      return _buildHorizontalCard(context);
    }
    return _buildVerticalCard(context);
  }

  Widget _buildHorizontalCard(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16, bottom: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(((0.05) * 255).toInt()),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Header
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: PropertyImage(
                    imageUrl: property.imageUrl,
                    propertyType: property.type,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(((0.1) * 255).toInt()),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(LucideIcons.heart,
                          size: 20, color: AppTheme.textSecondary),
                      onPressed: () {},
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ),
                if (property.isFeatured)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Featured',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),
                if (property.showVerificationBadge && property.verificationBadgeLabel != null)
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.verifiedBadgeBlue,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(80),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.badgeCheck,
                              size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            property.verificationBadgeLabel!,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            // Content Body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${property.price.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            property.title,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (property.showVerificationBadge && property.verificationBadgeLabel != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.verifiedBadgeBlue.withAlpha(
                                  ((0.2) * 255).toInt()),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: AppTheme.verifiedBadgeBlue.withAlpha(
                                      ((0.5) * 255).toInt())),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(LucideIcons.badgeCheck,
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
                                        fontSize: 11,
                                      ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    if (property.realEstateCompanyName != null &&
                        property.realEstateCompanyName!.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          property.realEstateCompanyName!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    Row(
                      children: [
                        const Icon(LucideIcons.mapPin,
                            size: 14, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            property.location,
                            style: Theme.of(context).textTheme.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSpec(context, LucideIcons.bed,
                            '${property.bedrooms} Beds'),
                        _buildSpec(context, LucideIcons.bath,
                            '${property.bathrooms} Baths'),
                        _buildSpec(context, LucideIcons.maximize,
                            '${property.area} sqft'),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalCard(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(((0.04) * 255).toInt()),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image Left Side
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(16)),
              child: PropertyImage(
                imageUrl: property.imageUrl,
                propertyType: property.type,
                height: 120,
                width: 120,
                fit: BoxFit.cover,
              ),
            ),
            // Content Right Side
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  property.title,
                                  style: Theme.of(context).textTheme.titleMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (property.showVerificationBadge && property.verificationBadgeLabel != null) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.verifiedBadgeBlue.withAlpha(
                                        ((0.2) * 255).toInt()),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: AppTheme.verifiedBadgeBlue.withAlpha(
                                            ((0.5) * 255).toInt())),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(LucideIcons.badgeCheck,
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
                                              fontSize: 11,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const Icon(LucideIcons.heart,
                            size: 18, color: AppTheme.textSecondary),
                      ],
                    ),
                    if (property.realEstateCompanyName != null &&
                        property.realEstateCompanyName!.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        property.realEstateCompanyName!,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      property.location,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${property.price.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildSpec(
                            context, LucideIcons.bed, '${property.bedrooms}',
                            isSmall: true),
                        const SizedBox(width: 12),
                        _buildSpec(
                            context, LucideIcons.bath, '${property.bathrooms}',
                            isSmall: true),
                        const SizedBox(width: 12),
                        _buildSpec(context, LucideIcons.maximize,
                            '${property.area} sqft',
                            isSmall: true),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpec(BuildContext context, IconData icon, String label,
      {bool isSmall = false}) {
    return Row(
      children: [
        Icon(icon, size: isSmall ? 14 : 16, color: AppTheme.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: isSmall ? 12 : 13,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}
