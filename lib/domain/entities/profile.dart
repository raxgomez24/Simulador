import 'package:equatable/equatable.dart';

/// Entity representing a user profile/role in the system
class Profile extends Equatable {
  final String id;
  final String displayName;
  final double initialBalance;
  final bool canCreate;
  final bool canEdit;
  final bool canDelete;
  final bool canInvest;
  final bool isActive;
  final String color;
  final String? description;

  const Profile({
    required this.id,
    required this.displayName,
    required this.initialBalance,
    required this.canCreate,
    required this.canEdit,
    required this.canDelete,
    required this.canInvest,
    required this.isActive,
    required this.color,
    this.description,
  });

  /// Creates a copy of this profile with modified fields
  Profile copyWith({
    String? id,
    String? displayName,
    double? initialBalance,
    bool? canCreate,
    bool? canEdit,
    bool? canDelete,
    bool? canInvest,
    bool? isActive,
    String? color,
    String? description,
  }) {
    return Profile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      initialBalance: initialBalance ?? this.initialBalance,
      canCreate: canCreate ?? this.canCreate,
      canEdit: canEdit ?? this.canEdit,
      canDelete: canDelete ?? this.canDelete,
      canInvest: canInvest ?? this.canInvest,
      isActive: isActive ?? this.isActive,
      color: color ?? this.color,
      description: description ?? this.description,
    );
  }

  /// Checks if the profile is a system profile (cannot be deleted)
  bool get isSystemProfile => _systemProfileIds.contains(id);

  /// List of system profile IDs that cannot be deleted
  static const _systemProfileIds = {
    'admin',
    'student',
    'teacher',
    'employee',
    'guest',
    'investor',
  };

  /// Gets the display name with status indicator
  String get displayNameWithStatus => isActive ? displayName : '$displayName (Inactivo)';

  /// Gets all permissions as a map
  Map<String, bool> get permissions => {
        'Crear': canCreate,
        'Editar': canEdit,
        'Eliminar': canDelete,
        'Invertir': canInvest,
      };

  /// Gets the number of active permissions
  int get activePermissionsCount {
    return permissions.values.where((perm) => perm).length;
  }

  @override
  List<Object?> get props => [
        id,
        displayName,
        initialBalance,
        canCreate,
        canEdit,
        canDelete,
        canInvest,
        isActive,
        color,
        description,
      ];
}
