import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/session.dart';
import '../../providers/session_provider.dart';

class LiveTimerBadge extends ConsumerWidget {
  const LiveTimerBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(sessionProvider);

    return sessionState.when(
      data: (session) => TimerBadge(session: session),
      loading: () => const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class TimerBadge extends StatelessWidget {
  final Session session;

  const TimerBadge({
    super.key,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor();
    final statusIcon = _getStatusIcon();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withOpacity(0.2),
            statusColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            size: 16,
            color: statusColor,
          ),
          const SizedBox(width: 8),
          Text(
            Formatters.formatDuration(session.tiempoRestante),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 1,
            height: 20,
            color: statusColor.withOpacity(0.3),
          ),
          const SizedBox(width: 12),
          Text(
            session.estadoTexto,
            style: theme.textTheme.labelMedium?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (session.estado) {
      case SessionState.active:
        return AppColors.success;
      case SessionState.paused:
        return AppColors.warning;
      case SessionState.ended:
        return AppColors.error;
      case SessionState.waiting:
        return AppColors.textSecondary;
    }
  }

  IconData _getStatusIcon() {
    switch (session.estado) {
      case SessionState.active:
        return Icons.play_circle;
      case SessionState.paused:
        return Icons.pause_circle;
      case SessionState.ended:
        return Icons.stop_circle;
      case SessionState.waiting:
        return Icons.schedule;
    }
  }
}
