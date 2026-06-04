import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user.dart';

/// State class for hamburger menu
class HamburgerMenuState {
  final bool isOpen;
  final bool isEnabled;
  final User? currentUser;

  const HamburgerMenuState({
    this.isOpen = false,
    this.isEnabled = true,
    this.currentUser,
  });

  HamburgerMenuState copyWith({
    bool? isOpen,
    bool? isEnabled,
    User? currentUser,
  }) {
    return HamburgerMenuState(
      isOpen: isOpen ?? this.isOpen,
      isEnabled: isEnabled ?? this.isEnabled,
      currentUser: currentUser ?? this.currentUser,
    );
  }
}

/// Notifier for hamburger menu state
class HamburgerMenuNotifier extends StateNotifier<HamburgerMenuState> {
  HamburgerMenuNotifier() : super(const HamburgerMenuState());

  /// Toggle menu open/closed state
  void toggleMenu() {
    if (!state.isEnabled) return;
    state = state.copyWith(isOpen: !state.isOpen);
  }

  /// Open the menu
  void openMenu() {
    if (!state.isEnabled) return;
    state = state.copyWith(isOpen: true);
  }

  /// Close the menu
  void closeMenu() {
    state = state.copyWith(isOpen: false);
  }

  /// Enable or disable the menu (admin control)
  void setMenuEnabled(bool enabled) {
    state = state.copyWith(isEnabled: enabled);
  }

  /// Update current user
  void updateUser(User? user) {
    state = state.copyWith(currentUser: user);
  }
}

/// Provider for hamburger menu state management
final hamburgerMenuProvider = StateNotifierProvider<HamburgerMenuNotifier, HamburgerMenuState>(
  (ref) => HamburgerMenuNotifier(),
);

/// Provider for checking if menu should be shown based on admin settings
final menuVisibilityProvider = Provider<bool>((ref) {
  // In a real app, this could come from admin settings or remote config
  // For now, we use the enabled state
  return ref.watch(hamburgerMenuProvider).isEnabled;
});

/// Provider to check if current user can access menu
final menuAccessProvider = Provider<bool>((ref) {
  final menuState = ref.watch(hamburgerMenuProvider);
  // Menu is available if enabled and user is authenticated
  return menuState.isEnabled && menuState.currentUser != null;
});
