import 'package:equatable/equatable.dart';

class Validators {
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'El usuario es requerido';
    }
    if (value.length < 3) {
      return 'El usuario debe tener al menos 3 caracteres';
    }
    if (value.length > 20) {
      return 'El usuario no puede exceder 20 caracteres';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Solo se permiten letras, números y guiones bajos';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El correo es requerido';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Ingresa un correo válido';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    if (value.length > 50) {
      return 'La contraseña no puede exceder 50 caracteres';
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'El nombre es requerido';
    }
    if (value.length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }
    if (value.length > 50) {
      return 'El nombre no puede exceder 50 caracteres';
    }
    return null;
  }

  static String? validateAmount(String? value, {double? min, double? max}) {
    if (value == null || value.isEmpty) {
      return 'El monto es requerido';
    }
    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Ingresa un monto válido';
    }
    if (amount <= 0) {
      return 'El monto debe ser mayor a 0';
    }
    if (min != null && amount < min) {
      return 'El monto mínimo es $min';
    }
    if (max != null && amount > max) {
      return 'El monto máximo es $max';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName es requerido';
    }
    return null;
  }

  static bool isValidUsername(String username) {
    return validateUsername(username) == null;
  }

  static bool isValidEmail(String email) {
    return validateEmail(email) == null;
  }

  static bool isValidPassword(String password) {
    return validatePassword(password) == null;
  }

  static bool isValidName(String name) {
    return validateName(name) == null;
  }

  static bool isValidAmount(String amount, {double? min, double? max}) {
    return validateAmount(amount, min: min, max: max) == null;
  }
}

class ValidationResult extends Equatable {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult({
    required this.isValid,
    this.errorMessage,
  });

  factory ValidationResult.success() {
    return const ValidationResult(isValid: true);
  }

  factory ValidationResult.failure(String message) {
    return ValidationResult(
      isValid: false,
      errorMessage: message,
    );
  }

  @override
  List<Object?> get props => [isValid, errorMessage];
}
