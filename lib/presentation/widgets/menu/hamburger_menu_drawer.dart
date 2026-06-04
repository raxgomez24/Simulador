import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../presentation/providers/hamburger_menu_provider.dart';
import 'hamburger_menu_header.dart';
import 'hamburger_menu_footer.dart';
import 'hamburger_menu_item.dart';

/// Main hamburger menu drawer with animations
class HamburgerMenuDrawer extends ConsumerStatefulWidget {
  final Widget child;

  const HamburgerMenuDrawer({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<HamburgerMenuDrawer> createState() => _HamburgerMenuDrawerState();
}

class _HamburgerMenuDrawerState extends ConsumerState<HamburgerMenuDrawer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleMenuItemTap(String route) {
    // Close menu
    ref.read(hamburgerMenuProvider.notifier).closeMenu();

    // Navigate if route is different from current
    if (ModalRoute.of(context)?.settings.name != route) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        route,
        (route) => false,
      );
    }
  }

  void _handleLogout() {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondaryBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Cerrar Sesión',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          '¿Estás seguro de que deseas cerrar sesión?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Close menu first
              ref.read(hamburgerMenuProvider.notifier).closeMenu();
              // Navigate to login and clear all routes
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  List<MenuItemData> _getMenuItems(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;

    return [
      // Main Navigation Section
      MenuItemData(
        icon: Icons.home,
        label: AppStrings.home,
        route: '/',
        isSelected: currentRoute == '/',
      ),
      MenuItemData(
        icon: Icons.category,
        label: 'Temas/Categorías',
        route: '/themes',
        isSelected: currentRoute == '/themes',
      ),
      MenuItemData(
        icon: Icons.account_balance_wallet,
        label: 'Mis Inversiones',
        route: '/investments',
        isSelected: currentRoute == '/investments',
      ),
      MenuItemData(
        icon: Icons.leaderboard,
        label: 'Ranking',
        route: '/ranking',
        isSelected: currentRoute == '/ranking',
      ),

      // User Section Divider
      const MenuItemData(isDivider: true),

      // User Management Section
      MenuItemData(
        icon: Icons.person,
        label: 'Perfil',
        route: '/profile',
        isSelected: currentRoute == '/profile',
      ),
      MenuItemData(
        icon: Icons.history,
        label: 'Historial de Inversiones',
        route: '/investment-history',
        isSelected: currentRoute == '/investment-history',
      ),

      // Support Section Divider
      const MenuItemData(isDivider: true),

      // Support Section
      MenuItemData(
        icon: Icons.help_outline,
        label: 'Ayuda/Instrucciones',
        route: '/help',
        isSelected: currentRoute == '/help',
      ),

      // Actions Section Divider
      const MenuItemData(isDivider: true),

      // Actions Section
      const MenuItemData(
        icon: Icons.logout,
        label: 'Cerrar Sesión',
        isDanger: true,
        isAction: true,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final menuState = ref.watch(hamburgerMenuProvider);
    final menuItems = _getMenuItems(context);

    // Update animation based on menu state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (menuState.isOpen && _animationController.status == AnimationStatus.dismissed) {
        _animationController.forward();
      } else if (!menuState.isOpen && _animationController.status == AnimationStatus.completed) {
        _animationController.reverse();
      }
    });

    return Stack(
      children: [
        // Main content
        widget.child,

        // Overlay
        AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return GestureDetector(
              onTap: () {
                if (menuState.isOpen) {
                  ref.read(hamburgerMenuProvider.notifier).closeMenu();
                }
              },
              child: Container(
                color: AppColors.overlay.withOpacity(_fadeAnimation.value * 0.5),
                child: menuState.isOpen
                    ? const SizedBox.expand()
                    : const SizedBox.shrink(),
              ),
            );
          },
        ),

        // Menu drawer
        AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_slideAnimation.value * MediaQuery.of(context).size.width * 0.75, 0),
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: child,
              ),
            );
          },
          child: GestureDetector(
            onHorizontalDragEnd: (details) {
              // Swipe to close
              if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
                ref.read(hamburgerMenuProvider.notifier).closeMenu();
              }
            },
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.75,
              height: MediaQuery.of(context).size.height,
              child: Drawer(
                backgroundColor: AppColors.primaryBackground,
                child: Column(
                  children: [
                    // Header
                    const HamburgerMenuHeader(),

                    // Menu items
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: menuItems.length,
                        itemBuilder: (context, index) {
                          final item = menuItems[index];

                          // Handle divider items
                          if (item.isDivider) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Divider(
                                color: AppColors.textSecondary.withOpacity(0.2),
                                thickness: 1,
                              ),
                            );
                          }

                          // Handle action items (logout)
                          if (item.isAction) {
                            return HamburgerMenuItem(
                              icon: item.icon,
                              label: item.label,
                              onTap: _handleLogout,
                              isDanger: item.isDanger,
                              index: index,
                              totalItems: menuItems.length,
                            );
                          }

                          // Handle regular navigation items
                          return HamburgerMenuItem(
                            icon: item.icon,
                            label: item.label,
                            onTap: () => _handleMenuItemTap(item.route ?? '/'),
                            isSelected: item.isSelected,
                            index: index,
                            totalItems: menuItems.length,
                          );
                        },
                      ),
                    ),

                    // Footer
                    const HamburgerMenuFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Data class for menu items
class MenuItemData {
  final IconData icon;
  final String label;
  final String? route;
  final bool isSelected;
  final bool isDanger;
  final bool isAction;
  final bool isDivider;

  const MenuItemData({
    this.icon = Icons.menu,
    this.label = '',
    this.route,
    this.isSelected = false,
    this.isDanger = false,
    this.isAction = false,
    this.isDivider = false,
  });
}
