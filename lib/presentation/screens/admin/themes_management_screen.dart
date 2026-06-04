import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/theme.dart';
import '../../providers/themes_provider.dart';
import '../../widgets/admin/theme_form_dialog.dart';
import '../../widgets/admin/theme_delete_dialog.dart';
import '../../widgets/admin/theme_info_dialog.dart';

class ThemesManagementScreen extends ConsumerStatefulWidget {
  const ThemesManagementScreen({super.key});

  @override
  ConsumerState<ThemesManagementScreen> createState() => _ThemesManagementScreenState();
}

class _ThemesManagementScreenState extends ConsumerState<ThemesManagementScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isGridView = true;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _showCreateThemeDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const ThemeFormDialog(),
    );
    if (result == true) {
      // Limpiar filtros después de crear
      ref.read(searchQueryThemesProvider.notifier).state = '';
      ref.read(activeFilterProvider.notifier).state = null;
    }
  }

  Future<void> _showEditThemeDialog(InvestmentTheme theme) async {
    await showDialog<bool>(
      context: context,
      builder: (context) => ThemeFormDialog(theme: theme),
    );
  }

  Future<void> _showDeleteThemeDialog(InvestmentTheme theme) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ThemeDeleteDialog(theme: theme),
    );

    if (confirmed == true) {
      // La acción se maneja dentro del diálogo
    }
  }

  void _showThemeInfoDialog(InvestmentTheme theme) {
    showDialog(
      context: context,
      builder: (context) => ThemeInfoDialog(theme: theme),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themesAsync = ref.watch(themesManagementProvider);
    final filteredThemes = ref.watch(filteredThemesProvider);
    final searchQuery = ref.watch(searchQueryThemesProvider);
    final activeFilter = ref.watch(activeFilterProvider);

    return Column(
      children: [
        // Back button header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.secondaryBackground,
            border: Border(
              bottom: BorderSide(color: AppColors.borderLight, width: 1),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_ios),
                tooltip: 'Volver',
              ),
              const SizedBox(width: 8),
              const Text(
                'Gestión de Temas',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        // Barra de búsqueda y filtros
        _buildSearchAndFilters(searchQuery, activeFilter, filteredThemes),

        // Lista de temas
        Expanded(
          child: themesAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar temas',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: const TextStyle(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.read(themesManagementProvider.notifier).refresh(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryAccent,
                    ),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
            data: (themes) {
              if (themes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox,
                        size: 64,
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay temas creados',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Crea tu primer tema para comenzar',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _showCreateThemeDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Crear Tema'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryAccent,
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (filteredThemes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No se encontraron temas',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Intenta con otra búsqueda',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                );
              }

              if (_isGridView) {
                return _buildGridView(filteredThemes);
              } else {
                return _buildListView(filteredThemes);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters(String searchQuery, bool? activeFilter, List<InvestmentTheme> filteredThemes) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Primera fila: búsqueda y vista
          Row(
            children: [
              // Campo de búsqueda
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar temas...',
                    hintStyle: const TextStyle(color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.tertiaryBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  style: const TextStyle(color: AppColors.textPrimary),
                  onChanged: (value) {
                    ref.read(searchQueryThemesProvider.notifier).state = value;
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Botón cambiar vista
              IconButton(
                onPressed: () {
                  setState(() {
                    _isGridView = !_isGridView;
                  });
                },
                icon: Icon(
                  _isGridView ? Icons.view_list : Icons.grid_view,
                  color: AppColors.textSecondary,
                ),
                tooltip: _isGridView ? 'Vista de lista' : 'Vista de cuadrícula',
              ),
              // Botón refrescar
              IconButton(
                onPressed: () => ref.read(themesManagementProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
                tooltip: 'Refrescar',
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Segunda fila: filtros
          Row(
            children: [
              // Filtro de estado
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<bool?>(
                    value: activeFilter,
                    dropdownColor: AppColors.secondaryBackground,
                    style: const TextStyle(color: AppColors.textPrimary),
                    items: const [
                      DropdownMenuItem(
                        value: null,
                        child: Text('Todos los temas'),
                      ),
                      DropdownMenuItem(
                        value: true,
                        child: Text('Solo activos'),
                      ),
                      DropdownMenuItem(
                        value: false,
                        child: Text('Solo inactivos'),
                      ),
                    ],
                    onChanged: (value) {
                      ref.read(activeFilterProvider.notifier).state = value;
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Contador
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.tertiaryBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${filteredThemes.length} temas',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(List<InvestmentTheme> themes) {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: themes.length,
      itemBuilder: (context, index) {
        return _buildThemeCard(themes[index]);
      },
    );
  }

  Widget _buildListView(List<InvestmentTheme> themes) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: themes.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildThemeCard(themes[index], isList: true),
        );
      },
    );
  }

  Widget _buildThemeCard(InvestmentTheme theme, {bool isList = false}) {
    final projectCount = ref.watch(themeProjectCountProvider(theme.id));

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _hexToColor(theme.color),
          width: 3,
        ),
      ),
      child: Stack(
        children: [
          // Contenido principal
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con icono y estado
                Row(
                  children: [
                    Container(
                      width: isList ? 50 : 60,
                      height: isList ? 50 : 60,
                      decoration: BoxDecoration(
                        color: _hexToColor(theme.color).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          theme.icon,
                          style: TextStyle(fontSize: isList ? 28 : 32),
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Indicador de estado
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.activo
                            ? AppColors.success.withValues(alpha: 0.2)
                            : AppColors.error.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            theme.activo ? Icons.check_circle : Icons.cancel,
                            size: 12,
                            color: theme.activo ? AppColors.success : AppColors.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            theme.activo ? 'Activo' : 'Inactivo',
                            style: TextStyle(
                              color: theme.activo ? AppColors.success : AppColors.error,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Nombre
                Text(
                  theme.nombre,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (theme.descripcion.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    theme.descripcion,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: isList ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const Spacer(),
                // Estadísticas
                Row(
                  children: [
                    Icon(Icons.folder_open, size: 14, color: AppColors.info),
                    const SizedBox(width: 4),
                    Text(
                      '$projectCount proyectos',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.attach_money, size: 14, color: AppColors.success),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '\$${theme.totalInvertido.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Botones de acción (hover en desktop, siempre visibles en mobile)
          Positioned(
            bottom: 8,
            right: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ver info
                IconButton(
                  onPressed: () => _showThemeInfoDialog(theme),
                  icon: const Icon(Icons.info_outline, color: AppColors.info, size: 20),
                  tooltip: 'Ver detalles',
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: const EdgeInsets.all(4),
                ),
                // Editar
                IconButton(
                  onPressed: () => _showEditThemeDialog(theme),
                  icon: const Icon(Icons.edit, color: AppColors.primaryAccent, size: 20),
                  tooltip: 'Editar',
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: const EdgeInsets.all(4),
                ),
                // Eliminar
                IconButton(
                  onPressed: () => _showDeleteThemeDialog(theme),
                  icon: const Icon(Icons.delete, color: AppColors.error, size: 20),
                  tooltip: 'Eliminar',
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: const EdgeInsets.all(4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _hexToColor(String hexColor) {
    final hexCode = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }
}
