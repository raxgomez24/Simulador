import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/hamburger_menu_provider.dart';
import '../../widgets/common/bottom_nav_bar.dart';
import 'menu_widgets.dart';

/// Example screen showing how to integrate the hamburger menu
/// This demonstrates the proper way to use HamburgerMenuDrawer with existing BottomNavBar
class HamburgerMenuExampleScreen extends ConsumerStatefulWidget {
  const HamburgerMenuExampleScreen({super.key});

  @override
  ConsumerState<HamburgerMenuExampleScreen> createState() => _HamburgerMenuExampleScreenState();
}

class _HamburgerMenuExampleScreenState extends ConsumerState<HamburgerMenuExampleScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize hamburger menu with current user
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authProvider);
      if (authState.value != null) {
        ref.read(hamburgerMenuProvider.notifier).updateUser(authState.value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.value;

    return HamburgerMenuDrawer(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.home),
          leading: const HamburgerMenuButton(),
          actions: [
            // You can add other actions here
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                // Handle notifications
              },
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (user != null) ...[
                Text(
                  'Bienvenido, ${user.nombre}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  'Saldo: ${user.saldo.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ] else
                const Text('No hay usuario autenticado'),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  // Example: Toggle menu programmatically
                  ref.read(hamburgerMenuProvider.notifier).toggleMenu();
                },
                child: const Text('Toggle Menú'),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const BottomNavBar(currentIndex: 0),
      ),
    );
  }
}

/// Alternative: Integration in main app structure
/// Wrap your main app widget or individual screens with HamburgerMenuDrawer
///
/// Example in app.dart or main.dart:
///
/// ```dart
/// class MyApp extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     return HamburgerMenuDrawer(
///       child: MaterialApp(
///         // ... your app configuration
///       ),
///     );
///   }
/// }
/// ```

/// Example: Admin control to enable/disable menu
/// This can be called from an admin screen
void toggleMenuAvailability(WidgetRef ref, bool enabled) {
  ref.read(hamburgerMenuProvider.notifier).setMenuEnabled(enabled);
}

/// Example: Update user in menu when logging in
void updateMenuUser(WidgetRef ref, User? user) {
  ref.read(hamburgerMenuProvider.notifier).updateUser(user);
}

/// Usage checklist for implementing hamburger menu:
///
/// 1. ✅ Import the hamburger menu widgets:
///    import 'package:your_app/presentation/widgets/menu/menu_widgets.dart';
///    import 'package:your_app/presentation/providers/hamburger_menu_provider.dart';
///
/// 2. ✅ Wrap your screen content with HamburgerMenuDrawer:
///    return HamburgerMenuDrawer(
///      child: Scaffold(
///        appBar: AppBar(
///          leading: const HamburgerMenuButton(),
///          // ... other app bar content
///        ),
///        body: YourContent(),
///        bottomNavigationBar: const BottomNavBar(currentIndex: 0),
///      ),
///    );
///
/// 3. ✅ Initialize menu with user data (in initState or didChangeDependencies):
///    WidgetsBinding.instance.addPostFrameCallback((_) {
///      final user = ref.read(authProvider).value;
///      ref.read(hamburgerMenuProvider.notifier).updateUser(user);
///    });
///
/// 4. ✅ The menu automatically integrates with existing BottomNavBar
///    - BottomNavBar remains visible and functional
///    - Menu appears as an overlay when triggered
///    - Both navigation methods coexist
///
/// 5. ✅ Admin control (optional):
///    ref.read(hamburgerMenuProvider.notifier).setMenuEnabled(false); // Disable
///    ref.read(hamburgerMenuProvider.notifier).setMenuEnabled(true);  // Enable
///
/// 6. ✅ Programmatic control (optional):
///    ref.read(hamburgerMenuProvider.notifier).openMenu();
///    ref.read(hamburgerMenuProvider.notifier).closeMenu();
///    ref.read(hamburgerMenuProvider.notifier).toggleMenu();
