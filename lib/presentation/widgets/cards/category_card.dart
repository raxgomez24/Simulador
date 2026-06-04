import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/theme.dart';

class CategoryCard extends StatefulWidget {
  final InvestmentTheme theme;
  final VoidCallback? onTap;
  final bool isSelected;

  const CategoryCard({
    super.key,
    required this.theme,
    this.onTap,
    this.isSelected = false,
  });

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _elevationAnimation = Tween<double>(begin: 0.0, end: 6.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _setHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _parseColor(widget.theme.color);
    final themeData = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      child: GestureDetector(
        onTapDown: (_) => _animationController.forward(),
        onTapUp: (_) => _animationController.reverse(),
        onTapCancel: () => _animationController.reverse(),
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.isSelected
                        ? [
                            themeColor.withOpacity(0.3),
                            themeColor.withOpacity(0.1),
                          ]
                        : [
                            AppColors.cardBackground,
                            AppColors.cardBackground.withOpacity(0.8),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: widget.isSelected ? themeColor : AppColors.borderLight,
                    width: widget.isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    // Enhanced main shadow for 3D effect
                    BoxShadow(
                      color: Colors.black.withOpacity(widget.isSelected || _isHovered ? 0.35 : 0.15),
                      blurRadius: _isHovered ? 28 : widget.isSelected ? 20 : 12,
                      offset: Offset(0, _isHovered ? 12 : widget.isSelected ? 8 : 4),
                      spreadRadius: _isHovered ? 3 : 0,
                    ),
                    // Colored glow for selected state
                    if (widget.isSelected)
                      BoxShadow(
                        color: themeColor.withOpacity(0.25),
                        blurRadius: 25,
                        offset: const Offset(0, 6),
                        spreadRadius: -5,
                      ),
                    // Colored glow on hover (even when not selected)
                    if (_isHovered && !widget.isSelected)
                      BoxShadow(
                        color: themeColor.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    // Inner highlight for top edge (3D effect)
                    BoxShadow(
                      color: Colors.white.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                    // Side shadow for depth
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(-4, 0),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Enhanced colored accent on left side
                    Positioned(
                      left: 0,
                      top: 8,
                      bottom: 8,
                      width: widget.isSelected || _isHovered ? 4 : 2,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              themeColor.withOpacity(0.4),
                              themeColor,
                              themeColor.withOpacity(0.4),
                            ],
                          ),
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Icon with enhanced 3D effect
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  themeColor.withOpacity(0.25),
                                  themeColor.withOpacity(0.15),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: themeColor.withOpacity(0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: themeColor.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                _getIconData(widget.theme.icon),
                                color: themeColor,
                                size: 18,
                              ),
                            ),
                          ),

                          const SizedBox(height: 6),

                          // Category Name
                          Text(
                            widget.theme.nombre,
                            style: themeData.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: widget.isSelected ? themeColor : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 4),

                          // Combined stats in one row
                          Row(
                            children: [
                              Icon(
                                Icons.business_center,
                                size: 11,
                                color: widget.isSelected
                                    ? themeColor.withOpacity(0.8)
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  '${widget.theme.numeroProyectos}',
                                  style: TextStyle(
                                    color: widget.isSelected
                                        ? themeColor.withOpacity(0.9)
                                        : AppColors.textSecondary,
                                    fontSize: 10,
                                    fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.account_balance_wallet,
                                size: 11,
                                color: widget.isSelected
                                    ? themeColor.withOpacity(0.8)
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  Formatters.formatCompactNumber(widget.theme.totalInvertido),
                                  style: TextStyle(
                                    color: widget.isSelected
                                        ? themeColor
                                        : AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'technology':
      case 'tech':
        return Icons.computer;
      case 'health':
        return Icons.health_and_safety;
      case 'energy':
        return Icons.bolt;
      case 'education':
        return Icons.school;
      case 'finance':
      case 'finanzas':
        return Icons.attach_money;
      case 'retail':
        return Icons.shopping_cart;
      case 'manufacturing':
        return Icons.precision_manufacturing;
      case 'real_estate':
      case 'bienes_raíces':
        return Icons.home_work;
      default:
        return Icons.category;
    }
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceAll('#', '0xFF')));
    } catch (e) {
      return AppColors.primaryAccent;
    }
  }
}
