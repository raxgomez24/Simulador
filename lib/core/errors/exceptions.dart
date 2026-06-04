import 'package:equatable/equatable.dart';

abstract class AppException extends Equatable implements Exception {
  final String message;
  final String? code;

  const AppException({
    required this.message,
    this.code,
  });

  @override
  List<Object?> get props => [message, code];
}

class ServerException extends AppException {
  const ServerException({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

class NetworkException extends AppException {
  const NetworkException({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

class AuthenticationException extends AppException {
  const AuthenticationException({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

class AuthorizationException extends AppException {
  const AuthorizationException({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  const ValidationException({
    required String message,
    String? code,
    this.fieldErrors,
  }) : super(message: message, code: code);

  @override
  List<Object?> get props => [message, code, fieldErrors];
}

class NotFoundException extends AppException {
  const NotFoundException({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

class ConflictException extends AppException {
  const ConflictException({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

class InsufficientFundsException extends AppException {
  const InsufficientFundsException({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

class InvalidAmountException extends AppException {
  const InvalidAmountException({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

class ConnectionException extends AppException {
  const ConnectionException({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

class TimeoutException extends AppException {
  const TimeoutException({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

class CacheException extends AppException {
  const CacheException({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

class SessionClosedException extends AppException {
  const SessionClosedException({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

class DatabaseException extends AppException {
  const DatabaseException({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

class InsufficientBalanceException extends AppException {
  final double availableBalance;

  const InsufficientBalanceException({
    required String message,
    String? code,
    this.availableBalance = 0.0,
  }) : super(message: message, code: code);

  @override
  List<Object?> get props => [message, code, availableBalance];
}
