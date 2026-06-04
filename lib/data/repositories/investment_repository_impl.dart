import 'dart:async';
import '../../domain/entities/investment.dart';
import '../../domain/entities/session.dart';
import '../../domain/repositories/investment_repository.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/exceptions.dart';
import '../datasources/remote/websocket_datasource.dart';
import '../models/investment_model.dart';

class InvestmentRepositoryImpl implements InvestmentRepository {
  final WebSocketDataSource _dataSource;

  InvestmentRepositoryImpl(this._dataSource);

  @override
  Future<List<Investment>> getAllInvestments() async {
    try {
      final completer = Completer<List<Investment>>();

      final subscription = _dataSource.messageStream.listen((message) {
        if (message['type'] == ApiConstants.messageTypeInvestments) {
          if (message['status'] == ApiConstants.statusSuccess) {
            final List<dynamic> investmentsJson = message['data'] ?? [];
            final investments = investmentsJson
                .map((json) => InvestmentModel.fromJson(json).toEntity())
                .toList();
            completer.complete(investments);
          } else {
            completer.completeError(
              ServerException(
                message: message['error'] ?? 'Error al obtener inversiones',
                code: message['errorCode'],
              ),
            );
          }
        }
      });

      _dataSource.send({
        'type': ApiConstants.messageTypeInvestments,
        'action': 'get_all',
      });

      final result = await completer.future.timeout(
        ApiConstants.connectionTimeout,
      );
      subscription.cancel();
      return result;
    } on TimeoutException {
      throw const TimeoutException(
        message: 'Tiempo de espera agotado',
        code: ApiConstants.errorServer,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(
        message: e.toString(),
        code: ApiConstants.errorServer,
      );
    }
  }

  @override
  Future<List<Investment>> getInvestmentsByUser(String userId) async {
    try {
      final completer = Completer<List<Investment>>();

      final subscription = _dataSource.messageStream.listen((message) {
        if (message['type'] == ApiConstants.messageTypeInvestments) {
          if (message['status'] == ApiConstants.statusSuccess) {
            final List<dynamic> investmentsJson = message['data'] ?? [];
            final investments = investmentsJson
                .map((json) => InvestmentModel.fromJson(json).toEntity())
                .toList();
            completer.complete(investments);
          } else {
            completer.completeError(
              ServerException(
                message: message['error'] ?? 'Error al obtener inversiones',
                code: message['errorCode'],
              ),
            );
          }
        }
      });

      _dataSource.send({
        'type': ApiConstants.messageTypeInvestments,
        'action': 'get_by_user',
        'userId': userId,
      });

      final result = await completer.future.timeout(
        ApiConstants.connectionTimeout,
      );
      subscription.cancel();
      return result;
    } on TimeoutException {
      throw const TimeoutException(
        message: 'Tiempo de espera agotado',
        code: ApiConstants.errorServer,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(
        message: e.toString(),
        code: ApiConstants.errorServer,
      );
    }
  }

  @override
  Future<List<Investment>> getInvestmentsByProject(String projectId) async {
    try {
      final completer = Completer<List<Investment>>();

      final subscription = _dataSource.messageStream.listen((message) {
        if (message['type'] == ApiConstants.messageTypeInvestments) {
          if (message['status'] == ApiConstants.statusSuccess) {
            final List<dynamic> investmentsJson = message['data'] ?? [];
            final investments = investmentsJson
                .map((json) => InvestmentModel.fromJson(json).toEntity())
                .toList();
            completer.complete(investments);
          } else {
            completer.completeError(
              ServerException(
                message: message['error'] ?? 'Error al obtener inversiones',
                code: message['errorCode'],
              ),
            );
          }
        }
      });

      _dataSource.send({
        'type': ApiConstants.messageTypeInvestments,
        'action': 'get_by_project',
        'projectId': projectId,
      });

      final result = await completer.future.timeout(
        ApiConstants.connectionTimeout,
      );
      subscription.cancel();
      return result;
    } on TimeoutException {
      throw const TimeoutException(
        message: 'Tiempo de espera agotado',
        code: ApiConstants.errorServer,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(
        message: e.toString(),
        code: ApiConstants.errorServer,
      );
    }
  }

  @override
  Future<Investment> makeInvestment({
    required String userId,
    required String projectId,
    required double amount,
    SessionState? sessionState,
  }) async {
    try {
      final completer = Completer<Investment>();

      final subscription = _dataSource.messageStream.listen((message) {
        if (message['type'] == ApiConstants.messageTypeInvest) {
          if (message['status'] == ApiConstants.statusSuccess) {
            final investmentModel = InvestmentModel.fromJson(message['data']);
            completer.complete(investmentModel.toEntity());
          } else {
            final errorCode = message['errorCode'];
            if (errorCode == ApiConstants.errorInsufficientFunds) {
              completer.completeError(
                const InsufficientFundsException(
                  message: 'Saldo insuficiente para realizar la inversión',
                  code: ApiConstants.errorInsufficientFunds,
                ),
              );
            } else if (errorCode == ApiConstants.errorInvalidAmount) {
              completer.completeError(
                const InvalidAmountException(
                  message: 'Monto de inversión inválido',
                  code: ApiConstants.errorInvalidAmount,
                ),
              );
            } else {
              completer.completeError(
                ServerException(
                  message: message['error'] ?? 'Error al invertir',
                  code: errorCode,
                ),
              );
            }
          }
        }
      });

      _dataSource.send({
        'type': ApiConstants.messageTypeInvest,
        'action': 'create',
        'userId': userId,
        'projectId': projectId,
        'amount': amount,
      });

      final result = await completer.future.timeout(
        ApiConstants.connectionTimeout,
      );
      subscription.cancel();
      return result;
    } on TimeoutException {
      throw const TimeoutException(
        message: 'Tiempo de espera agotado',
        code: ApiConstants.errorServer,
      );
    } catch (e) {
      if (e is InsufficientFundsException ||
          e is InvalidAmountException ||
          e is ServerException) {
        rethrow;
      }
      throw ServerException(
        message: e.toString(),
        code: ApiConstants.errorServer,
      );
    }
  }

  @override
  Future<double> getTotalInvestedByUser(String userId) async {
    final investments = await getInvestmentsByUser(userId);
    return investments.fold<double>(
      0.0,
      (sum, investment) => sum + investment.monto,
    );
  }

  @override
  Future<double> getTotalInvestedInProject(String projectId) async {
    final investments = await getInvestmentsByProject(projectId);
    return investments.fold<double>(
      0.0,
      (sum, investment) => sum + investment.monto,
    );
  }

  @override
  Future<Investment> createInvestment({
    required String usuarioId,
    required String usuarioNombre,
    required String perfil,
    required String proyectoId,
    required String proyectoNombre,
    required String temaId,
    required String temaNombre,
    required String temaColor,
    required double monto,
    String? observaciones,
    SessionState? sessionState,
  }) async {
    try {
      final completer = Completer<Investment>();

      final subscription = _dataSource.messageStream.listen((message) {
        if (message['type'] == ApiConstants.messageTypeInvest) {
          if (message['status'] == ApiConstants.statusSuccess) {
            final investmentModel = InvestmentModel.fromJson(message['data']);
            completer.complete(investmentModel.toEntity());
          } else {
            final errorCode = message['errorCode'];
            if (errorCode == ApiConstants.errorInsufficientFunds) {
              completer.completeError(
                const InsufficientFundsException(
                  message: 'Saldo insuficiente para realizar la inversión',
                  code: ApiConstants.errorInsufficientFunds,
                ),
              );
            } else if (errorCode == ApiConstants.errorInvalidAmount) {
              completer.completeError(
                const InvalidAmountException(
                  message: 'Monto de inversión inválido',
                  code: ApiConstants.errorInvalidAmount,
                ),
              );
            } else {
              completer.completeError(
                ServerException(
                  message: message['error'] ?? 'Error al crear inversión',
                  code: errorCode,
                ),
              );
            }
          }
        }
      });

      _dataSource.send({
        'type': ApiConstants.messageTypeInvest,
        'action': 'create',
        'usuarioId': usuarioId,
        'usuarioNombre': usuarioNombre,
        'perfil': perfil,
        'proyectoId': proyectoId,
        'proyectoNombre': proyectoNombre,
        'temaId': temaId,
        'temaNombre': temaNombre,
        'temaColor': temaColor,
        'monto': monto,
        if (observaciones != null) 'observaciones': observaciones,
      });

      final result = await completer.future.timeout(
        ApiConstants.connectionTimeout,
      );
      subscription.cancel();
      return result;
    } on TimeoutException {
      throw const TimeoutException(
        message: 'Tiempo de espera agotado',
        code: ApiConstants.errorServer,
      );
    } catch (e) {
      if (e is InsufficientFundsException ||
          e is InvalidAmountException ||
          e is ServerException) {
        rethrow;
      }
      throw ServerException(
        message: e.toString(),
        code: ApiConstants.errorServer,
      );
    }
  }

  @override
  Future<Investment> updateInvestment({
    required String id,
    String? usuarioId,
    String? usuarioNombre,
    String? perfil,
    String? proyectoId,
    String? proyectoNombre,
    String? temaId,
    String? temaNombre,
    String? temaColor,
    double? monto,
    String? observaciones,
    String? estado,
  }) async {
    try {
      final completer = Completer<Investment>();

      final subscription = _dataSource.messageStream.listen((message) {
        if (message['type'] == ApiConstants.messageTypeInvest) {
          if (message['status'] == ApiConstants.statusSuccess) {
            final investmentModel = InvestmentModel.fromJson(message['data']);
            completer.complete(investmentModel.toEntity());
          } else {
            final errorCode = message['errorCode'];
            if (errorCode == ApiConstants.errorInsufficientFunds) {
              completer.completeError(
                const InsufficientFundsException(
                  message: 'Saldo insuficiente para actualizar la inversión',
                  code: ApiConstants.errorInsufficientFunds,
                ),
              );
            } else if (errorCode == ApiConstants.errorInvalidAmount) {
              completer.completeError(
                const InvalidAmountException(
                  message: 'Monto de inversión inválido',
                  code: ApiConstants.errorInvalidAmount,
                ),
              );
            } else {
              completer.completeError(
                ServerException(
                  message: message['error'] ?? 'Error al actualizar inversión',
                  code: errorCode,
                ),
              );
            }
          }
        }
      });

      _dataSource.send({
        'type': ApiConstants.messageTypeInvest,
        'action': 'update',
        'id': id,
        if (usuarioId != null) 'usuarioId': usuarioId,
        if (usuarioNombre != null) 'usuarioNombre': usuarioNombre,
        if (perfil != null) 'perfil': perfil,
        if (proyectoId != null) 'proyectoId': proyectoId,
        if (proyectoNombre != null) 'proyectoNombre': proyectoNombre,
        if (temaId != null) 'temaId': temaId,
        if (temaNombre != null) 'temaNombre': temaNombre,
        if (temaColor != null) 'temaColor': temaColor,
        if (monto != null) 'monto': monto,
        if (observaciones != null) 'observaciones': observaciones,
        if (estado != null) 'estado': estado,
      });

      final result = await completer.future.timeout(
        ApiConstants.connectionTimeout,
      );
      subscription.cancel();
      return result;
    } on TimeoutException {
      throw const TimeoutException(
        message: 'Tiempo de espera agotado',
        code: ApiConstants.errorServer,
      );
    } catch (e) {
      if (e is InsufficientFundsException ||
          e is InvalidAmountException ||
          e is ServerException) {
        rethrow;
      }
      throw ServerException(
        message: e.toString(),
        code: ApiConstants.errorServer,
      );
    }
  }

  @override
  Future<void> deleteInvestment(String investmentId) async {
    try {
      final completer = Completer<void>();

      final subscription = _dataSource.messageStream.listen((message) {
        if (message['type'] == ApiConstants.messageTypeInvest) {
          if (message['status'] == ApiConstants.statusSuccess) {
            completer.complete();
          } else {
            completer.completeError(
              ServerException(
                message: message['error'] ?? 'Error al eliminar inversión',
                code: message['errorCode'],
              ),
            );
          }
        }
      });

      _dataSource.send({
        'type': ApiConstants.messageTypeInvest,
        'action': 'delete',
        'id': investmentId,
      });

      await completer.future.timeout(
        ApiConstants.connectionTimeout,
      );
      subscription.cancel();
    } on TimeoutException {
      throw const TimeoutException(
        message: 'Tiempo de espera agotado',
        code: ApiConstants.errorServer,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(
        message: e.toString(),
        code: ApiConstants.errorServer,
      );
    }
  }
}
