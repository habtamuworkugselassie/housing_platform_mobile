import '../network/api_config.dart';

class PropertyMediaModel {
  final String id;
  final String type; // IMAGE, VIDEO
  final String? url;
  final String? caption;
  final int index;
  final bool isPrimary;

  PropertyMediaModel({
    required this.id,
    required this.type,
    this.url,
    this.caption,
    required this.index,
    required this.isPrimary,
  });

  factory PropertyMediaModel.fromJson(Map<String, dynamic> json) {
    return PropertyMediaModel(
      id: json['id']?.toString() ?? '',
      type: json['type'] as String? ?? 'IMAGE',
      url: json['url'] as String?,
      caption: json['caption'] as String?,
      index: (json['index'] as num?)?.toInt() ?? 0,
      isPrimary: json['isPrimary'] as bool? ?? false,
    );
  }
}

class AgentModel {
  final String name;
  final String organization;
  final String imageUrl;
  final String phone;

  // Since Backend PropertyResponse exposes realEstateCompanyName and agent details flat, we create a nested model mapped here
  // We'll hydrate this from the flat PropertyResponse fields
  const AgentModel({
    required this.name,
    required this.organization,
    required this.imageUrl,
    required this.phone,
  });
}

class PropertyModel {
  final String id;
  final String title;
  final String description;
  final String type; // RESIDENTIAL, COMMERCIAL, etc
  final String status; // AVAILABLE, SOLD
  final double priceETB;
  final double priceUSD;
  final String address;
  final String city;
  final String state;
  final String country;
  final String zipCode;
  final double? latitude;
  final double? longitude;
  final int bedrooms;
  final int bathrooms;
  final double area;
  final bool isSponsored;
  final String? realEstateCompanyId;
  final String? realEstateCompanyName;
  final String? realEstateCompanyPhone;
  final bool realEstateCompanyVerified;
  /// Verification level from backend: NONE, HALF, FULL. HALF = e.g. docs submitted but numbers missing.
  final String? realEstateCompanyVerificationLevel;
  final List<PropertyMediaModel> images;
  
  // Custom composite properties
  final AgentModel agent;
  final bool isFeatured;

  PropertyModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.priceETB,
    required this.priceUSD,
    required this.address,
    required this.city,
    required this.state,
    required this.country,
    required this.zipCode,
    this.latitude,
    this.longitude,
    required this.bedrooms,
    required this.bathrooms,
    required this.area,
    required this.isSponsored,
    this.realEstateCompanyId,
    this.realEstateCompanyName,
    this.realEstateCompanyPhone,
    this.realEstateCompanyVerified = false,
    this.realEstateCompanyVerificationLevel,
    required this.images,
    required this.agent,
    this.isFeatured = false,
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    var imagesList = (json['images'] as List<dynamic>?)
            ?.map((e) => PropertyMediaModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final companyName = json['realEstateCompanyName'] as String? ?? 'Independent Agent';
    final companyPhone = json['realEstateCompanyPhone'] as String? ?? '+251 900 000000';
    // Mocks missing backend direct agent exposure using company info
    final agent = AgentModel(
        name: companyName, // Mocking agent as company until agent projection expands
        organization: companyName,
        phone: companyPhone,
        imageUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&q=80',
    );

    return PropertyModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? 'Untitled Property',
      description: json['description'] as String? ?? '',
      type: json['type'] as String? ?? 'RESIDENTIAL',
      status: json['status'] as String? ?? 'AVAILABLE',
      priceETB: (json['priceETB'] as num?)?.toDouble() ?? 0.0,
      priceUSD: (json['priceUSD'] as num?)?.toDouble() ?? 0.0,
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      country: json['country'] as String? ?? 'Ethiopia',
      zipCode: json['zipCode'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      bedrooms: (json['bedrooms'] as num?)?.toInt() ?? 0,
      bathrooms: (json['bathrooms'] as num?)?.toInt() ?? 0,
      area: (json['area'] as num?)?.toDouble() ?? 0.0,
      isSponsored: json['isSponsored'] as bool? ?? false,
      realEstateCompanyId: json['realEstateCompanyId']?.toString(),
      realEstateCompanyName: companyName,
      realEstateCompanyPhone: companyPhone,
      realEstateCompanyVerified: json['realEstateCompanyVerified'] as bool? ?? false,
      realEstateCompanyVerificationLevel: json['realEstateCompanyVerificationLevel'] as String?,
      images: imagesList,
      agent: agent,
      isFeatured: json['isSponsored'] as bool? ?? false, // using isSponsored for featured highlight
    );
  }

  // Display price getter
  double get price => priceETB > 0 ? priceETB : priceUSD;

  /// True if we should show a verification badge (FULL or HALF).
  bool get showVerificationBadge =>
      realEstateCompanyVerificationLevel == 'FULL' ||
      realEstateCompanyVerificationLevel == 'HALF' ||
      realEstateCompanyVerified;

  /// Label for badge: Verified (FULL) or Half verified (HALF).
  String? get verificationBadgeLabel {
    final level = realEstateCompanyVerificationLevel;
    if (level == 'FULL' || realEstateCompanyVerified) return 'Verified';
    if (level == 'HALF') return 'Half verified';
    return null;
  }
  
  // Display location
  String get location => '$city, $state $country'.trim().replaceAll(',  ', ', ');

  // Get primary image (uses same backend origin as API so release builds hit Droplet).
  String get imageUrl {
    if (images.isEmpty) {
      return 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&q=80';
    }
    final primary = images.firstWhere((img) => img.isPrimary, orElse: () => images.first);
    return '${ApiConfig.baseOrigin}/api/v1/properties/$id/images/${primary.id}/file';
  }
}
