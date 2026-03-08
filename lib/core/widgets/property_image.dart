import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/theme.dart';

/// Placeholder icon and tint for property type when image fails to load.
IconData _placeholderIconForType(String? type) {
  if (type == null || type.isEmpty) return LucideIcons.image;
  switch (type.toUpperCase()) {
    case 'HOUSE':
      return LucideIcons.home;
    case 'APARTMENT':
    case 'CONDOMINIUM':
      return LucideIcons.building;
    case 'VILLA':
      return LucideIcons.home;
    case 'LAND':
      return LucideIcons.treeDeciduous;
    case 'TOWNHOUSE':
      return LucideIcons.building2;
    default:
      return LucideIcons.image;
  }
}

/// Network image for property with type-based placeholder on error (e.g. 404).
/// Use for property list and detail hero images.
class PropertyImage extends StatelessWidget {
  final String imageUrl;
  final String? propertyType;
  final double? width;
  final double? height;
  final BoxFit fit;

  const PropertyImage({
    Key? key,
    required this.imageUrl,
    this.propertyType,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      progressIndicatorBuilder: (context, url, downloadProgress) =>
          _PlaceholderBox(
        icon: _placeholderIconForType(propertyType),
        width: width,
        height: height,
        showLoading: true,
        progress: downloadProgress.progress,
      ),
      errorWidget: (context, url, error) => _PlaceholderBox(
        icon: _placeholderIconForType(propertyType),
        width: width,
        height: height,
      ),
    );
  }
}

class _PlaceholderBox extends StatelessWidget {
  final IconData icon;
  final double? width;
  final double? height;
  final bool showLoading;
  final double? progress;

  const _PlaceholderBox({
    required this.icon,
    this.width,
    this.height,
    this.showLoading = false,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Center(
        child: showLoading
            ? SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 2,
                  color: AppTheme.primaryColor,
                ),
              )
            : Icon(
                icon,
                size: 48,
                color: AppTheme.textSecondary,
              ),
      ),
    );
  }
}

/// Agent/avatar image with person placeholder on error.
class AgentAvatarImage extends StatelessWidget {
  final String imageUrl;
  final double size;

  const AgentAvatarImage({
    Key? key,
    required this.imageUrl,
    this.size = 56,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border.all(color: AppTheme.borderColor),
        shape: BoxShape.circle,
      ),
      child: Icon(
        LucideIcons.user,
        size: size * 0.5,
        color: AppTheme.textSecondary,
      ),
    );

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, url) => placeholder,
        errorWidget: (context, url, error) => placeholder,
      ),
    );
  }
}
