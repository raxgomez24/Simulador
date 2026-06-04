import '../../entities/investment.dart';
import '../../repositories/investment_repository.dart';

class GetInvestmentsUseCase {
  final InvestmentRepository _investmentRepository;

  GetInvestmentsUseCase(this._investmentRepository);

  Future<List<Investment>> callByUser(String userId) async {
    return await _investmentRepository.getInvestmentsByUser(userId);
  }

  Future<List<Investment>> callByProject(String projectId) async {
    return await _investmentRepository.getInvestmentsByProject(projectId);
  }

  Future<double> callTotalByUser(String userId) async {
    return await _investmentRepository.getTotalInvestedByUser(userId);
  }

  Future<double> callTotalByProject(String projectId) async {
    return await _investmentRepository.getTotalInvestedInProject(projectId);
  }
}
