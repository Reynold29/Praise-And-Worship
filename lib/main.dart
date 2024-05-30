import 'package:flutter/material.dart';
import 'package:worshipcompanion/screens/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:worshipcompanion/screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool onboardingCompleted = prefs.getBool('onboardingCompleted') ?? false;
  String username = prefs.getString('username') ?? '';

  runApp(MyApp(onboardingCompleted: onboardingCompleted, username: username));
}

class MyApp extends StatelessWidget {
  final bool onboardingCompleted;
  final String username;

  const MyApp({super.key, required this.onboardingCompleted, required this.username});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Praise and Worship Companion',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: onboardingCompleted ? MainScreen(username: username) : const OnboardingScreen(),
    );
  }
}
