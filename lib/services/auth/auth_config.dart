import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthConfig {
  // TikTok Configuration - loaded from environment variables
  static String get tiktokClientKey => dotenv.env['TIKTOK_CLIENT_KEY'] ?? '';

  static String get tiktokClientSecret =>
      dotenv.env['TIKTOK_CLIENT_SECRET'] ?? '';
  static const String tiktokRedirectUri = 'http://localhost:3455/callback/';
  static const String tiktokScope = 'user.info.basic';
  static const String tiktokAuthUrl =
      'https://www.tiktok.com/v2/auth/authorize/';
  static const String tiktokTokenUrl =
      'https://open.tiktokapis.com/v2/oauth/token/';

  // Add other platform configs here in the future
  // Instagram, YouTube, Twitter, etc.
  static String get instagramClientId =>
      dotenv.env['INSTAGRAM_CLIENT_ID'] ?? '';

  static String get instagramClientSecret =>
      dotenv.env['INSTAGRAM_CLIENT_SECRET'] ?? '';

  static String get youtubeClientId => dotenv.env['YOUTUBE_CLIENT_ID'] ?? '';

  static String get youtubeClientSecret =>
      dotenv.env['YOUTUBE_CLIENT_SECRET'] ?? '';

  static String get twitterClientId => dotenv.env['TWITTER_CLIENT_ID'] ?? '';

  static String get twitterClientSecret =>
      dotenv.env['TWITTER_CLIENT_SECRET'] ?? '';
}
