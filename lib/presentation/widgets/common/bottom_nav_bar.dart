import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                icon: Icons.home,
                label: AppStrings.home,
                index: 0,
                route: '/',
              ),
              _buildNavItem(
                context,
                icon: Icons.business_center,
                label: AppStrings.projects,
                index: 1,
                route: '/projects',
              ),
              _buildNavItem(
                context,
                icon: Icons.account_balance_wallet,
                label: AppStrings.investments,
                index: 2,
                route: '/investments',
              ),
              _buildNavItem(
                context,
                icon: Icons.leaderboard,
                label: AppStrings.ranking,
                index: 3,
                route: '/ranking',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int index,
    required String route,
  }) {
    final isSelected = currentIndex == index;
    final color = isSelected ? AppColors.primaryAccent : AppColors.textSecondary;

    return InkWell(
      onTap: () {
        if (currentIndex != index) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            route,
            (route) => false,
          );
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
