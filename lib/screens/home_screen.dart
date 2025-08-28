import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth/auth_manager.dart';
import '../services/auth/auth_models.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OmniVideo Uploader'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Consumer<AuthManager>(
            builder: (context, authManager, child) {
              return PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'logout') {
                    _handleLogout(context, authManager);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout),
                        SizedBox(width: 8),
                        Text('Logout'),
                      ],
                    ),
                  ),
                ],
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundImage: authManager.currentUser?.avatarUrl != null
                        ? NetworkImage(authManager.currentUser!.avatarUrl!)
                        : null,
                    child: authManager.currentUser?.avatarUrl == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<AuthManager>(
        builder: (context, authManager, child) {
          if (authManager.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = authManager.currentUser!;
          final availablePlatforms = authManager.getAvailableUploadPlatforms();

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: user.avatarUrl != null
                              ? NetworkImage(user.avatarUrl!)
                              : null,
                          child: user.avatarUrl == null
                              ? const Icon(Icons.person, size: 30)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome, ${user.name}!',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Connected to ${_getPlatformDisplayName(user.provider)}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        _getPlatformIcon(user.provider),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Upload section
                Text(
                  'Upload Video',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.cloud_upload,
                          size: 64,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Select a video to upload',
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Upload to ${availablePlatforms.map(_getPlatformDisplayName).join(', ')}',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _selectVideo(context),
                          icon: const Icon(Icons.video_file),
                          label: const Text('Select Video'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Connected platforms section
                Text(
                  'Connected Platforms',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    children: [
                      _buildPlatformCard(
                        context,
                        user.provider,
                        isConnected: true,
                        user: user,
                      ),
                      const SizedBox(height: 8),
                      _buildPlatformCard(context, AuthProvider.instagram),
                      const SizedBox(height: 8),
                      _buildPlatformCard(context, AuthProvider.youtube),
                      const SizedBox(height: 8),
                      _buildPlatformCard(context, AuthProvider.twitter),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlatformCard(
    BuildContext context,
    AuthProvider platform, {
    bool isConnected = false,
    AuthUser? user,
  }) {
    return Card(
      child: ListTile(
        leading: _getPlatformIcon(platform),
        title: Text(_getPlatformDisplayName(platform)),
        subtitle: isConnected && user != null
            ? Text('Connected as ${user.name}')
            : const Text('Not connected'),
        trailing: isConnected
            ? const Icon(Icons.check_circle, color: Colors.green)
            : TextButton(
                onPressed: platform == AuthProvider.tiktok
                    ? null // Already connected
                    : () => _connectPlatform(context, platform),
                child: const Text('Connect'),
              ),
      ),
    );
  }

  Widget _getPlatformIcon(AuthProvider platform) {
    IconData iconData;
    Color color;

    switch (platform) {
      case AuthProvider.tiktok:
        iconData = Icons.music_note;
        color = Colors.black;
        break;
      case AuthProvider.instagram:
        iconData = Icons.camera_alt;
        color = const Color(0xFFE4405F);
        break;
      case AuthProvider.youtube:
        iconData = Icons.play_circle_fill;
        color = const Color(0xFFFF0000);
        break;
      case AuthProvider.twitter:
        iconData = Icons.alternate_email;
        color = const Color(0xFF1DA1F2);
        break;
    }

    return Icon(iconData, color: color, size: 32);
  }

  String _getPlatformDisplayName(AuthProvider platform) {
    switch (platform) {
      case AuthProvider.tiktok:
        return 'TikTok';
      case AuthProvider.instagram:
        return 'Instagram';
      case AuthProvider.youtube:
        return 'YouTube';
      case AuthProvider.twitter:
        return 'X (Twitter)';
    }
  }

  void _selectVideo(BuildContext context) {
    // TODO: Implement video selection and upload
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Video upload feature coming soon!')),
    );
  }

  void _connectPlatform(BuildContext context, AuthProvider platform) {
    // TODO: Implement connecting additional platforms
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${_getPlatformDisplayName(platform)} integration coming soon!',
        ),
      ),
    );
  }

  Future<void> _handleLogout(
    BuildContext context,
    AuthManager authManager,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await authManager.logout();
    }
  }
}
