import 'package:intl/intl.dart';
import 'package:amerike_investment_sim/domain/entities/investment.dart';
import 'package:amerike_investment_sim/domain/entities/project.dart';
import 'package:amerike_investment_sim/domain/entities/user.dart';

class ExportService {
  static const String _csvDelimiter = ',';
  static final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd HH:mm:ss');
  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );

  static String exportInvestmentsToCSV(List<Investment> investments) {
    final buffer = StringBuffer();

    buffer.writeln('ID,Usuario ID,Usuario Nombre,Proyecto ID,Proyecto Nombre,Tema ID,Tema Nombre,Tema Color,Monto,Fecha Hora,Observaciones');

    for (final investment in investments) {
      final line = [
        _escapeCSV(investment.id),
        _escapeCSV(investment.usuarioId),
        _escapeCSV(investment.usuarioNombre ?? 'N/A'),
        _escapeCSV(investment.proyectoId),
        _escapeCSV(investment.proyectoNombre ?? 'N/A'),
        _escapeCSV(investment.temaId),
        _escapeCSV(investment.temaNombre ?? 'N/A'),
        _escapeCSV(investment.temaColor ?? 'N/A'),
        investment.monto.toStringAsFixed(2),
        _dateFormatter.format(investment.fechaHora),
        _escapeCSV(investment.observaciones ?? ''),
      ].join(_csvDelimiter);

      buffer.writeln(line);
    }

    return buffer.toString();
  }

  static String exportProjectsToCSV(List<Project> projects) {
    final buffer = StringBuffer();

    buffer.writeln('ID,Nombre,Descripción,Tema ID,Tema Nombre,Tema Color,Monto Invertido,Número Inversores,Creado En,Activo,Participantes');

    for (final project in projects) {
      final line = [
        _escapeCSV(project.id),
        _escapeCSV(project.nombre),
        _escapeCSV(project.descripcion ?? ''),
        _escapeCSV(project.temaId),
        _escapeCSV(project.temaNombre),
        _escapeCSV(project.temaColor ?? ''),
        project.totalInvertido.toStringAsFixed(2),
        project.numeroInversores.toString(),
        project.createdAt != null
            ? _dateFormatter.format(project.createdAt!)
            : 'N/A',
        project.activo.toString(),
        _escapeCSV(project.participantes.map((p) => '${p['name']}: ${p['role']}').join('; ')),
      ].join(_csvDelimiter);

      buffer.writeln(line);
    }

    return buffer.toString();
  }

  static String exportUsersToCSV(List<User> users) {
    final buffer = StringBuffer();

    buffer.writeln('ID,Nombre,Correo,Username,Saldo,Perfil,Activo,Fecha Registro,Creado En,Último Login');

    for (final user in users) {
      final line = [
        _escapeCSV(user.id),
        _escapeCSV(user.nombre),
        _escapeCSV(user.correo ?? ''),
        _escapeCSV(user.username),
        user.saldo.toStringAsFixed(2),
        _escapeCSV(User.perfilToString(user.perfil)),
        user.activo.toString(),
        user.fechaRegistro != null
            ? _dateFormatter.format(user.fechaRegistro!)
            : 'N/A',
        user.createdAt != null
            ? _dateFormatter.format(user.createdAt!)
            : 'N/A',
        user.lastLogin != null
            ? _dateFormatter.format(user.lastLogin!)
            : 'N/A',
      ].join(_csvDelimiter);

      buffer.writeln(line);
    }

    return buffer.toString();
  }

  static String exportRankingToCSV(List<MapEntry<String, double>> ranking) {
    final buffer = StringBuffer();

    buffer.writeln('Posición,Proyecto,Monto Invertido,Número Inversores,Porcentaje');

    final total = ranking.fold<double>(0, (sum, entry) => sum + entry.value);

    for (int i = 0; i < ranking.length; i++) {
      final entry = ranking[i];
      final percentage = total > 0 ? (entry.value / total * 100) : 0;

      final line = [
        (i + 1).toString(),
        _escapeCSV(entry.key),
        entry.value.toStringAsFixed(2),
        'N/A',
        percentage.toStringAsFixed(2),
      ].join(_csvDelimiter);

      buffer.writeln(line);
    }

    return buffer.toString();
  }

  static String generateFilename({
    required String type,
    String? extension,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'Tania_${type}_${timestamp}.${extension ?? 'csv'}';
  }

  static String _escapeCSV(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  static Map<String, dynamic> generateSummaryData({
    List<Investment>? investments,
    List<Project>? projects,
    List<User>? users,
  }) {
    final summary = <String, dynamic>{};

    if (investments != null && investments.isNotEmpty) {
      final totalInvested = investments.fold<double>(
        0,
        (sum, inv) => sum + inv.monto,
      );

      final uniqueUsers = investments.map((inv) => inv.usuarioId).toSet();
      final uniqueProjects = investments.map((inv) => inv.proyectoId).toSet();

      final investmentsByTema = <String, int>{};
      for (final inv in investments) {
        final tema = inv.temaNombre ?? 'unknown';
        investmentsByTema[tema] = (investmentsByTema[tema] ?? 0) + 1;
      }

      summary['inversiones'] = {
        'total': investments.length,
        'monto_total': totalInvested,
        'usuarios_unicos': uniqueUsers.length,
        'proyectos_unicos': uniqueProjects.length,
        'por_tema': investmentsByTema,
        'promedio_por_inversion': totalInvested / investments.length,
      };
    }

    if (projects != null && projects.isNotEmpty) {
      final totalProjectRaised = projects.fold<double>(
        0,
        (sum, proj) => sum + proj.totalInvertido,
      );

      final totalInvestors = projects.fold<int>(
        0,
        (sum, proj) => sum + proj.numeroInversores,
      );

      final activeProjects = projects.where((p) => p.activo).length;

      summary['proyectos'] = {
        'total': projects.length,
        'activos': activeProjects,
        'inactivos': projects.length - activeProjects,
        'recaudado_total': totalProjectRaised,
        'inversores_totales': totalInvestors,
        'promedio_invertido_por_proyecto': totalProjectRaised / projects.length,
      };
    }

    if (users != null && users.isNotEmpty) {
      final totalBalance = users.fold<double>(
        0,
        (sum, user) => sum + user.saldo,
      );

      final activeUsers = users.where((u) => u.activo).length;

      final usersByPerfil = <String, int>{};
      for (final user in users) {
        final perfil = User.perfilToString(user.perfil);
        usersByPerfil[perfil] = (usersByPerfil[perfil] ?? 0) + 1;
      }

      summary['usuarios'] = {
        'total': users.length,
        'activos': activeUsers,
        'inactivos': users.length - activeUsers,
        'saldo_total': totalBalance,
        'saldo_promedio': totalBalance / users.length,
        'por_perfil': usersByPerfil,
      };
    }

    return summary;
  }
}