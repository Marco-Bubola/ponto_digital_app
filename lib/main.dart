import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'theme.dart';
import 'views/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar dados de localização para pt_BR
  await initializeDateFormatting('pt_BR', null);
  
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

