import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../auth/auth_config.dart';
import '../auth/auth_models.dart';

class TikTokAuthService {
  static const String _characters =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';

  /// Generate a cryptographically secure random string for PKCE
  String _generateCodeVerifier() {
    final random = Random.secure();
    final length = 43 + random.nextInt(86); // 43-128 characters
    return List.generate(
      length,
      (i) => _characters[random.nextInt(_characters.length)],
    ).join();
  }

  /// Generate code challenge from code verifier using SHA256
  String _generateCodeChallenge(String codeVerifier) {
    final bytes = utf8.encode(codeVerifier);
    final digest = sha256.convert(bytes);
    // TikTok requires hex encoding, not base64
    return digest.toString();
  }

  /// Generate anti-forgery state token
  String _generateState() {
    final random = Random.secure();
    return List.generate(
      30,
      (i) => _characters[random.nextInt(_characters.length)],
    ).join();
  }

  /// Build the TikTok authorization URL
  String _buildAuthUrl({required String codeChallenge, required String state}) {
    final params = {
      'client_key': AuthConfig.tiktokClientKey,
      'scope': AuthConfig.tiktokScope,
      'response_type': 'code',
      'redirect_uri': AuthConfig.tiktokRedirectUri,
      'state': state,
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
    };

    final queryString = params.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');

    return '${AuthConfig.tiktokAuthUrl}?$queryString';
  }

  /// Exchange authorization code for access token
  Future<AuthToken?> _exchangeCodeForToken({
    required String code,
    required String codeVerifier,
  }) async {
    try {
      debugPrint('=== TOKEN EXCHANGE DEBUG ===');
      debugPrint('Code length: ${code.length}');
      debugPrint('Code Verifier length: ${codeVerifier.length}');
      debugPrint('Client Key: ${AuthConfig.tiktokClientKey}');
      debugPrint(
        'Client Secret length: ${AuthConfig.tiktokClientSecret.length}',
      );
      debugPrint('Redirect URI: ${AuthConfig.tiktokRedirectUri}');

      // Prepare body parameters exactly as TikTok expects
      final body = <String, String>{
        'client_key': AuthConfig.tiktokClientKey,
        'client_secret': AuthConfig.tiktokClientSecret,
        'code': code,
        'grant_type': 'authorization_code',
        'redirect_uri': AuthConfig.tiktokRedirectUri,
        'code_verifier': codeVerifier,
      };

      // Log each parameter for debugging
      body.forEach((key, value) {
        debugPrint('$key: ${key == 'client_secret' ? '[HIDDEN]' : value}');
      });

      final response = await http.post(
        Uri.parse(AuthConfig.tiktokTokenUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: body,
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response headers: ${response.headers}');
      debugPrint('Response body: ${response.body}');

      // Handle different response scenarios
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['error'] != null) {
          final errorMsg =
              '${jsonData['error']}: ${jsonData['error_description']}';
          debugPrint('TikTok API error: $errorMsg');

          // Provide more specific error context
          if (jsonData['error'] == 'invalid_request') {
            debugPrint('This usually means parameter validation failed.');
            debugPrint(
              'Check: 1) Client credentials 2) Redirect URI exact match 3) Code expiry',
            );
          }

          return null;
        }

        if (jsonData['data'] != null) {
          debugPrint('✅ Token exchange successful!');
          return AuthToken.fromJson(jsonData['data'], AuthProvider.tiktok);
        }
      } else {
        debugPrint('❌ HTTP Error ${response.statusCode}: ${response.body}');
      }

      return null;
    } catch (e, stackTrace) {
      debugPrint('❌ Exception in token exchange: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Get user information using access token
  Future<AuthUser?> _getUserInfo(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://open.tiktokapis.com/v2/user/info/?fields=open_id,union_id,avatar_url,display_name',
        ),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['data'] != null && jsonData['data']['user'] != null) {
          return AuthUser.fromJson(
            jsonData['data']['user'],
            AuthProvider.tiktok,
          );
        }
      }

      debugPrint('Failed to get user info: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('Error getting user info: $e');
      return null;
    }
  }

  /// Main login method for TikTok
  Future<AuthenticationResult> login() async {
    HttpServer? server;
    try {
      // Generate PKCE parameters
      final codeVerifier = _generateCodeVerifier();
      final codeChallenge = _generateCodeChallenge(codeVerifier);
      final state = _generateState();

      // Start local server to handle OAuth callback
      server = await HttpServer.bind('localhost', 3455);
      debugPrint('OAuth callback server started on http://localhost:3455');

      // Build authorization URL
      final authUrl = _buildAuthUrl(codeChallenge: codeChallenge, state: state);

      // Launch the authorization URL in the default browser
      final uri = Uri.parse(authUrl);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        return AuthenticationResult.failure(
          'Could not launch TikTok authorization URL',
        );
      }

      // Wait for the OAuth callback
      String? authCode;
      String? receivedState;
      String? error;

      await for (final request in server) {
        final uri = request.uri;

        // Handle the callback
        if (uri.path == '/callback/') {
          authCode = uri.queryParameters['code'];
          receivedState = uri.queryParameters['state'];
          error = uri.queryParameters['error'];

          // Send response to browser
          request.response
            ..statusCode = 200
            ..headers.set('content-type', 'text/html')
            ..write('''
              <!DOCTYPE html>
              <html>
                <head>
                  <title>TikTok Authentication</title>
                  <style>
                    body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
                    .success { color: #4CAF50; }
                    .error { color: #f44336; }
                  </style>
                </head>
                <body>
                  <h1>TikTok Authentication</h1>
                  ${error != null ? '<p class="error">Authentication failed: $error</p>' : '<p class="success">Authentication successful! You can close this window.</p>'}
                </body>
              </html>
            ''');
          await request.response.close();
          break;
        } else {
          // Handle other requests
          request.response
            ..statusCode = 404
            ..write('Not found');
          await request.response.close();
        }
      }

      // Check for errors
      if (error != null) {
        return AuthenticationResult.failure(
          'TikTok authentication error: $error',
        );
      }

      // Verify state to prevent CSRF attacks
      if (receivedState != state) {
        return AuthenticationResult.failure(
          'Invalid state parameter. Possible CSRF attack.',
        );
      }

      if (authCode == null) {
        return AuthenticationResult.failure('No authorization code received');
      }

      // Exchange code for access token
      final token = await _exchangeCodeForToken(
        code: authCode,
        codeVerifier: codeVerifier,
      );

      if (token == null) {
        return AuthenticationResult.failure(
          'Failed to exchange authorization code for access token',
        );
      }

      // Get user information
      final user = await _getUserInfo(token.accessToken);

      if (user == null) {
        return AuthenticationResult.failure(
          'Failed to retrieve user information',
        );
      }

      return AuthenticationResult.success(user, token);
    } catch (e) {
      debugPrint('TikTok login error: $e');
      return AuthenticationResult.failure('An unexpected error occurred: $e');
    } finally {
      // Clean up the server
      await server?.close();
    }
  }

  /// Refresh access token
  Future<AuthToken?> refreshToken(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse(AuthConfig.tiktokTokenUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_key': AuthConfig.tiktokClientKey,
          'client_secret': AuthConfig.tiktokClientSecret,
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['data'] != null) {
          return AuthToken.fromJson(jsonData['data'], AuthProvider.tiktok);
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error refreshing token: $e');
      return null;
    }
  }
}
