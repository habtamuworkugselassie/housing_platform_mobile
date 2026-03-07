import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sponsored_organization_model.dart';
import 'auth_provider.dart';

/// Exclusive-only sponsor slides for splash screen.
final exclusiveSponsorSlidesProvider = FutureProvider<List<SponsoredOrganizationModel>>((ref) async {
  final service = ref.watch(sponsorshipServiceProvider);
  return service.getExclusiveOrganizations();
});

/// Premium sponsor slides for hero carousel: EXCLUSIVE and PREMIUM only,
/// sorted with EXCLUSIVE first, then by basePrice descending.
final premiumSponsorSlidesProvider = FutureProvider<List<SponsoredOrganizationModel>>((ref) async {
  final service = ref.watch(sponsorshipServiceProvider);
  final list = await service.getSponsoredOrganizations();
  const exclusive = 'EXCLUSIVE';
  const premium = 'PREMIUM';
  final filtered = list
      .where((o) {
        final t = (o.sponsorshipType).toUpperCase();
        return t == exclusive || t == premium;
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
