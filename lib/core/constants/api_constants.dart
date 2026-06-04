class ApiConstants {
  // WebSocket Configuration
  static const String defaultWebSocketUrl = 'ws://localhost:8080';
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration reconnectDelay = Duration(seconds: 3);
  static const int maxReconnectAttempts = 5;

  // Heartbeat Configuration
  static const Duration heartbeatInterval = Duration(seconds: 30);
  static const Duration heartbeatTimeout = Duration(seconds: 10);

  // Message Types
  static const String messageTypeAuth = 'auth';
  static const String messageTypeProjects = 'projects';
  static const String messageTypeProjectDetail = 'project_detail';
  static const String messageTypeInvestments = 'investments';
  static const String messageTypeInvest = 'invest';
  static const String messageTypeSession = 'session';
  static const String messageTypeRanking = 'ranking';
  static const String messageTypeUsers = 'users';
  static const String messageTypeError = 'error';
  static const String messageTypeHeartbeat = 'heartbeat';
  static const String messageTypePong = 'pong';

  // Response Status
  static const String statusSuccess = 'success';
  static const String statusError = 'error';
  static const String statusPending = 'pending';

  // Error Codes
  static const String errorInvalidCredentials = 'INVALID_CREDENTIALS';
  static const String errorUserExists = 'USER_EXISTS';
  static const String errorInsufficientFunds = 'INSUFFICIENT_FUNDS';
  static const String errorInvalidAmount = 'INVALID_AMOUNT';
  static const String errorProjectNotFound = 'PROJECT_NOT_FOUND';
  static const String errorUserNotFound = 'USER_NOT_FOUND';
  static const String errorServer = 'SERVER_ERROR';
  static const String errorUnauthorized = 'UNAUTHORIZED';
  static const String errorConnectionLost = 'CONNECTION_LOST';

  // Session States
  static const String sessionWaiting = 'waiting';
  static const String sessionActive = 'active';
  static const String sessionPaused = 'paused';
  static const String sessionEnded = 'ended';

  // User Roles
  static const String roleAdmin = 'admin';
  static const String roleStudent = 'student';
  static const String roleGuest = 'guest';

  // Initial Configuration
  static const double initialBalance = 1000000.0; // $1,000,000
  static const Duration roundDuration = Duration(minutes: 30);
  static const int minimumInvestment = 10000;
  static const int maximumInvestment = 500000;
}
