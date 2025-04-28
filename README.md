# youtube_linkedin_poster/youtube_linkedin_poster/README.md

# YouTube LinkedIn Poster

This Flutter application transcribes YouTube videos and generates LinkedIn posts using Claude AI.

## Features

1. **- Input YouTube URLs and extract video details.
2. - Download audio tracks and transcribe them using speech recognition.
3. - Generate LinkedIn-optimized content from transcriptions.
4. - Post directly to LinkedIn with OAuth authentication.
5. - Intuitive user interface with Material Design 3.**

## Project Structure

```
youtube_linkedin_poster
├── lib
│   ├── main.dart
│   ├── app.dart
│   ├── config
│   │   ├── env.dart
│   │   └── theme.dart
│   ├── models
│   │   ├── video_data.dart
│   │   ├── transcription.dart
│   │   └── post.dart
│   ├── services
│   │   ├── youtube_service.dart
│   │   ├── transcription_service.dart
│   │   ├── claude_service.dart
│   │   └── linkedin_service.dart
│   ├── providers
│   │   ├── auth_provider.dart
│   │   ├── video_provider.dart
│   │   └── post_provider.dart
│   ├── views
│   │   ├── home
│   │   │   ├── home_view.dart
│   │   │   └── home_viewmodel.dart
│   │   ├── transcription
│   │   │   ├── transcription_view.dart
│   │   │   └── transcription_viewmodel.dart
│   │   └── post
│   │       ├── post_view.dart
│   │       └── post_viewmodel.dart
│   ├── widgets
│   │   ├── video_input.dart
│   │   ├── progress_indicator.dart
│   │   └── post_editor.dart
│   ├── utils
│   │   ├── validators.dart
│   │   └── api_helpers.dart
│   └── constants
│       ├── strings.dart
│       └── api_constants.dart
├── .env
├── pubspec.yaml
└── README.md
```

## Setup Instructions

1. Clone the repository:
   ```
   git clone <repository-url>
   ```

2. Navigate to the project directory:
   ```
   cd youtube_linkedin_poster
   ```

3. Install dependencies:
   ```
   flutter pub get
   ```

4. Set up your environment variables in the `.env` file.

5. Run the application:
   ```
   flutter run
   ```

## Dependencies


- provider: ^6.0.5
- shared_preferences: ^2.2.0
- youtube_explode_dart: ^1.12.4
- speech_to_text: ^6.3.0
- just_audio: ^0.9.34
- dart_openai: ^4.0.0
- flutter_dotenv: ^5.1.0
- linkedin_login: ^2.3.1
- url_launcher: ^6.1.12

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.