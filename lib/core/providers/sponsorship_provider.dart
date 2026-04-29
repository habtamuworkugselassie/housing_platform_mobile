import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sponsored_organization_model.dart';
import 'auth_provider.dart';

/// Exclusive-only sponsor slides for splash screen.
final exclusiveSponsorSlidesProvider = FutureProvider<List<SponsoredOrganizationModel>>((ref) async {
  final service = ref.watch(sponsorshipServiceProvider);
  return service.getExclusiveOrganizations();
});

/// Hero carousel: EXCLUSIVE and PLATINUM (legacy API may still return PREMIUM).
final premiumSponsorSlidesProvider = FutureProvider<List<SponsoredOrganizationModel>>((ref) async {
  final service = ref.watch(sponsorshipServiceProvider);
  final list = await service.getSponsoredOrganizations();
  const exclusive = 'EXCLUSIVE';
  const platinum = 'PLATINUM';
  const legacyPremium = 'PREMIUM';
  final filtered = list
      .where((o) {
        final t = (o.sponsorshipType).toUpperCase();
        return t == exclusive || t == platinum || t == legacyPremium;
      })
      .toList();
  filtered.sort((a, b) {
    final aEx = a.sponsorshipType.toUpperCase() == exclusive ? 0 : 1;
    final bEx = b.sponsorshipType.toUpperCase() == exclusive ? 0 : 1;
    if (aEx != bEx) return aEx.compareTo(bEx);
    final aPrice = a.basePrice ?? 0;
    final bPrice = b.basePrice ?? 0;
    return bPrice.compareTo(aPrice);
  });
  return filtered;
});
