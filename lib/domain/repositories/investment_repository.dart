import '../entities/investment.dart';
import '../entities/session.dart';

abstract class InvestmentRepository {
  Future<List<Investment>> getAllInvestments();
  Future<List<Investment>> getInvestmentsByUser(String userId);
  Future<List<Investment>> getInvestmentsByProject(String projectId);
  Future<Investment> makeInvestment({
    required String userId,
    required String projectId,
    required double amount,
    SessionState? sessionState,
  });
  Future<double> getTotalInvestedByUser(String userId);
  Future<double> getTotalInvestedInProject(String projectId);

  /// CRUD operations for investments (used by admin/investments management)
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
  });

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
  });

  Future<void> deleteInvestment(String investmentId);
}
