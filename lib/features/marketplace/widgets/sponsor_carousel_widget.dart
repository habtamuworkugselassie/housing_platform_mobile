import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/models/sponsored_organization_model.dart';
import '../../../core/network/media_helper.dart';
import '../../../core/providers/sponsorship_provider.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/brand.dart';
import 'dart:ui' show ImageFilter;

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
  ConsumerState<SponsorCarouselWidget> createState() =>
      _SponsorCarouselWidgetState();
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
    _autoplayTimer =
        Timer.periodic(Duration(seconds: widget.autoplaySeconds), (_) {
      if (!mounted) return;
      final next = (_currentIndex + 1) % itemCount;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  void _preloadSlideImages(
      BuildContext context, List<SponsoredOrganizationModel> slides) {
    const maxPreload = 5;
    for (var i = 0; i < slides.length && i < maxPreload; i++) {
      final url = mediaUrl(slides[i].splashImageUrl ?? slides[i].logoUrl);
      if (url != null && url.isNotEmpty) {
        precacheImage(CachedNetworkImageProvider(url), context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncSlides = ref.watch(premiumSponsorSlidesProvider);

    return asyncSlides.when(
      data: (slides) {
        if (slides.isEmpty) return const SizedBox.shrink();
        if (_autoplayTimer == null || !_autoplayTimer!.isActive) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _startAutoplay(slides.length));
        }
        // Preload carousel images so they appear faster when swiping
        _preloadSlideImages(context, slides);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            height: widget.height,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppTheme.brandDeep,
              borderRadius: BorderRadius.circular(AppTheme.radiusPanel),
              boxShadow: AppTheme.panelShadow,
            ),
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
                // Readability scrim at the foot, violet rather than black so the band stays on brand
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 120,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            AppTheme.brandDeep.withValues(alpha: 0.85),
                            Colors.transparent
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Eyebrow pill, top left
                const Positioned(
                  left: 14,
                  top: 14,
                  child: EyebrowPill('Featured partner',
                      onDark: true, solid: true),
                ),
                // Page indicators: gold active pill, like the web dots
                if (slides.length > 1)
                  Positioned(
                    right: 14,
                    top: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppTheme.brandDeep.withValues(alpha: 0.78),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          slides.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 2.5),
                            width: _currentIndex == i ? 18 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _currentIndex == i
                                  ? AppTheme.goldBright
                                  : Colors.white.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: AppTheme.violet50,
            borderRadius: BorderRadius.circular(AppTheme.radiusPanel),
          ),
          child: const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor)),
        ),
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
    final splashUrl = mediaUrl(sponsor.splashImageUrl ?? sponsor.logoUrl);
    final logoUrlResolved = mediaUrl(sponsor.logoUrl);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Media: one download, drawn twice. The blurred, violet-tinted echo fills the sides
        // that BoxFit.contain leaves empty, so the band reads as part of the violet app
        // rather than a grey strip; the sharp image sits on top, uncropped.
        if (splashUrl != null && splashUrl.isNotEmpty)
          CachedNetworkImage(
            imageUrl: splashUrl,
            memCacheWidth: 800,
            memCacheHeight: 450,
            maxWidthDiskCache: 800,
            maxHeightDiskCache: 450,
            fadeInDuration: const Duration(milliseconds: 200),
            placeholder: (_, __) => _placeholder(),
            errorWidget: (_, __, ___) => _placeholder(),
            imageBuilder: (context, provider) => Stack(
              fit: StackFit.expand,
              children: [
                ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Image(image: provider, fit: BoxFit.cover),
                ),
                Container(color: AppTheme.brandDeep.withValues(alpha: 0.55)),
                Image(image: provider, fit: BoxFit.contain),
              ],
            ),
          )
        else
          _placeholder(),
        // Frosted sponsor card, bottom left (web: the lower-third card on the sponsor band)
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.brandDeep.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(18),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.16)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child:
                          logoUrlResolved != null && logoUrlResolved.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: logoUrlResolved,
                                  fit: BoxFit.contain,
                                  memCacheWidth: 96,
                                  memCacheHeight: 96,
                                  placeholder: (_, __) =>
                                      _initialCircle(sponsor.name),
                                  errorWidget: (_, __, ___) =>
                                      _initialCircle(sponsor.name),
                                )
                              : _initialCircle(sponsor.name),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            sponsor.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (sponsor.address != null ||
                              sponsor.city != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              [sponsor.address, sponsor.city]
                                  .where((e) =>
                                      e != null &&
                                      e.toString().trim().isNotEmpty)
                                  .join(', '),
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 11.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    TierBadge(_tierLabel(sponsor.sponsorshipType),
                        gold: _isGoldTier(sponsor.sponsorshipType)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppTheme.brandDeep,
      child: const Center(
        child: Icon(LucideIcons.building2, size: 48, color: Colors.white24),
      ),
    );
  }

  bool _isGoldTier(String? type) {
    final t = (type ?? '').toUpperCase();
    return t.contains('EXCLUSIVE') ||
        t.contains('PLATINUM') ||
        t.contains('PREMIUM');
  }

  Widget _initialCircle(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
        style: const TextStyle(
          color: AppTheme.brandPanel,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  String _tierLabel(String? type) {
    if (type == null) return 'Sponsor';
    final t = type.toUpperCase();
    if (t.contains('EXCLUSIVE')) return 'Exclusive';
    if (t.contains('PLATINUM')) return 'Platinum';
    if (t.contains('PREMIUM')) return 'Premium';
    return type;
  }
}
