class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.refreshExpiresIn,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final int refreshExpiresIn;

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresIn: json['expires_in'] as int,
      refreshExpiresIn: json['refresh_expires_in'] as int,
    );
  }
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.phoneNumber,
    required this.role,
    this.entityType,
    this.taxId,
    this.legalName,
    this.isVerified = false,
  });

  final String id;
  final String phoneNumber;
  final String role;
  final String? entityType;
  final String? taxId;
  final String? legalName;
  final bool isVerified;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      phoneNumber: json['phone_number'] as String,
      role: json['role'] as String,
      entityType: json['entity_type'] as String?,
      taxId: json['tax_id'] as String?,
      legalName: json['legal_name'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
    );
  }
}

class AuthResponse {
  const AuthResponse({required this.tokens, required this.user});

  final AuthTokens tokens;
  final AuthUser user;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      tokens: AuthTokens.fromJson(json['token'] as Map<String, dynamic>),
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
