import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/models/sponsored_organization_model.dart';
import '../../../core/network/media_helper.dart';
import '../../../core/providers/sponsorship_provider.dart';
import '../../../core/theme/theme.dart';

/// Hero carousel showing media (image/video) from Premium and Exclusive sponsors.
/// Auto-advances every 5.5s and supports manual swipe.
class SponsorCarouselWidget extends ConsumerStatefulWidget {
  /// Height of the carousel. Default 220 for mobile.
  final double height;

  /// Auto-advance interval in seconds. 0 disables autoplay.
  final int autoplaySeconds;

  const SponsorCarouselWidget({
    Key? key,
    this.height = 220,
    this.autoplaySeconds = 5,
  }) : super(key: key);

  @override
  ConsumerState<SponsorCarouselWidget> createState() => _SponsorCarouselWidgetState();
}

class _SponsorCarouselWidgetState extends ConsumerState<SponsorCarouselWidget> {
  late PageController _pageController;
  Timer? _autoplayTimer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _autoplayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoplay(int itemCount) {
    _autoplayTimer?.cancel();
    if (widget.autoplaySeconds <= 0 || itemCount <= 1) return;
    _autoplayTimer = Timer.periodic(Duration(seconds: widget.autoplaySeconds), (_) {
      if (!mounted) return;
      final next = (_currentIndex + 1) % itemCount;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncSlides = ref.watch(premiumSponsorSlidesProvider);

    return asyncSlides.when(
      data: (slides) {
        if (slides.isEmpty) return const SizedBox.shrink();
        if (_autoplayTimer == null || !_autoplayTimer!.isActive) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoplay(slides.length));
        }
        return SizedBox(
          height: widget.height,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemCount: slides.length,
                itemBuilder: (context, index) {
                  return _SlidePage(
                    sponsor: slides[index],
                    isActive: index == _currentIndex,
                  );
                },
              ),
              // Gradient overlays for readability
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: 60,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 100,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                    ),
                  ),
                ),
              ),
              // Page indicators
              Positioned(
                left: 0,
                right: 0,
                bottom: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    slides.length,
                    (i) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _currentIndex == i ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentIndex == i
                            ? AppTheme.primaryColor
                            : Colors.white.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => SizedBox(
        height: widget.height,
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _SlidePage extends StatefulWidget {
  final SponsoredOrganizationModel sponsor;
  final bool isActive;

  const _SlidePage({required this.sponsor, required this.isActive});

  @override
  State<_SlidePage> createState() => _SlidePageState();
}

class _SlidePageState extends State<_SlidePage> {
  @override
  Widget build(BuildContext context) {
    final sponsor = widget.sponsor;
    final imageUrl = mediaUrl(sponsor.splashImageUrl ?? sponsor.logoUrl);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Media: prefer image for performance; video can be added with video_player for current slide only
        if (imageUrl != null && imageUrl.isNotEmpty)
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _placeholder(),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _placeholder();
            },
          )
        else
          _placeholder(),
        // Content overlay
        Positioned(
          left: 16,
          right: 16,
          bottom: 40,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (sponsor.logoUrl != null && sponsor.logoUrl!.trim().isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    mediaUrl(sponsor.logoUrl)!,
                    height: 48,
                    width: 48,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => _initialCircle(sponsor.name),
                  ),
                )
              else
                _initialCircle(sponsor.name),
              const SizedBox(height: 8),
              Text(
                sponsor.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (sponsor.address != null || sponsor.city != null) ...[
                const SizedBox(height: 4),
                Text(
                  [sponsor.address, sponsor.city].where((e) => e != null && e.toString().trim().isNotEmpty).join(', '),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _tierColor(sponsor.sponsorshipType).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _tierLabel(sponsor.sponsorshipType),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFF27272A),
      child: const Center(
        child: Icon(LucideIcons.building2, size: 48, color: Colors.white24),
      ),
    );
  }

  Widget _initialCircle(String name) {
    return Container(
      height: 48,
      width: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _tierColor(String? type) {
    if (type == null) return AppTheme.primaryColor;
    final t = type.toUpperCase();
    if (t.contains('EXCLUSIVE')) return const Color(0xFFFACC15);
    if (t.contains('PREMIUM')) return const Color(0xFFF59E0B);
    return AppTheme.primaryColor;
  }

  String _tierLabel(String? type) {
    if (type == null) return 'Sponsor';
    final t = type.toUpperCase();
    if (t.contains('EXCLUSIVE')) return 'Exclusive';
    if (t.contains('PREMIUM')) return 'Premium';
    return type;
  }
}
