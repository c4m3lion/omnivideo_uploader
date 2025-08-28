# OmniVideo Uploader

A Flutter desktop application for uploading videos to multiple social media platforms with one click.

## Features

- **Multi-platform Authentication**: Currently supports TikTok with more platforms coming soon
- **Secure Token Management**: Uses PKCE flow for OAuth2 authentication
- **Environment-based Configuration**: Credentials stored securely in `.env` file
- **Clean Architecture**: Modular service design for easy platform integration
- **Cross-platform Desktop**: Works on Windows, macOS, and Linux

## Currently Supported Platforms

✅ **TikTok** - Full integration with Login Kit
🚧 **Instagram** - Coming soon
🚧 **YouTube** - Coming soon  
🚧 **Twitter/X** - Coming soon

## Setup Instructions

### 1. Environment Variables Setup

**Important**: Never commit your API credentials to version control!

1. **Copy the example environment file**:
   ```bash
   cp .env.example .env
   ```

2. **Edit `.env` file** with your actual credentials:
   ```env
   TIKTOK_CLIENT_KEY=your_actual_client_key_here
   TIKTOK_CLIENT_SECRET=your_actual_client_secret_here
   ```

3. **Verify `.env` is in `.gitignore`** (already done):
    - The `.env` file is automatically ignored by git
    - Only `.env.example` will be tracked in version control

### 2. TikTok Developer Setup

1. **Register your app** at [TikTok for Developers](https://developers.tiktok.com/)
2. Go to your developer dashboard → Manage Apps → Select your app
3. Get your **Client Key** and **Client Secret**
4. Configure **Redirect URI** in Login Kit settings:
    - Add: `http://localhost:3455/callback/`
    - Make sure to use the exact URL including the trailing slash

### 3. Run the App

```bash
flutter pub get
flutter run -d windows  # or -d macos, -d linux
```

## Project Structure

```
lib/
├── main.dart                          # App entry point + env loading
├── .env                              # Your credentials (gitignored)
├── .env.example                      # Template for credentials
├── screens/
│   ├── login_screen.dart             # Authentication screen
│   └── home_screen.dart              # Main dashboard
└── services/
    ├── auth/
    │   ├── auth_config.dart          # Environment-based config
    │   ├── auth_models.dart          # Data models
    │   └── auth_manager.dart         # Main auth controller
    └── platforms/
        ├── tiktok_auth_service.dart  # TikTok-specific logic
        ├── instagram_auth_service.dart  # Coming soon
        ├── youtube_auth_service.dart    # Coming soon
        └── twitter_auth_service.dart    # Coming soon
```

## Security Features

- **Environment Variables**: Credentials loaded from `.env` file (not committed to git)
- **PKCE Implementation**: Uses Proof Key for Code Exchange for secure desktop auth
- **CSRF Protection**: State parameter validation to prevent attacks
- **Token Storage**: Secure local storage with SharedPreferences
- **Auto Token Refresh**: Handles token expiration automatically

## Adding New Platforms

The architecture is designed for easy platform integration:

1. Add credentials to `.env` file
2. Create a new service in `services/platforms/`
3. Add the platform to `AuthProvider` enum in `auth_models.dart`
4. Add configuration getters in `auth_config.dart`
5. Implement the login method in `auth_manager.dart`
6. Update UI components in the screens

## Development Status

This is the foundation for a multi-platform video uploader. The TikTok integration is complete and ready for use. The
upload functionality and additional platform integrations will be added in future updates.

## Requirements

- Flutter 3.8.1 or higher
- Desktop platform (Windows, macOS, or Linux)
- Active TikTok Developer account

## First Time Setup

1. **Clone the repository**
2. **Copy environment template**: `cp .env.example .env`
3. **Add your TikTok credentials** to `.env` file
4. **Install dependencies**: `flutter pub get`
5. **Run the app**: `flutter run -d windows`

## Security Notes

- ✅ **`.env` file is in `.gitignore`** - Your credentials won't be committed
- ✅ **Use `.env.example`** - Template for other developers
- ✅ **Environment variables loaded at startup** - Secure credential management
- ⚠️ **Never commit `.env`** - Contains sensitive API keys

For questions or issues, please check the TikTok Login Kit documentation or create an issue in this repository.
