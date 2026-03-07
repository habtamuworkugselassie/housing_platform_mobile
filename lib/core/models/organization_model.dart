/// Media item for organization detail (from GET /organizations/:id).
class OrganizationMediaItem {
  final String? id;
  final String? url;
  final String? mediaKind;

  const OrganizationMediaItem({this.id, this.url, this.mediaKind});

  factory OrganizationMediaItem.fromJson(Map<String, dynamic> json) {
    return OrganizationMediaItem(
      id: json['id']?.toString(),
      url: json['url']?.toString(),
      mediaKind: json['mediaKind']?.toString(),
    );
  }

  bool get isVideo => (mediaKind ?? '').toUpperCase().contains('VIDEO');
}

/// Model for marketplace organization listing and detail (GET /organizations/marketplace, GET /organizations/:id).
class OrganizationModel {
  final String id;
  final String name;
  final String? type;
  final String? status;
  final String? address;
  final String? city;
  final String? country;
  final String? email;
  final String? website;
  final String? description;
  final String? logoUrl;
  final bool verified;
  final String? verificationLevel;
  final List<OrganizationPhoneDto>? phoneNumbers;
  final List<OrganizationMediaItem>? media;
  final String? registrationNumber;
  final String? createdAt;

  const OrganizationModel({
    required this.id,
    required this.name,
    this.type,
    this.status,
    this.address,
    this.city,
    this.country,
    this.email,
    this.website,
    this.description,
    this.logoUrl,
    this.verified = false,
    this.verificationLevel,
    this.phoneNumbers,
    this.media,
    this.registrationNumber,
    this.createdAt,
  });

  factory OrganizationModel.fromJson(Map<String, dynamic> json) {
    List<OrganizationPhoneDto>? phones;
    if (json['phoneNumbers'] is List) {
      phones = (json['phoneNumbers'] as List)
          .map((e) => OrganizationPhoneDto.fromJson(
              e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    List<OrganizationMediaItem>? mediaList;
    if (json['media'] is List) {
      mediaList = (json['media'] as List)
          .map((e) => OrganizationMediaItem.fromJson(
              e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    return OrganizationModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString(),
      status: json['status']?.toString(),
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      country: json['country']?.toString(),
      email: json['email']?.toString(),
      website: json['website']?.toString(),
      description: json['description']?.toString(),
      logoUrl: json['logoUrl']?.toString(),
      verified: json['verified'] == true,
      verificationLevel: json['verificationLevel']?.toString(),
      phoneNumbers: phones,
      media: mediaList,
      registrationNumber: json['registrationNumber']?.toString(),
      createdAt: json['createdAt']?.toString(),
    );
  }

  String get displayLocation {
    final parts = [address, city, country].where((e) => e != null && e.toString().trim().isNotEmpty).toList();
    return parts.join(', ');
  }
}

class OrganizationPhoneDto {
  final String? countryCode;
  final String? number;

  const OrganizationPhoneDto({this.countryCode, this.number});

  factory OrganizationPhoneDto.fromJson(Map<String, dynamic> json) {
    return OrganizationPhoneDto(
      countryCode: json['countryCode']?.toString(),
      number: json['number']?.toString(),
    );
  }

  String get display => [countryCode, number].where((e) => e != null && e.toString().trim().isNotEmpty).join(' ').trim();
}
