// Constantes do aplicativo Ponto Digital
class AppConstants {
  // API Configuration
  // Default production API base. You can override this at build/run time using
  // --dart-define=API_BASE=<url>. Example for local testing with Android emulator:
  // flutter run -d emulator-5554 --dart-define=API_BASE=http://10.0.2.2:3000
  static const String baseUrl = 'https://api.pontodigital.com';

  // Backwards-compatible alias used across the app. Reads the compile-time
  // environment variable 'API_BASE' when provided via --dart-define. If not
  // provided, falls back to the production `baseUrl`.
  static const String apiBase = String.fromEnvironment('API_BASE', defaultValue: baseUrl);
  static const String apiVersion = 'v1';
  
  // Google Gemini AI
  static const String geminiApiKey = 'YOUR_GEMINI_API_KEY';
  
  // App Configuration
  static const String appName = 'Ponto Digital';
  static const String appVersion = '1.0.0';
  
  // Security Settings
  static const int maxDevicesPerUser = 5;
  static const double gpsRadiusMeters = 100.0;
  
  // Time Settings
  static const int offlineSyncIntervalMinutes = 30;
  static const int sessionTimeoutMinutes = 480; // 8 horas
}

// Cores do Design System (baseado na documentação)
class AppColors {
  static const int primaryBlue = 0xFF2563EB;
  static const int secondaryTeal = 0xFF14B8A6;
  static const int neutralGray = 0xFF6B7280;
  static const int successGreen = 0xFF10B981;
  static const int warningYellow = 0xFFF59E0B;
  static const int errorRed = 0xFFEF4444;
  
  // Tons adicionais
  static const int lightGray = 0xFFF9FAFB;
  static const int darkGray = 0xFF1F2937;
  static const int white = 0xFFFFFFFF;
}

// Tipos de marcação de ponto
enum TimeRecordType {
  entrada,    // ✅ Entrada - Início da jornada
  pausa,      // ⏸️ Pausa - Intervalo/almoço
  retorno,    // ▶️ Retorno - Volta da pausa
  saida       // 🏁 Saída - Fim da jornada
}

// Status de validação de ponto
enum ValidationStatus {
  success,
  faceRecognitionFailed,
  gpsOutOfRange,
  deviceNotAuthorized,
  networkError
}
