import 'package:flutter/material.dart';
import 'initialization.dart';
import 'main_app.dart';

void main() async {
  // Set up error handlers first
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('FlutterError: ${details.exceptionAsString()}');
    debugPrint('Stack trace: ${details.stack}');
    FlutterError.dumpErrorToConsole(details);
  };

  // Initialize the app
  final initialized = await AppInitializer.initialize();

  if (!initialized) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'Failed to initialize app. Please check your connection and try again.',
            ),
          ),
        ),
      ),
    );
    return;
  }

  runApp(const MainApp());
}
