import 'package:flutter/material.dart';
import '../../../app/config.dart';
import '../../../core/constants/app_colors.dart';

/// Footer widget for hamburger menu showing app version
class HamburgerMenuFooter extends StatelessWidget {
  const HamburgerMenuFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        border: Border(
          top: BorderSide(
            color: AppColors.borderLight.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.info_outline,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                'Amerike MBA 2026',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Versión ${AppConfig.appVersion}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary.withValues(alpha: 0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
