# NextU - AI Career Coach

NextU is a Flutter application that serves as your personal AI career coach. It helps you track your career goals, get AI-powered advice, and improve your professional development journey.

## Features

- 🎯 Career Goal Setting & Tracking
- 💬 AI-powered Career Coaching Conversations
- 📄 CV/Resume Review & Optimization
- 📊 Weekly Progress Check-ins
- 🔐 Secure Authentication (Google & Apple Sign-in)

## Getting Started

### Prerequisites

- Flutter SDK (>=3.2.3)
- Dart SDK (>=3.2.3)
- Firebase project
- Google Cloud project with Gemini API enabled
- For iOS: Xcode and CocoaPods
- For Android: Android Studio and Android SDK

### Setup

1. Clone the repository:
```bash
git clone https://github.com/yourusername/nextu.git
cd nextu
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure Firebase:
   - Create a new Firebase project
   - Add Android and iOS apps to your Firebase project
   - Download and place the configuration files:
     - Android: `google-services.json` in `android/app/`
     - iOS: `GoogleService-Info.plist` in `ios/Runner/`

4. Set up Gemini API:
   - Get an API key from Google Cloud Console
   - Add it to your environment variables or use Firebase Remote Config

5. Configure signing:
   - For Android: Update `android/app/build.gradle` with your signing config
   - For iOS: Set up signing in Xcode

6. Run the app:
```bash
flutter run
```

### Environment Variables

Create a `.env` file in the project root with:

```
GEMINI_API_KEY=your_gemini_api_key
```

## Project Structure

```
lib/
  ├── constants/          # App-wide constants
  ├── features/          
  │   ├── auth/          # Authentication
  │   ├── chat/          # AI chat functionality
  │   ├── cv/            # CV review feature
  │   ├── goals/         # Career goals
  │   └── home/          # Home screen
  ├── services/          # Business logic
  ├── models/            # Data models
  └── main.dart          # App entry point
```

## State Management

The app uses Riverpod for state management, providing:
- Dependency injection
- State management
- Side effects handling
- Caching

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Google Gemini API for AI capabilities
- Firebase for backend services
- Flutter team for the amazing framework
