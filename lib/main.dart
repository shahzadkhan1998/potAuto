import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'providers/auth_provider.dart';
import 'providers/post_provider.dart';
import 'providers/video_provider.dart';
import 'views/home_view.dart';
import 'services/navigation_service.dart';

void main() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Set up global Flutter error handling
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        debugPrint('Flutter Error: ${details.exception}');
        debugPrint('Stack trace: ${details.stack}');
      };

      // Load environment variables with error handling
      try {
        debugPrint('Loading environment variables...');
        await dotenv.load(fileName: ".env");
        debugPrint('Environment variables loaded successfully');
      } catch (e) {
        debugPrint('Warning: Failed to load .env file: $e');
        debugPrint(
          'The app will continue, but some features may not work properly',
        );
      }

      // Run the app
      debugPrint('Starting application...');
      runApp(const MyApp());
    },
    (error, stack) {
      debugPrint('Uncaught error in root zone:');
      debugPrint('Error: $error');
      debugPrint('Stack trace: $stack');
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            debugPrint('Initializing AuthProvider');
            return AuthProvider();
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            debugPrint('Initializing VideoProvider');
            return VideoProvider();
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            debugPrint('Initializing PostProvider');
            return PostProvider();
          },
        ),
      ],
      child: MaterialApp(
        navigatorKey: NavigationService.navigatorKey,
        title: 'YouTube to LinkedIn',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const HomeView(),
        builder: (context, child) {
          if (child == null) return const SizedBox.shrink();

          ErrorWidget.builder = (FlutterErrorDetails details) {
            debugPrint('Error in widget tree: ${details.exception}');
            return Material(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Something went wrong',
                      style: TextStyle(fontSize: 18),
                    ),
                    if (kDebugMode)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          details.toString(),
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),
            );
          };

          return child;
        },
      ),
    );
  }
}
