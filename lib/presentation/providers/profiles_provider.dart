import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/profile.dart';

/// Provider for the list of all profiles
final profilesProvider = StateNotifierProvider<ProfilesNotifier, List<Profile>>(
  (ref) => ProfilesNotifier(),
);

/// Notifier for managing profiles state
class ProfilesNotifier extends StateNotifier<List<Profile>> {
  ProfilesNotifier() : super(_getInitialProfiles());

  /// Gets the initial list of predefined profiles
  static List<Profile> _getInitialProfiles() {
    return const [
      Profile(
        id: 'admin',
        displayName: 'Admin',
        initialBalance: 0,
        canCreate: true,
        canEdit: true,
        canDelete: true,
        canInvest: false,
        isActive: true,
        color: '#EF4444',
        description: 'Administrador del sistema con acceso completo',
      ),
      Profile(
        id: 'student',
        displayName: 'Alumno',
        initialBalance: 1000000,
        canCreate: false,
        canEdit: false,
        canDelete: false,
        canInvest: true,
        isActive: true,
        color: '#00D4AA',
        description: 'Estudiante del programa MBA',
      ),
      Profile(
        id: 'teacher',
        displayName: 'Docente',
        initialBalance: 4000000,
        canCreate: false,
        canEdit: false,
        canDelete: false,
        canInvest: true,
        isActive: true,
        color: '#007AFF',
        description: 'Profesor del programa MBA',
      ),
      Profile(
        id: 'employee',
        displayName: 'Administrativo',
        initialBalance: 6000000,
        canCreate: false,
        canEdit: false,
        canDelete: false,
        canInvest: true,
        isActive: true,
        color: '#FFB800',
        description: 'Personal administrativo',
      ),
      Profile(
        id: 'guest',
        displayName: 'Invitado',
        initialBalance: 2000000,
        canCreate: false,
        canEdit: false,
        canDelete: false,
        canInvest: true,
        isActive: true,
        color: '#A78BFA',
        description: 'Invitado especial al evento',
      ),
      Profile(
        id: 'investor',
        displayName: 'Inversionista',
        initialBalance: 10000000,
        canCreate: false,
        canEdit: false,
        canDelete: false,
        canInvest: true,
        isActive: true,
        color: '#10B981',
        description: 'Inversionista profesional',
      ),
    ];
  }

  /// Updates an existing profile
  void updateProfile(Profile updatedProfile) {
    state = state
        .map((profile) => profile.id == updatedProfile.id ? updatedProfile : profile)
        .toList();
  }

  /// Updates the initial balance for a specific profile
  void updateInitialBalance(String profileId, double newBalance) {
    final index = state.indexWhere((p) => p.id == profileId);
    if (index != -1) {
      state[index] = state[index].copyWith(initialBalance: newBalance);
      state = [...state]; // Trigger update
    }
  }

  /// Updates permissions for a specific profile
  void updatePermissions({
    required String profileId,
    bool? canCreate,
    bool? canEdit,
    bool? canDelete,
    bool? canInvest,
  }) {
    final index = state.indexWhere((p) => p.id == profileId);
    if (index != -1) {
      state[index] = state[index].copyWith(
        canCreate: canCreate ?? state[index].canCreate,
        canEdit: canEdit ?? state[index].canEdit,
        canDelete: canDelete ?? state[index].canDelete,
        canInvest: canInvest ?? state[index].canInvest,
      );
      state = [...state]; // Trigger update
    }
  }

  /// Toggles the active status of a profile
  void toggleProfileActive(String profileId) {
    final index = state.indexWhere((p) => p.id == profileId);
    if (index != -1) {
      state[index] = state[index].copyWith(isActive: !state[index].isActive);
      state = [...state]; // Trigger update
    }
  }

  /// Updates the color of a profile
  void updateProfileColor(String profileId, String newColor) {
    final index = state.indexWhere((p) => p.id == profileId);
    if (index != -1) {
      state[index] = state[index].copyWith(color: newColor);
      state = [...state]; // Trigger update
    }
  }

  /// Updates the description of a profile
  void updateProfileDescription(String profileId, String newDescription) {
    final index = state.indexWhere((p) => p.id == profileId);
    if (index != -1) {
      state[index] = state[index].copyWith(description: newDescription);
      state = [...state]; // Trigger update
    }
  }

  /// Gets a profile by ID
  Profile? getProfileById(String profileId) {
    try {
      return state.firstWhere((p) => p.id == profileId);
    } catch (e) {
      return null;
    }
  }

  /// Gets the initial balance for a specific profile ID
  double getInitialBalance(String profileId) {
    final profile = getProfileById(profileId);
    return profile?.initialBalance ?? 1000000;
  }

  /// Resets all profiles to their default values
  void resetToDefaults() {
    state = _getInitialProfiles();
  }
}

/// Provider for active profiles only
final activeProfilesProvider = Provider<List<Profile>>((ref) {
  final profiles = ref.watch(profilesProvider);
  return profiles.where((profile) => profile.isActive).toList();
});

/// Provider for getting initial balance by profile ID
final initialBalanceProvider = Provider.family<double, String>((ref, profileId) {
  final profilesNotifier = ref.watch(profilesProvider.notifier);
  return profilesNotifier.getInitialBalance(profileId);
});
