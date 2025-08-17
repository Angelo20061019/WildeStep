import 'package:flutter/material.dart';
import 'pages/splash_screen.dart'; // Adjust the path if needed
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    print('Before Firebase initialization');
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        print('Firebase initialized!');
      } else {
        print('Firebase already initialized!');
      }
      print('After Firebase initialization');
    } else {
      print('Firebase initialization skipped: Unsupported platform');
    }
  } catch (e, st) {
    print('Firebase initialization error: $e\n$st');
  }
  runApp(const WildStepsApp());
}

class WildStepsApp extends StatelessWidget {
  const WildStepsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WILD STEPS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Montserrat', // Optional: set your modern font globally
      ),
      home: const SplashScreen(), // Set SplashScreen as the initial page
    );
  }
}