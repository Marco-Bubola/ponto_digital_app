import 'package:flutter/material.dart';
import 'theme.dart';
import 'views/auth/login_screen.dart';

void main() {
  runApp(const PontoDigitalApp());
}

class PontoDigitalApp extends StatelessWidget {
  const PontoDigitalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ponto Digital',
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
