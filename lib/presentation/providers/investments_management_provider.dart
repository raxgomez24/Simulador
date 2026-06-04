import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/investment.dart';
import '../../domain/entities/session.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/investment_repository.dart';
import '../../data/repositories/investment_repository_impl.dart';
import '../../data/repositories/investment_repository_local.dart';
import '../../data/datasources/remote/websocket_datasource.dart';
import '../../app/config.dart';
import 'admin_provider.dart';
import 'session_provider.dart';

final webSocketDataSourceProvider = Provider<WebSocketDataSource>((ref) {
  return WebSocketDataSource();
});

// Estado para la gestión de inversiones
class InvestmentsManagementState {
  final List<Investment> investments;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final UserRole? selectedPerfil;
  final InvestmentStatus? selectedEstado;
  final DateTime? startDate;
  final DateTime? endDate;
  final int currentPage;
  final int itemsPerPage;
  final bool showStatistics;

  const InvestmentsManagementState({
    this.investments = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.selectedPerfil,
    this.selectedEstado,
    this.startDate,
    this.endDate,
    this.currentPage = 1,
    this.itemsPerPage = 50,
    this.showStatistics = false,
  });

  List<Investment> get filteredInvestments {
    var filtered = investments.toList();

    // Filtro de búsqueda
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((inv) {
        return inv.usuarioNombre.toLowerCase().contains(query) ||
            inv.proyectoNombre.toLowerCase().contains(query) ||
            inv.temaNombre.toLowerCase().contains(query);
      }).toList();
    }

    // Filtro por perfil
    if (selectedPerfil != null) {
      filtered = filtered.where((inv) => inv.perfil == selectedPerfil).toList();
    }

    // Filtro por estado
    if (selectedEstado != null) {
      filtered = filtered.where((inv) => inv.estado == selectedEstado).toList();
    }

    // Filtro por fecha
    if (startDate != null) {
      filtered = filtered.where((inv) => inv.fechaHora.isAfter(startDate!)).toList();
    }

    if (endDate != null) {
      final endDateTime = endDate!.add(const Duration(days: 1));
      filtered = filtered.where((inv) => inv.fechaHora.isBefore(endDateTime)).toList();
    }

    return filtered;
  }

  List<Investment> get paginatedInvestments {
    final start = (currentPage - 1) * itemsPerPage;
    final end = start + itemsPerPage;
    final filtered = filteredInvestments;

    if (start >= filtered.length) return [];
    return filtered.sublist(start, end > filtered.length ? filtered.length : end);
  }

  int get totalPages => (filteredInvestments.length / itemsPerPage).ceil();

  InvestmentsManagementState copyWith({
    List<Investment>? investments,
    bool? isLoading,
    String? error,
    String? searchQuery,
    UserRole? selectedPerfil,
    InvestmentStatus? selectedEstado,
    DateTime? startDate,
    DateTime? endDate,
    int? currentPage,
    int? itemsPerPage,
    bool? showStatistics,
    bool clearSelectedPerfil = false,
    bool clearSelectedEstado = false,
    bool clearStartDate = false,
    bool clearEndDate = false,
  }) {
    return InvestmentsManagementState(
      investments: investments ?? this.investments,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedPerfil: clearSelectedPerfil ? null : (selectedPerfil ?? this.selectedPerfil),
      selectedEstado: clearSelectedEstado ? null : (selectedEstado ?? this.selectedEstado),
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      currentPage: currentPage ?? this.currentPage,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
      showStatistics: showStatistics ?? this.showStatistics,
    );
  }
}

// Provider para el repositorio de inversiones
final investmentRepositoryProvider = Provider<InvestmentRepository>((ref) {
  // En web, no usar repositorio local (no SQLite disponible)
  if (AppConfig.isWeb || !AppConfig.useLocalData) {
    final dataSource = ref.read(webSocketDataSourceProvider);
    return InvestmentRepositoryImpl(dataSource);
  } else {
    return InvestmentRepositoryLocal();
  }
});

