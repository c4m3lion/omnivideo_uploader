enum AuthProvider { tiktok, instagram, youtube, twitter }

class AuthUser {
  final String id;
  final String name;
  final String? email;
  final String? avatarUrl;
  final AuthProvider provider;
  final Map<String, dynamic> additionalData;

  AuthUser({
    required this.id,
    required this.name,
    this.email,
    this.avatarUrl,
    required this.provider,
    this.additionalData = const {},
  });

  factory AuthUser.fromJson(Map<String, dynamic> json, AuthProvider provider) {
    return AuthUser(
      id: json['id'] ?? json['open_id'] ?? '',
      name: json['name'] ?? json['display_name'] ?? json['username'] ?? '',
      email: json['email'],
      avatarUrl: json['avatar_url'] ?? json['avatar_url_100'],
      provider: provider,
      additionalData: json,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'provider': provider.name,
      'additionalData': additionalData,
    };
  }
}

class AuthToken {
  final String accessToken;
  final String? refreshToken;
  final DateTime expiresAt;
  final AuthProvider provider;
  final List<String> scopes;

  AuthToken({
    required this.accessToken,
    this.refreshToken,
    required this.expiresAt,
    required this.provider,
    this.scopes = const [],
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool get isValid => !isExpired && accessToken.isNotEmpty;

  factory AuthToken.fromJson(Map<String, dynamic> json, AuthProvider provider) {
    final expiresIn = json['expires_in'] as int? ?? 3600;
    return AuthToken(
      accessToken: json['access_token'] ?? '',
      refreshToken: json['refresh_token'],
      expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
      provider: provider,
      scopes: (json['scope'] as String?)?.split(',') ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_at': expiresAt.toIso8601String(),
      'provider': provider.name,
      'scopes': scopes,
    };
  }
}

class AuthenticationResult {
  final bool success;
  final AuthUser? user;
  final AuthToken? token;
  final String? error;

  AuthenticationResult({
    required this.success,
    this.user,
    this.token,
    this.error,
  });

  factory AuthenticationResult.success(AuthUser user, AuthToken token) {
    return AuthenticationResult(success: true, user: user, token: token);
  }

  factory AuthenticationResult.failure(String error) {
    return AuthenticationResult(success: false, error: error);
  }
}
