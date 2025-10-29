# Game Tracker

A simple Flutter app to track video games that you have played or completed.

## Features

- Search for games by name using the RAWG.io API
- Add games to your personal list
- Mark start and completion dates
- Add personal ratings and notes
- Clean, modern Material 3 design

## Setup

1. Get a free API key from [RAWG.io](https://rawg.io/apidocs)
   - When asked for a URL during registration, you can use:
     - `http://localhost` (for development)
     - Your GitHub repository URL if you have one
     - `https://example.com` (temporary URL for development)
2. Add your API key to `lib/config/api_config.dart`
3. Run `flutter pub get`
4. Run `flutter run`

## Architecture

The app follows clean architecture principles:
- **Models**: Data classes for Game and SavedGame
- **Services**: API service for RAWG.io and local storage service
- **Providers**: Riverpod providers for state management
- **UI**: Screens and widgets organized by feature