// Provider para el estado de gestión de inversiones
final investmentsManagementProvider =
    StateNotifierProvider<InvestmentsManagementNotifier, InvestmentsManagementState>((ref) {
  final repository = ref.read(investmentRepositoryProvider);
  final adminActions = ref.read(adminActionsProvider);
  return InvestmentsManagementNotifier(repository, adminActions, ref);
});

class InvestmentsManagementNotifier extends StateNotifier<InvestmentsManagementState> {
  final InvestmentRepository _repository;
  final AdminActions _adminActions;
  final Ref _ref;

  InvestmentsManagementNotifier(this._repository, this._adminActions, this._ref)
      : super(const InvestmentsManagementState()) {
    _loadInvestments();
  }

  Future<void> _loadInvestments() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final investments = await _repository.getAllInvestments();
      state = state.copyWith(
        investments: investments,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    await _loadInvestments();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query, currentPage: 1);
  }

  void setSelectedPerfil(UserRole? perfil) {
    state = state.copyWith(selectedPerfil: perfil, currentPage: 1);
  }

  void clearSelectedPerfil() {
    state = state.copyWith(clearSelectedPerfil: true, currentPage: 1);
  }

  void setSelectedEstado(InvestmentStatus? estado) {
    state = state.copyWith(selectedEstado: estado, currentPage: 1);
  }

  void clearSelectedEstado() {
    state = state.copyWith(clearSelectedEstado: true, currentPage: 1);
  }

  void setDateRange(DateTime? start, DateTime? end) {
    state = state.copyWith(startDate: start, endDate: end, currentPage: 1);
  }

  void clearDateRange() {
    state = state.copyWith(clearStartDate: true, clearEndDate: true, currentPage: 1);
  }

  void setCurrentPage(int page) {
    if (page >= 1 && page <= state.totalPages) {
      state = state.copyWith(currentPage: page);
    }
  }

  void toggleStatistics() {
    state = state.copyWith(showStatistics: !state.showStatistics);
  }

  Future<void> cancelInvestment(String investmentId, String motivo) async {
    try {
      if (AppConfig.useLocalData) {
        // En modo local, marcamos la inversión como cancelada
        await _repository.updateInvestment(
          id: investmentId,
          estado: 'cancelada',
          observaciones: 'Cancelada: $motivo',
        );
      } else {
        // En modo remoto, usamos WebSocket
        await _adminActions.cancelInvestment(investmentId, motivo);
      }
      // Refresh investments after cancellation
      await refresh();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteInvestment(String investmentId) async {
    try {
      if (AppConfig.useLocalData) {
        // En modo local, usamos el repository directo
        await _repository.deleteInvestment(investmentId);
      } else {
        // En modo remoto, usamos WebSocket
        await _adminActions.deleteInvestment(investmentId);
      }
      // Refresh investments after deletion
      await refresh();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> createManualInvestment({
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
  }) async {
    try {
      // Obtener el estado actual de la sesión para validación
      final sessionState = _ref.read(sessionProvider).value?.estado;

      if (AppConfig.useLocalData) {
        // En modo local, usamos el repository directo
        await _repository.createInvestment(
          usuarioId: usuarioId,
          usuarioNombre: usuarioNombre,
          perfil: perfil,
          proyectoId: proyectoId,
          proyectoNombre: proyectoNombre,
          temaId: temaId,
          temaNombre: temaNombre,
          temaColor: temaColor,
          monto: monto,
          observaciones: observaciones,
          sessionState: sessionState,
        );
      } else {
        // En modo remoto, usamos WebSocket
        await _adminActions.createManualInvestment(
          usuarioId: usuarioId,
          usuarioNombre: usuarioNombre,
          perfil: perfil,
          proyectoId: proyectoId,
          proyectoNombre: proyectoNombre,
          temaId: temaId,
          temaNombre: temaNombre,
          temaColor: temaColor,
          monto: monto,
          observaciones: observaciones,
        );
      }
      // Refresh investments after creation
      await refresh();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> editInvestment({
    required String id,
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
  }) async {
    try {
      if (AppConfig.useLocalData) {
        // En modo local, usamos el repository directo
        await _repository.updateInvestment(
          id: id,
          usuarioId: usuarioId,
          usuarioNombre: usuarioNombre,
          perfil: perfil,
          proyectoId: proyectoId,
          proyectoNombre: proyectoNombre,
          temaId: temaId,
          temaNombre: temaNombre,
          temaColor: temaColor,
          monto: monto,
          observaciones: observaciones,
        );
      } else {
        // En modo remoto, usamos WebSocket
        await _adminActions.editInvestment(
          id: id,
          usuarioId: usuarioId,
          usuarioNombre: usuarioNombre,
          perfil: perfil,
          proyectoId: proyectoId,
          proyectoNombre: proyectoNombre,
          temaId: temaId,
          temaNombre: temaNombre,
          temaColor: temaColor,
          monto: monto,
          observaciones: observaciones,
        );
      }
      // Refresh investments after editing
      await refresh();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider para estadísticas de inversiones
final investmentsStatisticsProvider =
    Provider<InvestmentsStatistics>((ref) {
      final state = ref.watch(investmentsManagementProvider);
      final investments = state.filteredInvestments;

      return InvestmentsStatistics.fromInvestments(investments);
    });

class InvestmentsStatistics {
  final int totalInvestments;
  final double totalAmount;
  final double averageAmount;
  final double highestInvestment;
  final double lowestInvestment;
  final Map<UserRole, int> investmentsByProfile;
  final Map<String, int> investmentsByTheme;
  final Map<DateTime, int> investmentsByDate;
  final List<UserInvestmentStats> topUsers;
  final List<ProjectInvestmentStats> topProjects;

  InvestmentsStatistics({
    required this.totalInvestments,
    required this.totalAmount,
    required this.averageAmount,
    required this.highestInvestment,
    required this.lowestInvestment,
    required this.investmentsByProfile,
    required this.investmentsByTheme,
    required this.investmentsByDate,
    required this.topUsers,
    required this.topProjects,
  });

  factory InvestmentsStatistics.fromInvestments(List<Investment> investments) {
    if (investments.isEmpty) {
      return InvestmentsStatistics(
        totalInvestments: 0,
        totalAmount: 0,
        averageAmount: 0,
        highestInvestment: 0,
        lowestInvestment: 0,
        investmentsByProfile: {},
        investmentsByTheme: {},
        investmentsByDate: {},
        topUsers: [],
        topProjects: [],
      );
    }

    final totalAmount = investments.fold<double>(0, (sum, inv) => sum + inv.monto);
    final averageAmount = totalAmount / investments.length;
    final amounts = investments.map((inv) => inv.monto).toList();
    amounts.sort();
    final highestInvestment = amounts.last;
    final lowestInvestment = amounts.first;

    // Inversiones por perfil
    final investmentsByProfile = <UserRole, int>{};
    for (final inv in investments) {
      investmentsByProfile[inv.perfil] = (investmentsByProfile[inv.perfil] ?? 0) + 1;
    }

    // Inversiones por tema
    final investmentsByTheme = <String, int>{};
    for (final inv in investments) {
      investmentsByTheme[inv.temaNombre] = (investmentsByTheme[inv.temaNombre] ?? 0) + 1;
    }

    // Inversiones por fecha
    final investmentsByDate = <DateTime, int>{};
    for (final inv in investments) {
      final date = DateTime(inv.fechaHora.year, inv.fechaHora.month, inv.fechaHora.day);
      investmentsByDate[date] = (investmentsByDate[date] ?? 0) + 1;
    }

    // Top 5 usuarios
    final userStats = <String, UserInvestmentStats>{};
    for (final inv in investments) {
      final key = inv.usuarioId;
      if (!userStats.containsKey(key)) {
        userStats[key] = UserInvestmentStats(
          usuarioId: inv.usuarioId,
          usuarioNombre: inv.usuarioNombre,
          perfil: inv.perfil,
          totalAmount: 0,
          investmentCount: 0,
        );
      }
      userStats[key] = userStats[key]!.copyWith(
        totalAmount: userStats[key]!.totalAmount + inv.monto,
        investmentCount: userStats[key]!.investmentCount + 1,
      );
    }

    final topUsers = userStats.values.toList()
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    final top5Users = topUsers.take(5).toList();

    // Top 5 proyectos
    final projectStats = <String, ProjectInvestmentStats>{};
    for (final inv in investments) {
      final key = inv.proyectoId;
      if (!projectStats.containsKey(key)) {
        projectStats[key] = ProjectInvestmentStats(
          proyectoId: inv.proyectoId,
          proyectoNombre: inv.proyectoNombre,
          temaNombre: inv.temaNombre,
          temaColor: inv.temaColor,
          totalAmount: 0,
          investmentCount: 0,
        );
      }
      projectStats[key] = projectStats[key]!.copyWith(
        totalAmount: projectStats[key]!.totalAmount + inv.monto,
        investmentCount: projectStats[key]!.investmentCount + 1,
      );
    }

    final topProjects = projectStats.values.toList()
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    final top5Projects = topProjects.take(5).toList();

    return InvestmentsStatistics(
      totalInvestments: investments.length,
      totalAmount: totalAmount,
      averageAmount: averageAmount,
      highestInvestment: highestInvestment,
      lowestInvestment: lowestInvestment,
      investmentsByProfile: investmentsByProfile,
      investmentsByTheme: investmentsByTheme,
      investmentsByDate: investmentsByDate,
      topUsers: top5Users,
      topProjects: top5Projects,
    );
  }
}

class UserInvestmentStats {
  final String usuarioId;
  final String usuarioNombre;
  final UserRole perfil;
  final double totalAmount;
  final int investmentCount;

  UserInvestmentStats({
    required this.usuarioId,
    required this.usuarioNombre,
    required this.perfil,
    required this.totalAmount,
    required this.investmentCount,
  });

  UserInvestmentStats copyWith({
    String? usuarioId,
    String? usuarioNombre,
    UserRole? perfil,
    double? totalAmount,
    int? investmentCount,
  }) {
    return UserInvestmentStats(
      usuarioId: usuarioId ?? this.usuarioId,
      usuarioNombre: usuarioNombre ?? this.usuarioNombre,
      perfil: perfil ?? this.perfil,
      totalAmount: totalAmount ?? this.totalAmount,
      investmentCount: investmentCount ?? this.investmentCount,
    );
  }
}

class ProjectInvestmentStats {
  final String proyectoId;
  final String proyectoNombre;
  final String temaNombre;
  final String temaColor;
  final double totalAmount;
  final int investmentCount;

  ProjectInvestmentStats({
    required this.proyectoId,
    required this.proyectoNombre,
    required this.temaNombre,
    required this.temaColor,
    required this.totalAmount,
    required this.investmentCount,
  });

  ProjectInvestmentStats copyWith({
    String? proyectoId,
    String? proyectoNombre,
    String? temaNombre,
    String? temaColor,
    double? totalAmount,
    int? investmentCount,
  }) {
    return ProjectInvestmentStats(
      proyectoId: proyectoId ?? this.proyectoId,
      proyectoNombre: proyectoNombre ?? this.proyectoNombre,
      temaNombre: temaNombre ?? this.temaNombre,
      temaColor: temaColor ?? this.temaColor,
      totalAmount: totalAmount ?? this.totalAmount,
      investmentCount: investmentCount ?? this.investmentCount,
    );
  }
}
