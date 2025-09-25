import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'theme.dart';
import 'views/auth/login_screen.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar dados de localização para pt_BR
  await initializeDateFormatting('pt_BR', null);
  // Inicializar serviço de tema (lê preferência salva)
  await ThemeService.init();
  
  runApp(const PontoDigitalApp());
}

class PontoDigitalApp extends StatelessWidget {
  const PontoDigitalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.themeModeNotifier,
      builder: (context, mode, child) {
        return MaterialApp(
          title: 'Ponto Digital',
          theme: AppTheme.lightTheme,
          darkTheme: ThemeData.dark().copyWith(
            useMaterial3: true,
            // You can further customize dark theme to match branding
          ),
          themeMode: mode,
          home: const LoginScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

