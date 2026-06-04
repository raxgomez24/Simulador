import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/hamburger_menu_provider.dart';

/// Hamburger menu button widget that triggers the menu
class HamburgerMenuButton extends ConsumerWidget {
  const HamburgerMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuState = ref.watch(hamburgerMenuProvider);
    final isVisible = ref.watch(menuAccessProvider);

    if (!isVisible) {
      return const SizedBox.shrink();
    }

    return IconButton(
      icon: AnimatedIcon(
        icon: AnimatedIcons.menu_close,
        progress: menuState.isOpen ? const AlwaysStoppedAnimation(1.0) : const AlwaysStoppedAnimation(0.0),
        color: AppColors.textPrimary,
        size: 28,
      ),
      onPressed: () {
        ref.read(hamburgerMenuProvider.notifier).toggleMenu();
      },
      tooltip: menuState.isOpen ? 'Cerrar menú' : 'Abrir menú',
    );
  }
}
