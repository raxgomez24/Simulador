/// WebSocket message models for real-time communication
///
/// This file defines the message structure and constants used for
/// WebSocket communication in the multi-device investment app.
library;

/// Base WebSocket message class
///
/// All WebSocket messages follow this structure with a type, action,
/// optional data payload, and timestamp.
class WSMessage {
  /// Message type identifier (e.g., 'investment', 'session', 'user')
  final String type;

  /// Action to perform (e.g., 'create', 'update', 'delete')
  final String action;

  /// Optional data payload containing the message content
  final Map<String, dynamic>? data;

  /// ISO 8601 timestamp when the message was created
  final String? timestamp;

  /// Creates a new WebSocket message
  const WSMessage({
    required this.type,
    required this.action,
    this.data,
    this.timestamp,
  });

  // ========== MESSAGE TYPES ==========

  /// Investment-related messages
  static const String TYPE_INVESTMENT = 'investment';

  /// Session-related messages (timer sessions)
  static const String TYPE_SESSION = 'session';

  /// User-related messages
  static const String TYPE_USER = 'user';

  /// Project-related messages
  static const String TYPE_PROJECT = 'project';

  // ========== INVESTMENT ACTIONS ==========

  /// New investment created
  static const String ACTION_INVESTMENT_CREATED = 'created';

  /// Investment updated
  static const String ACTION_INVESTMENT_UPDATED = 'updated';

  /// Investment deleted
  static const String ACTION_INVESTMENT_DELETED = 'deleted';

  // ========== SESSION ACTIONS ==========

  /// Session started (timer began)
  static const String ACTION_SESSION_STARTED = 'started';

  /// Session updated (e.g., time update, note added)
  static const String ACTION_SESSION_UPDATED = 'updated';

  /// Session paused
  static const String ACTION_SESSION_PAUSED = 'paused';

  /// Session ended (timer stopped)
  static const String ACTION_SESSION_ENDED = 'ended';

  // ========== USER ACTIONS ==========

  /// User logged in
  static const String ACTION_USER_LOGIN = 'login';

  /// User logged out
  static const String ACTION_USER_LOGOUT = 'logout';

  // ========== SERIALIZATION ==========

  /// Creates a WSMessage from JSON
  ///
  /// Example:
  /// ```dart
  /// final json = {
  ///   'type': 'investment',
  ///   'action': 'created',
  ///   'data': {'id': '123', 'amount': 1000},
  ///   'timestamp': '2024-06-03T10:00:00Z'
  /// };
  /// final message = WSMessage.fromJson(json);
  /// ```
  factory WSMessage.fromJson(Map<String, dynamic> json) {
    return WSMessage(
      type: json['type'] as String,
      action: json['action'] as String,
      data: json['data'] as Map<String, dynamic>?,
      timestamp: json['timestamp'] as String?,
    );
  }

  /// Converts the WSMessage to JSON
  ///
  /// Example:
  /// ```dart
  /// final message = WSMessage(
  ///   type: WSMessage.TYPE_INVESTMENT,
  ///   action: WSMessage.ACTION_INVESTMENT_CREATED,
  ///   data: {'id': '123', 'amount': 1000},
  /// );
  /// final json = message.toJson();
  /// ```
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'action': action,
      if (data != null) 'data': data,
      if (timestamp != null) 'timestamp': timestamp,
    };
  }

  /// Creates a copy of this WSMessage with the given fields replaced
  WSMessage copyWith({
    String? type,
    String? action,
    Map<String, dynamic>? data,
    String? timestamp,
  }) {
    return WSMessage(
      type: type ?? this.type,
      action: action ?? this.action,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'WSMessage(type: $type, action: $action, data: $data, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is WSMessage &&
      other.type == type &&
      other.action == action &&
      other.data == data &&
      other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return type.hashCode ^
      action.hashCode ^
      data.hashCode ^
      timestamp.hashCode;
  }
}
