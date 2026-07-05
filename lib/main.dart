import 'package:flutter/material.dart';
import 'onboarding_screen.dart';

void main() => runApp(const MindScapeApp());

class MindScapeApp extends StatelessWidget {
  const MindScapeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OnboardingScreen(),
    );
  }
}
