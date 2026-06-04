import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/project.dart';

class ProjectCard extends StatefulWidget {
  final Project project;
  final VoidCallback? onTap;
  final VoidCallback? onInvest;
  final VoidCallback? onReadMore;
  final bool showInvestButton;

  const ProjectCard({
    super.key,
    required this.project,
    this.onTap,
    this.onInvest,
    this.onReadMore,
    this.showInvestButton = true,
  });

  @override
  State<ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<ProjectCard>
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _elevationAnimation = Tween<double>(begin: 0.0, end: 8.0).animate(
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
    final baseColor = _parseColor(widget.project.temaColor ?? '#00D4AA');

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
                height: 240,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.cardBackground,
                      AppColors.secondaryBackground,
                    ],
                    stops: const [0.0, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    // Enhanced main shadow for 3D effect
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: _isHovered ? 40 : 30,
                      offset: Offset(0, _isHovered ? 20 : 15),
                      spreadRadius: _isHovered ? 5 : 0,
                    ),
                    // Enhanced colored glow
                    BoxShadow(
                      color: baseColor.withValues(alpha: 0.25),
                      blurRadius: _isHovered ? 50 : 40,
                      offset: Offset(0, _isHovered ? 12 : 8),
                      spreadRadius: -8,
                    ),
                    // Deep shadow for elevation
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: _isHovered ? 25 : 20,
                      offset: Offset(0, _isHovered ? 15 : 10),
                    ),
                    // Inner highlight for top edge (3D effect)
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, -3),
                    ),
                    // Side shadow for depth
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(-8, 0),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Stack(
                  children: [
                    // Enhanced 3D Effect - Left side image
                    Positioned(
                      left: -30,
                      top: -10,
                      bottom: -10,
                      width: 200,
                      child: _build3DSide(context),
                    ),

                    // Content
                    Padding(
                      padding: const EdgeInsets.only(left: 130, right: 16, top: 16, bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Category Badge
                                _buildCategoryBadge(context),

                                const SizedBox(height: 8),

                                // Project Title
                                Text(
                                  widget.project.nombre,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                const SizedBox(height: 4),

                                // Subtitle/Description
                                Text(
                                  widget.project.truncatedDescription,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                const SizedBox(height: 8),

                                // Stats Row
                                Row(
                                  children: [
                                    _buildMiniStat(
                                      icon: Icons.account_balance_wallet,
                                      value: Formatters.formatCompactNumber(widget.project.totalInvertido),
                                    ),
                                    const SizedBox(width: 12),
                                    _buildMiniStat(
                                      icon: Icons.people,
                                      value: widget.project.numeroInversores.toString(),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Action Buttons
                          if (widget.showInvestButton) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildActionButton(
                                    onPressed: widget.onReadMore ?? widget.onTap,
                                    text: 'Leer más...',
                                    isSecondary: true,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildActionButton(
                                    onPressed: widget.onInvest,
                                    text: AppStrings.invest,
                                    isSecondary: false,
                                  ),
                                ),
                              ],
                            ),
                          ],
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

  Widget _build3DSide(BuildContext context) {
    final baseColor = _parseColor(widget.project.temaColor ?? '#00D4AA');

    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.horizontal(
          left: Radius.circular(24),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            baseColor.withValues(alpha: 0.98),
            baseColor.withValues(alpha: 0.85),
            baseColor.withValues(alpha: 0.65),
            Colors.transparent,
          ],
          stops: const [0.0, 0.25, 0.75, 1.0],
        ),
        boxShadow: [
          // Side shadow for depth
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(5, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Image with enhanced 3D effect
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(24),
              ),
              child: widget.project.imagen != null && widget.project.imagen!.isNotEmpty
                  ? Image.network(
                      widget.project.imagen!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholderIcon(baseColor),
                    )
                  : _buildPlaceholderIcon(baseColor),
            ),
          ),

          // Multiple shadow layers for realistic 3D depth
          Positioned(
            left: 15,
            top: 15,
            bottom: 15,
            right: 15,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: RadialGradient(
                  center: const Alignment(0.3, 0.4),
                  radius: 0.8,
                  colors: [
                    Colors.black.withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Side shadow for depth
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 60,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.5),
                    Colors.black.withValues(alpha: 0.7),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // Enhanced highlight edge
          Positioned(
            right: 0,
            top: 8,
            bottom: 8,
            width: 3,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.white.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(1.5),
                ),
              ),
            ),
          ),

          // Top edge highlight
          Positioned(
            right: 0,
            top: 0,
            left: 0,
            height: 2,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [
                    Colors.white.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Bottom edge shadow
          Positioned(
            right: 0,
            bottom: 0,
            left: 20,
            height: 30,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.3),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderIcon(Color baseColor) {
    return Container(
      color: baseColor.withValues(alpha: 0.3),
      child: Center(
        child: Icon(
          Icons.business,
          size: 60,
          color: Colors.white.withValues(alpha: 0.8),
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _parseColor(widget.project.temaColor ?? '#00D4AA').withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _parseColor(widget.project.temaColor ?? '#00D4AA').withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        widget.project.temaNombre,
        style: TextStyle(
          color: _parseColor(widget.project.temaColor ?? '#00D4AA'),
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildMiniStat({
    required IconData icon,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required VoidCallback? onPressed,
    required String text,
    required bool isSecondary,
  }) {
    final baseColor = _parseColor(widget.project.temaColor ?? '#00D4AA');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            gradient: isSecondary
                ? null
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      baseColor,
                      baseColor.withValues(alpha: 0.8),
                    ],
                  ),
            color: isSecondary
                ? AppColors.tertiaryBackground
                : null,
            borderRadius: BorderRadius.circular(10),
            border: isSecondary
                ? Border.all(
                    color: AppColors.borderLight,
                    width: 1,
                  )
                : null,
            boxShadow: isSecondary
                ? null
                : [
                    BoxShadow(
                      color: baseColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSecondary ? AppColors.textPrimary : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceAll('#', '0xFF')));
    } catch (e) {
      return AppColors.primaryAccent;
    }
  }
}
