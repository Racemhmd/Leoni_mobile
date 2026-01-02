import 'package:flutter/material.dart';
import 'auth/login_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const LeoniApp());
}

class LeoniApp extends StatelessWidget {
  const LeoniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Leoni Employee App',
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
    );
  }
}
