/// Model for a sponsored organization (splash, hero, partners).
class SponsoredOrganizationModel {
  final String id;
  final String name;
  final String? logoUrl;
  final String? videoUrl;
  final String? splashImageUrl;
  final String? address;
  final String? city;
  final String? country;
  final String sponsorshipType;
  final num? basePrice;

  const SponsoredOrganizationModel({
    required this.id,
    required this.name,
    this.logoUrl,
    this.videoUrl,
    this.splashImageUrl,
    this.address,
    this.city,
    this.country,
    this.sponsorshipType = '',
    this.basePrice,
  });

  factory SponsoredOrganizationModel.fromJson(Map<String, dynamic> json) {
    return SponsoredOrganizationModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      logoUrl: json['logoUrl']?.toString(),
      videoUrl: json['videoUrl']?.toString(),
      splashImageUrl: json['splashImageUrl']?.toString(),
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      country: json['country']?.toString(),
      sponsorshipType: json['sponsorshipType']?.toString() ?? '',
      basePrice: json['basePrice'] is num ? json['basePrice'] as num : null,
    );
  }

  bool get isExclusive =>
      sponsorshipType.toUpperCase() == 'EXCLUSIVE';
}
