import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AppSearchBar extends StatefulWidget {
  final String? hintText;
  final Function(String)? onSearch;
  final Function()? onClear;
  final bool autofocus;
  final TextEditingController? controller;

  const AppSearchBar({
    super.key,
    this.hintText,
    this.onSearch,
    this.onClear,
    this.autofocus = false,
    this.controller,
  });

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  late TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
    _hasText = _controller.text.isNotEmpty;
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _hasText = _controller.text.isNotEmpty;
    });
    widget.onSearch?.call(_controller.text);
  }

  void _clearSearch() {
    _controller.clear();
    widget.onClear?.call();
    _onTextChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.tertiaryBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, right: 8),
            child: Icon(
              Icons.search,
              color: AppColors.textSecondary,
              size: 22,
            ),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: widget.autofocus,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText ?? 'Buscar proyectos, participantes...',
                hintStyle: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (value) {
                widget.onSearch?.call(value);
                FocusScope.of(context).unfocus();
              },
            ),
          ),
          if (_hasText)
            IconButton(
              onPressed: _clearSearch,
              icon: const Icon(
                Icons.clear,
                color: AppColors.textSecondary,
                size: 20,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
            ),
        ],
      ),
    );
  }
}
