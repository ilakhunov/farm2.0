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
    // Handle tokens safely
    String accessToken;
    if (json['access_token'] is String) {
      accessToken = json['access_token'] as String;
    } else if (json['access_token'] is List) {
      final list = json['access_token'] as List;
      accessToken = list.isEmpty ? '' : list.first.toString();
    } else {
      accessToken = json['access_token']?.toString() ?? '';
    }
    
    String refreshToken;
    if (json['refresh_token'] is String) {
      refreshToken = json['refresh_token'] as String;
    } else if (json['refresh_token'] is List) {
      final list = json['refresh_token'] as List;
      refreshToken = list.isEmpty ? '' : list.first.toString();
    } else {
      refreshToken = json['refresh_token']?.toString() ?? '';
    }
    
    // Handle integers safely
    int expiresIn;
    if (json['expires_in'] is int) {
      expiresIn = json['expires_in'] as int;
    } else if (json['expires_in'] is num) {
      expiresIn = (json['expires_in'] as num).toInt();
    } else {
      expiresIn = 3600; // default
    }
    
    int refreshExpiresIn;
    if (json['refresh_expires_in'] is int) {
      refreshExpiresIn = json['refresh_expires_in'] as int;
    } else if (json['refresh_expires_in'] is num) {
      refreshExpiresIn = (json['refresh_expires_in'] as num).toInt();
    } else {
      refreshExpiresIn = 86400; // default
    }
    
    return AuthTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresIn: expiresIn,
      refreshExpiresIn: refreshExpiresIn,
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
    // Handle ID safely
    String id;
    if (json['id'] is String) {
      id = json['id'] as String;
    } else {
      id = json['id']?.toString() ?? '';
    }
    
    // Handle phoneNumber safely
    String phoneNumber;
    if (json['phone_number'] is String) {
      phoneNumber = json['phone_number'] as String;
    } else if (json['phone_number'] is List) {
      final list = json['phone_number'] as List;
      phoneNumber = list.isEmpty ? '' : list.first.toString();
    } else {
      phoneNumber = json['phone_number']?.toString() ?? '';
    }
    
    // Handle role safely
    String role;
    if (json['role'] is String) {
      role = json['role'] as String;
    } else {
      role = json['role']?.toString() ?? 'shop';
    }
    
    // Handle optional String fields safely
    String? entityType;
    if (json['entity_type'] == null) {
      entityType = null;
    } else if (json['entity_type'] is String) {
      entityType = json['entity_type'] as String;
    } else if (json['entity_type'] is List) {
      final list = json['entity_type'] as List;
      entityType = list.isEmpty ? null : list.first.toString();
    } else {
      entityType = json['entity_type'].toString();
    }
    
    String? taxId;
    if (json['tax_id'] == null) {
      taxId = null;
    } else if (json['tax_id'] is String) {
      taxId = json['tax_id'] as String;
    } else if (json['tax_id'] is List) {
      final list = json['tax_id'] as List;
      taxId = list.isEmpty ? null : list.first.toString();
    } else {
      taxId = json['tax_id'].toString();
    }
    
    String? legalName;
    if (json['legal_name'] == null) {
      legalName = null;
    } else if (json['legal_name'] is String) {
      legalName = json['legal_name'] as String;
    } else if (json['legal_name'] is List) {
      final list = json['legal_name'] as List;
      legalName = list.isEmpty ? null : list.first.toString();
    } else {
      legalName = json['legal_name'].toString();
    }
    
    // Handle isVerified safely
    bool isVerified;
    if (json['is_verified'] is bool) {
      isVerified = json['is_verified'] as bool;
    } else {
      isVerified = false;
    }
    
    return AuthUser(
      id: id,
      phoneNumber: phoneNumber,
      role: role,
      entityType: entityType,
      taxId: taxId,
      legalName: legalName,
      isVerified: isVerified,
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
