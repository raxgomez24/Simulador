class AppConfig {
  // App Configuration
  static const String appName = 'Amerike Investment Sim';
  static const String appVersion = '1.0.0';

  // Platform Detection
  static bool get isWeb => identical(0, 0.0);
  static bool get isMobile => !isWeb;

  // Data Source Configuration
  /// Cambia a false para usar el servidor WebSocket
  /// Cambia a true para usar datos locales (mock data)
  static const bool useLocalData = true;

  // Web Server Configuration (para modo multi-dispositivo)
  static const bool useWebServer = false; // TODO: Cambiar a true cuando se configure el servidor central
  static const String serverHost = '0.0.0.0'; // Escuchar en todas las interfaces
  static const int serverPort = 9000; // Puerto del servidor web

  // WebSocket Configuration (solo se usa si useLocalData es false)
  static const String defaultWebSocketUrl = 'ws://localhost:8080';
  static const Duration connectionTimeout = Duration(seconds: 30);

  // Investment Configuration
  static const double initialBalance = 1000000.0; // $1,000,000
  static const Duration roundDuration = Duration(minutes: 30);
  static const int minimumInvestment = 10000;
  static const int maximumInvestment = 500000;

  // UI Configuration
  static const bool enableAnimations = true;
  static const bool enableDarkMode = true;
  static const bool enableHapticFeedback = true;
}
