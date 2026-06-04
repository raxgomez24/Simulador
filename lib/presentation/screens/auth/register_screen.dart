import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_input.dart';
import '../home/home_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authProvider.notifier).registerAsGuest(
          _usernameController.text.trim(),
          _fullNameController.text.trim(),
        );

    ref.listen(authProvider, (previous, next) {
      next.when(
        data: (user) {
          if (user != null) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const HomeScreen(),
              ),
            );
          }
        },
        error: (error, stack) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.toString()),
              backgroundColor: AppColors.error,
            ),
          );
        },
        loading: () {},
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.register),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),

              // Description
              Text(
                AppStrings.guestDescription,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Username
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

              // Full Name
              AppInput(
                label: AppStrings.fullName,
                hint: AppStrings.fullNameHint,
                controller: _fullNameController,
                prefixIcon: const Icon(Icons.badge_outlined),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppStrings.required;
                  }
                  if (value.length < 2) {
                    return AppStrings.nameTooShort;
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Email (Optional)
              AppInput(
                label: '${AppStrings.email} (opcional)',
                hint: AppStrings.emailHint,
                controller: _emailController,
                prefixIcon: const Icon(Icons.email_outlined),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return AppStrings.invalidEmail;
                    }
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Register Button
              AppButton(
                text: AppStrings.guestRegister,
                onPressed: _handleRegister,
                isLoading: isLoading,
                isFullWidth: true,
                icon: Icons.person_add,
              ),

              const SizedBox(height: 16),

              // Cancel Button
              AppButton(
                text: AppStrings.cancel,
                onPressed: () => Navigator.of(context).pop(),
                variant: AppButtonVariant.outlined,
                isFullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
