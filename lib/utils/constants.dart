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

// Cores do Design System (Paleta Verde Moderna)
class AppColors {
  // Tons principais de verde
  static const int primaryGreen = 0xFF10B981; // Emerald 500
  static const int primaryGreenLight = 0xFF34D399; // Emerald 400  
  static const int primaryGreenDark = 0xFF059669; // Emerald 600
  
  // Tons secundários (verde azulado)
  static const int secondaryTeal = 0xFF14B8A6; // Teal 500
  static const int secondaryTealLight = 0xFF5EEAD4; // Teal 300
  static const int secondaryTealDark = 0xFF0F766E; // Teal 700
  
  // Tons de acento (verde lima)
  static const int accentLime = 0xFF84CC16; // Lime 500
  static const int accentLimeLight = 0xFFA3E635; // Lime 400
  
  // Tons neutros modernos
  static const int neutralGray = 0xFF6B7280; // Gray 500
  static const int neutralGray50 = 0xFFF9FAFB;
  static const int neutralGray100 = 0xFFF3F4F6;
  static const int neutralGray200 = 0xFFE5E7EB;
  static const int neutralGray300 = 0xFFD1D5DB;
  static const int neutralGray600 = 0xFF4B5563;
  static const int neutralGray800 = 0xFF1F2937;
  static const int neutralGray900 = 0xFF111827;
  
  // Status colors (modernizadas)
  static const int successGreen = 0xFF22C55E; // Green 500
  static const int warningYellow = 0xFFF59E0B; // Amber 500
  static const int errorRed = 0xFFEF4444; // Red 500
  
  // Tons legados (mantidos para compatibilidade)
  static const int primaryBlue = primaryGreen; // Alias para migração gradual
  static const int lightGray = neutralGray50;
  static const int darkGray = neutralGray900;
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
