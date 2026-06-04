import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

enum AppButtonVariant {
  primary,
  secondary,
  outlined,
  text,
}

enum AppButtonSize {
  small,
  medium,
  large,
}

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final Widget? leading;
  final Widget? trailing;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
    this.icon,
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final buttonSize = _getSize();
    final buttonStyle = _getStyle(context);

    Widget child;
    if (isLoading) {
      child = SizedBox(
        width: buttonSize['iconSize'] as double,
        height: buttonSize['iconSize'] as double,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    } else if (icon != null) {
      child = Icon(icon, size: buttonSize['iconSize'] as double);
    } else {
      child = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 8),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: buttonSize['fontSize'] as double,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      );
    }

    final button = _buildButton(buttonStyle, buttonSize, child);

    return isFullWidth
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }

  Widget _buildButton(
    ButtonStyle buttonStyle,
    Map<String, double> size,
    Widget child,
  ) {
    switch (variant) {
      case AppButtonVariant.primary:
        return ElevatedButton(
          style: buttonStyle,
          onPressed: isLoading ? null : onPressed,
          child: child,
        );
      case AppButtonVariant.secondary:
        return ElevatedButton(
          style: buttonStyle,
          onPressed: isLoading ? null : onPressed,
          child: child,
        );
      case AppButtonVariant.outlined:
        return OutlinedButton(
          style: buttonStyle,
          onPressed: isLoading ? null : onPressed,
          child: child,
        );
      case AppButtonVariant.text:
        return TextButton(
          style: buttonStyle,
          onPressed: isLoading ? null : onPressed,
          child: child,
        );
    }
  }

  ButtonStyle _getStyle(BuildContext context) {
    switch (variant) {
      case AppButtonVariant.primary:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryAccent,
          foregroundColor: Colors.white,
        );
      case AppButtonVariant.secondary:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondaryAccent,
          foregroundColor: Colors.white,
        );
      case AppButtonVariant.outlined:
        return OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryAccent,
          side: const BorderSide(color: AppColors.primaryAccent, width: 2),
        );
      case AppButtonVariant.text:
        return TextButton.styleFrom(
          foregroundColor: AppColors.primaryAccent,
        );
    }
  }

  Map<String, double> _getSize() {
    switch (size) {
      case AppButtonSize.small:
        return {
          'horizontalPadding': 12.0,
          'verticalPadding': 8.0,
          'fontSize': 14.0,
          'iconSize': 16.0,
        };
      case AppButtonSize.medium:
        return {
          'horizontalPadding': 24.0,
          'verticalPadding': 16.0,
          'fontSize': 16.0,
          'iconSize': 20.0,
        };
      case AppButtonSize.large:
        return {
          'horizontalPadding': 32.0,
          'verticalPadding': 20.0,
          'fontSize': 18.0,
          'iconSize': 24.0,
        };
    }
  }
}
