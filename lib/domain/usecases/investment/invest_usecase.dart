import '../../entities/investment.dart';
import '../../entities/session.dart';
import '../../repositories/investment_repository.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/errors/exceptions.dart';

class InvestUseCase {
  final InvestmentRepository _investmentRepository;

  InvestUseCase(this._investmentRepository);

  Future<Investment> call({
    required String userId,
    required String projectId,
    required double amount,
    SessionState? sessionState,
  }) async {
    if (userId.isEmpty) {
      throw const ValidationException(
        message: 'El ID de usuario es requerido',
        code: 'REQUIRED_USER_ID',
      );
    }
    if (projectId.isEmpty) {
      throw const ValidationException(
        message: 'El ID del proyecto es requerido',
        code: 'REQUIRED_PROJECT_ID',
      );
    }
    if (amount <= 0) {
      throw const InvalidAmountException(
        message: 'El monto debe ser mayor a 0',
        code: ApiConstants.errorInvalidAmount,
      );
    }
    if (amount < ApiConstants.minimumInvestment) {
      throw InvalidAmountException(
        message: 'La inversión mínima es \$${ApiConstants.minimumInvestment}',
        code: ApiConstants.errorInvalidAmount,
      );
    }
    if (amount > ApiConstants.maximumInvestment) {
      throw InvalidAmountException(
        message: 'La inversión máxima es \$${ApiConstants.maximumInvestment}',
        code: ApiConstants.errorInvalidAmount,
      );
    }
    return await _investmentRepository.makeInvestment(
      userId: userId,
      projectId: projectId,
      amount: amount,
      sessionState: sessionState,
    );
  }
}
