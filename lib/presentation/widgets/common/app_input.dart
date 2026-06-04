import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';

class AppInput extends StatelessWidget {
  final String label;
  final String? hint;
  final String? errorText;
  final TextEditingController? controller;
  final bool obscureText;
  final bool enabled;
  final int maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final String? Function(String?)? validator;
  final AutovalidateMode autovalidateMode;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization;
  final bool readOnly;

  const AppInput({
    super.key,
    required this.label,
    this.hint,
    this.errorText,
    this.controller,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.inputFormatters,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          enabled: enabled,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          validator: validator,
          autovalidateMode: autovalidateMode,
          focusNode: focusNode,
          textCapitalization: textCapitalization,
          readOnly: readOnly,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            prefixIcon: prefixIcon != null
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: prefixIcon,
                  )
                : null,
            suffixIcon: suffixIcon != null
                ? IconButton(
                    icon: suffixIcon!,
                    onPressed: onSuffixIconPressed,
                  )
                : null,
            prefixIconConstraints: const BoxConstraints(
              minWidth: 48,
              minHeight: 48,
            ),
            counterText: maxLength != null ? null : '',
            filled: true,
            fillColor: AppColors.tertiaryBackground,
            border: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.borderLight),
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.borderLight),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primaryAccent),
              borderRadius: BorderRadius.circular(12),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.error),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.error),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

class AppPasswordInput extends StatefulWidget {
  final String label;
  final String? hint;
  final String? errorText;
  final TextEditingController? controller;
  final bool enabled;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;

  const AppPasswordInput({
    super.key,
    required this.label,
    this.hint,
    this.errorText,
    this.controller,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.focusNode,
  });

  @override
  State<AppPasswordInput> createState() => _AppPasswordInputState();
}

class _AppPasswordInputState extends State<AppPasswordInput> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return AppInput(
      label: widget.label,
      hint: widget.hint,
      errorText: widget.errorText,
      controller: widget.controller,
      obscureText: _obscureText,
      enabled: widget.enabled,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      validator: widget.validator,
      focusNode: widget.focusNode,
      suffixIcon: Icon(
        _obscureText ? Icons.visibility_off : Icons.visibility,
        color: AppColors.textSecondary,
      ),
      onSuffixIconPressed: () {
        setState(() {
          _obscureText = !_obscureText;
        });
      },
    );
  }
}
