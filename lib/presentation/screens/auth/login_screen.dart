import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/network_utils.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_input.dart';
import '../home/home_screen.dart';
import 'package:amerike_investment_sim/data/database/database_seeder.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isGuestMode = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref.read(authProvider.notifier).login(
            _usernameController.text.trim(),
            _passwordController.text,
          );

      final authState = ref.read(authProvider);
      if (authState.hasError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_getErrorMessage(authState.error)),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      final user = authState.value;
      if (user != null && mounted) {
        if (user.isAdmin) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.admin);
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const HomeScreen(),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getErrorMessage(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error == null) {
      return AppStrings.error;
    }

    final errorString = error.toString();

    if (errorString.contains('Usuario o contraseña incorrectos') ||
        errorString.contains('INVALID_CREDENTIALS')) {
      return 'Usuario o contraseña incorrectos';
    }

    if (errorString.contains('inactivo') || errorString.contains('USER_INACTIVE')) {
      return 'El usuario está inactivo';
    }

    if (errorString.contains('no existe') || errorString.contains('USER_NOT_FOUND')) {
      return 'El usuario no existe';
    }

    if (errorString.contains('AuthenticationException')) {
      return 'Error de autenticación. Verifica tus credenciales.';
    }

    return errorString;
  }

  Future<void> _handleGuestRegister() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref.read(authProvider.notifier).registerAsGuest(
            _usernameController.text.trim(),
            _usernameController.text.trim(),
          );

      final authState = ref.read(authProvider);
      if (authState.hasError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_getErrorMessage(authState.error)),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      final user = authState.value;
      if (user != null && mounted) {
        if (user.isAdmin) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.admin);
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const HomeScreen(),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getErrorMessage(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryBackground,
              AppColors.secondaryBackground,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo/Title
                      _buildHeader(),

                      const SizedBox(height: 48),

                      // Username Input
                      AppInput(
                        label: AppStrings.username,
                        hint: AppStrings.usernameHint,
                        controller: _usernameController,
                        prefixIcon: const Icon(Icons.person_outline),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppStrings.required;
                          }
                          if (value.length < 3) {
                            return AppStrings.usernameTooShort;
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Password Input (only in login mode)
                      if (!_isGuestMode) ...[
                        AppPasswordInput(
                          label: AppStrings.password,
                          hint: AppStrings.passwordHint,
                          controller: _passwordController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppStrings.required;
                            }
                            if (value.length < 6) {
                              return AppStrings.shortPassword;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                      ],

                      const SizedBox(height: 24),

                      // Mode Toggle
                      _buildModeToggle(),

                      const SizedBox(height: 24),

                      // Submit Button
                      AppButton(
                        text: _isGuestMode
                            ? AppStrings.guestRegister
                            : AppStrings.login,
                        onPressed: _isGuestMode ? _handleGuestRegister : _handleLogin,
                        isLoading: isLoading,
                        isFullWidth: true,
                        icon: _isGuestMode ? Icons.person_add : Icons.login,
                      ),

                      const SizedBox(height: 16),

                      // Connection Status
                      _buildConnectionStatus(),

                      // Diagnostics button (hidden, long press to show)
                      GestureDetector(
                        onLongPress: () => _runDiagnostics(context),
                        child: const SizedBox(
                          height: 40,
                          child: Center(
                            child: Text(
                              'v1.0',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo Placeholder
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryAccent, AppColors.secondaryAccent],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryAccent.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.trending_up,
            size: 50,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          AppStrings.appName,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.appTitle,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  Widget _buildModeToggle() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _isGuestMode = false),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: !_isGuestMode
                    ? AppColors.primaryAccent
                    : AppColors.tertiaryBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                AppStrings.login,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: !_isGuestMode ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _isGuestMode = true),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _isGuestMode
                    ? AppColors.primaryAccent
                    : AppColors.tertiaryBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                AppStrings.guestRegister,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _isGuestMode ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionStatus() {
    return FutureBuilder<Map<String, String>>(
      future: NetworkUtils.getConnectionInfo(),
      builder: (context, snapshot) {
        final url = snapshot.data?['url'] ?? 'Detectando IP...';

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.tertiaryBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Servidor Activo',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.devices,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Conéctate desde otros dispositivos: $url',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _runDiagnostics(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        backgroundColor: AppColors.secondaryBackground,
        title: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryAccent,
              ),
            ),
            const SizedBox(width: 16),
            Text('Diagnosticando base de datos...'),
          ],
        ),
      ),
    );

    try {
      final seeder = DatabaseSeeder();
      final diagnosis = await seeder.diagnose();

      if (!context.mounted) return;

      Navigator.of(context).pop();

      final userExists = diagnosis['testUserFound'] == true;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.secondaryBackground,
          title: const Text('Diagnóstico de Base de Datos'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Tablas: ${diagnosis['tables']}'),
                const SizedBox(height: 8),
                Text('Registros: ${diagnosis['recordCounts']}'),
                const SizedBox(height: 8),
                Text('Usuario prueba existe: $userExists'),
                const SizedBox(height: 8),
                Text('Seeding necesario: ${diagnosis['seedingNeeded']}'),
                if (!userExists) ...[
                  const SizedBox(height: 16),
                  const Text('El usuario de prueba no existe. Puedes intentar reiniciar la base de datos.'),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
            if (!userExists)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _resetDatabase(context);
                },
                child: const Text(
                  'Reiniciar DB',
                  style: TextStyle(color: AppColors.warning),
                ),
              ),
          ],
        ),
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.secondaryBackground,
            title: const Text('Error de Diagnóstico'),
            content: Text('Error: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _resetDatabase(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        backgroundColor: AppColors.secondaryBackground,
        title: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryAccent,
              ),
            ),
            SizedBox(width: 16),
            Text('Reiniciando base de datos...'),
          ],
        ),
      ),
    );

    try {
      final seeder = DatabaseSeeder();
      seeder.resetDatabase().then((_) {
        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Base de datos reiniciada exitosamente'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      });
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al reiniciar: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
