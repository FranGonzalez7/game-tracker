# Game Tracker

A simple Flutter app to track video games that you have played or completed.

## Features

- Search for games by name using the RAWG.io API
- Add games to your personal list
- Mark start and completion dates
- Add personal ratings and notes
- Clean, modern Material 3 design
- User authentication with Firebase (Login and Register)

## Setup

1. **Configure Firebase:**
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Add your Android/iOS app to the Firebase project
   - Download the configuration files:
     - Android: `google-services.json` (place it in `android/app/`)
     - iOS: `GoogleService-Info.plist` (place it in `ios/Runner/`)
   - Enable Email/Password authentication in Firebase Console
     - Go to Authentication > Sign-in method > Enable Email/Password

2. **Get a free API key from [RAWG.io](https://rawg.io/apidocs)**
   - When asked for a URL during registration, you can use:
     - `http://localhost` (for development)
     - Your GitHub repository URL if you have one
     - `https://example.com` (temporary URL for development)
   - Add your API key to `lib/config/api_config.dart`

3. **Install dependencies:**
   ```bash
   flutter pub get
   ```

4. **Run the app:**
   ```bash
   flutter run
   ```

## Architecture

The app follows clean architecture principles:
- **Models**: Data classes for Game and SavedGame
- **Services**: API service for RAWG.io, local storage service, and Firebase authentication service
- **Providers**: Riverpod providers for state management (theme, games, saved games, and authentication)
- **UI**: Screens and widgets organized by feature

## Authentication

The app uses Firebase Authentication for user login and registration:
- Users can create an account with email and password
- Users can sign in with their credentials
- Session persistence is handled automatically by Firebase
- Users can sign out from the Settings screen
