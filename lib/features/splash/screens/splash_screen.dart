import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/media_helper.dart';
import '../../../core/models/sponsored_organization_model.dart';
import '../../../core/providers/sponsorship_provider.dart';
import '../../../core/theme/theme.dart';
import '../../marketplace/screens/root_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _dismissing = false;
  Timer? _autoTimer;
  static const _autoDismissDuration = Duration(seconds: 5);
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _autoTimer = Timer(_autoDismissDuration, _dismiss);
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (_dismissing) return;
    _dismissing = true;
    _autoTimer?.cancel();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RootScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncSlides = ref.watch(exclusiveSponsorSlidesProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Subtle gradient background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0a0a0a),
                    const Color(0xFF171717),
                    Colors.black,
                  ],
                ),
              ),
            ),
            asyncSlides.when(
              data: (slides) {
                if (slides.isEmpty) {
                  return _buildNoSponsorsContent();
                }
                if (slides.length == 1) {
                  return _buildSingleSponsor(slides.first);
                }
                return _buildCarousel(slides);
              },
              loading: () => _buildNoSponsorsContent(),
              error: (_, __) => _buildNoSponsorsContent(),
            ),
            // Page indicators when carousel
            if (asyncSlides.valueOrNull != null && asyncSlides.valueOrNull!.length > 1)
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    asyncSlides.valueOrNull!.length,
                    (i) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == i ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == i ? Colors.white : Colors.white.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            // App title at top
            Positioned(
              top: 24,
              left: 0,
              right: 0,
              child: Text(
                'Housing Platform',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            // Enter button at bottom
            Positioned(
              left: 24,
              right: 24,
              bottom: 32,
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: _dismissing ? null : _dismiss,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text('Enter'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSponsorsContent() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.home_work_outlined, size: 72, color: Colors.white.withValues(alpha: 0.3)),
          const SizedBox(height: 24),
          Text(
            'Welcome',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleSponsor(SponsoredOrganizationModel org) {
    final imageUrl = mediaUrl(org.splashImageUrl ?? org.logoUrl);
    final hasMedia = imageUrl != null && imageUrl.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.15),
                    blurRadius: 32,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: hasMedia
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholderContent(org),
                      )
                    : _placeholderContent(org),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              org.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (org.sponsorshipType.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  org.sponsorshipType.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCarousel(List<SponsoredOrganizationModel> slides) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) => setState(() => _currentPage = index),
      itemCount: slides.length,
      itemBuilder: (context, index) {
        return _buildSingleSponsor(slides[index]);
      },
    );
  }

  Widget _placeholderContent(SponsoredOrganizationModel org) {
    return Container(
      color: const Color(0xFF27272A),
      child: Center(
        child: org.logoUrl != null && org.logoUrl!.trim().isNotEmpty
            ? Image.network(
                mediaUrl(org.logoUrl)!,
                fit: BoxFit.contain,
                width: 120,
                height: 120,
                errorBuilder: (_, __, ___) => _initialCircle(org.name),
              )
            : _initialCircle(org.name),
      ),
    );
  }

  Widget _initialCircle(String name) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 40,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
