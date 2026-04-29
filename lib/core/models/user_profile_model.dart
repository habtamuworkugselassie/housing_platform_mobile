/// Response from GET /api/v1/users/me (matches backend UserResponse).
class UserProfile {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String? status; // ACTIVE, INACTIVE, etc.
  final bool emailVerified;
  final bool phoneVerified;
  final List<String> roles;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? organizationId;
  final bool enabled;
  final String? profileImageUrl;

  const UserProfile({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.status,
    this.emailVerified = false,
    this.phoneVerified = false,
    this.roles = const [],
    this.createdAt,
    this.updatedAt,
    this.organizationId,
    this.enabled = true,
    this.profileImageUrl,
  });

  String get fullName => '$firstName $lastName'.trim();

  bool get isBuyer => roles.any((r) => r.toUpperCase() == 'BUYER');

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final rolesRaw = json['roles'];
    List<String> rolesList = const [];
    if (rolesRaw is List) {
      rolesList = rolesRaw.map((e) => e.toString().toUpperCase()).toList();
    } else if (rolesRaw is String) {
      rolesList = [rolesRaw.toUpperCase()];
    }
    return UserProfile(
      id: json['id']?.toString() ?? '',
      email: json['email'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      status: json['status'] as String?,
      emailVerified: json['emailVerified'] as bool? ?? false,
      phoneVerified: json['phoneVerified'] as bool? ?? false,
      roles: rolesList,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
      organizationId: json['organizationId']?.toString(),
      enabled: json['enabled'] as bool? ?? true,
      profileImageUrl: json['profileImageUrl'] as String?,
    );
  }
}

/// Request body for PUT /api/v1/users/me (matches backend UserUpdateRequest).
class UserUpdateRequest {
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phoneNumber;

  const UserUpdateRequest({
    this.firstName,
    this.lastName,
    this.email,
    this.phoneNumber,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (firstName != null) map['firstName'] = firstName;
    if (lastName != null) map['lastName'] = lastName;
    if (email != null) map['email'] = email;
    if (phoneNumber != null) map['phoneNumber'] = phoneNumber;
    return map;
  }
}
