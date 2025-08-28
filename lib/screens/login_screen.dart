import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth/auth_manager.dart';
import '../services/auth/auth_models.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OmniVideo Uploader'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<AuthManager>(
        builder: (context, authManager, child) {
          if (authManager.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.video_library,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 24),
                Text(
                  'Welcome to OmniVideo Uploader',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Connect your social media accounts to start uploading videos with just one click',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                _buildPlatformButton(
                  context: context,
                  authManager: authManager,
                  platform: AuthProvider.tiktok,
                  label: 'Continue with TikTok',
                  icon: Icons.music_note,
                  color: Colors.black,
                  onPressed: () =>
                      _handleLogin(context, authManager, AuthProvider.tiktok),
                ),
                const SizedBox(height: 16),
                _buildPlatformButton(
                  context: context,
                  authManager: authManager,
                  platform: AuthProvider.instagram,
                  label: 'Continue with Instagram',
                  icon: Icons.camera_alt,
                  color: const Color(0xFFE4405F),
                  onPressed: () => _handleLogin(
                    context,
                    authManager,
                    AuthProvider.instagram,
                  ),
                  enabled: false, // Not implemented yet
                ),
                const SizedBox(height: 16),
                _buildPlatformButton(
                  context: context,
                  authManager: authManager,
                  platform: AuthProvider.youtube,
                  label: 'Continue with YouTube',
                  icon: Icons.play_circle_fill,
                  color: const Color(0xFFFF0000),
                  onPressed: () =>
                      _handleLogin(context, authManager, AuthProvider.youtube),
                  enabled: false, // Not implemented yet
                ),
                const SizedBox(height: 16),
                _buildPlatformButton(
                  context: context,
                  authManager: authManager,
                  platform: AuthProvider.twitter,
                  label: 'Continue with X (Twitter)',
                  icon: Icons.alternate_email,
                  color: const Color(0xFF1DA1F2),
                  onPressed: () =>
                      _handleLogin(context, authManager, AuthProvider.twitter),
                  enabled: false, // Not implemented yet
                ),
                const SizedBox(height: 32),
                Text(
                  'More platforms coming soon!',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlatformButton({
    required BuildContext context,
    required AuthManager authManager,
    required AuthProvider platform,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    bool enabled = true,
  }) {
    return ElevatedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, color: enabled ? Colors.white : Colors.grey),
      label: Text(
        label,
        style: TextStyle(
          color: enabled ? Colors.white : Colors.grey,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: enabled ? color : Colors.grey[300],
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _handleLogin(
    BuildContext context,
    AuthManager authManager,
    AuthProvider platform,
  ) async {
    AuthenticationResult result;

    switch (platform) {
      case AuthProvider.tiktok:
        result = await authManager.loginWithTikTok();
        break;
      case AuthProvider.instagram:
        result = await authManager.loginWithInstagram();
        break;
      case AuthProvider.youtube:
        result = await authManager.loginWithYouTube();
        break;
      case AuthProvider.twitter:
        result = await authManager.loginWithTwitter();
        break;
    }

    if (!context.mounted) return;

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Login failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
    // Success is handled by the AuthManager state change
  }
}
