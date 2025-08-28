import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_models.dart';
import '../platforms/tiktok_auth_service.dart';

class AuthManager extends ChangeNotifier {
  static const String _userKey = 'auth_user';
  static const String _tokenKey = 'auth_token';

  AuthUser? _currentUser;
  AuthToken? _currentToken;
  bool _isLoading = false;

  AuthUser? get currentUser => _currentUser;

  AuthToken? get currentToken => _currentToken;

  bool get isLoading => _isLoading;

  bool get isAuthenticated =>
      _currentUser != null && _currentToken?.isValid == true;

  // Platform-specific services
  final TikTokAuthService _tiktokService = TikTokAuthService();

  /// Initialize and load saved authentication state
  Future<void> initialize() async {
    _setLoading(true);
    try {
      await _loadSavedAuth();
    } finally {
      _setLoading(false);
    }
  }

  /// Login with TikTok
  Future<AuthenticationResult> loginWithTikTok() async {
    _setLoading(true);
    try {
      final result = await _tiktokService.login();

      if (result.success && result.user != null && result.token != null) {
        await _saveAuthData(result.user!, result.token!);
        _currentUser = result.user;
        _currentToken = result.token;
        notifyListeners();
      }

      return result;
    } finally {
      _setLoading(false);
    }
  }

  /// Placeholder methods for future platform integrations
  Future<AuthenticationResult> loginWithInstagram() async {
    // TODO: Implement Instagram login
    return AuthenticationResult.failure('Instagram login not implemented yet');
  }

  Future<AuthenticationResult> loginWithYouTube() async {
    // TODO: Implement YouTube login
    return AuthenticationResult.failure('YouTube login not implemented yet');
  }

  Future<AuthenticationResult> loginWithTwitter() async {
    // TODO: Implement Twitter login
    return AuthenticationResult.failure('Twitter login not implemented yet');
  }

  /// Logout and clear stored data
  Future<void> logout() async {
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      await prefs.remove(_tokenKey);

      _currentUser = null;
      _currentToken = null;
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh current token if needed
  Future<bool> refreshTokenIfNeeded() async {
    if (_currentToken == null || !_currentToken!.isExpired) {
      return true; // No refresh needed
    }

    if (_currentToken!.refreshToken == null) {
      await logout(); // Can't refresh, logout
      return false;
    }

    try {
      AuthToken? newToken;

      switch (_currentToken!.provider) {
        case AuthProvider.tiktok:
          newToken = await _tiktokService.refreshToken(
            _currentToken!.refreshToken!,
          );
          break;
        default:
          debugPrint(
            'Token refresh not implemented for ${_currentToken!.provider}',
          );
          return false;
      }

      if (newToken != null) {
        _currentToken = newToken;
        await _saveAuthData(_currentUser!, newToken);
        notifyListeners();
        return true;
      } else {
        await logout(); // Refresh failed, logout
        return false;
      }
    } catch (e) {
      debugPrint('Error refreshing token: $e');
      await logout();
      return false;
    }
  }

  /// Load saved authentication data
  Future<void> _loadSavedAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      final tokenJson = prefs.getString(_tokenKey);

      if (userJson != null && tokenJson != null) {
        final userData = json.decode(userJson) as Map<String, dynamic>;
        final tokenData = json.decode(tokenJson) as Map<String, dynamic>;

        final providerName = userData['provider'] as String;
        final provider = AuthProvider.values.firstWhere(
          (p) => p.name == providerName,
          orElse: () => AuthProvider.tiktok,
        );

        _currentUser = AuthUser.fromJson(userData, provider);
        _currentToken = AuthToken.fromJson(tokenData, provider);

        // Check if token needs refresh
        if (_currentToken!.isExpired) {
          await refreshTokenIfNeeded();
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading saved auth: $e');
      // Clear corrupted data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      await prefs.remove(_tokenKey);
    }
  }

  /// Save authentication data to local storage
  Future<void> _saveAuthData(AuthUser user, AuthToken token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, json.encode(user.toJson()));
      await prefs.setString(_tokenKey, json.encode(token.toJson()));
    } catch (e) {
      debugPrint('Error saving auth data: $e');
    }
  }

  /// Set loading state and notify listeners
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// Get platform-specific upload capabilities
  List<AuthProvider> getAvailableUploadPlatforms() {
    if (!isAuthenticated) return [];

    // For now, return the current authenticated platform
    // In the future, this could return multiple platforms if user is authenticated with multiple
    return [_currentUser!.provider];
  }

  /// Check if specific platform is authenticated
  bool isAuthenticatedWith(AuthProvider provider) {
    return isAuthenticated && _currentUser?.provider == provider;
  }
}
