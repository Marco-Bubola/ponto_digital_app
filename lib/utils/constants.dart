// Constantes do aplicativo Ponto Digital
class AppConstants {
  // API Configuration
  static const String baseUrl = 'https://api.pontodigital.com';
  static const String apiVersion = 'v1';
  
  // Google Gemini AI
  static const String geminiApiKey = 'YOUR_GEMINI_API_KEY';
  
  // App Configuration
  static const String appName = 'Ponto Digital';
  static const String appVersion = '1.0.0';
  
  // Security Settings
  static const int maxDevicesPerUser = 3;
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
