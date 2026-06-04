import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../presentation/providers/websocket_connection_provider.dart';

/// Widget que muestra el estado de la conexión WebSocket
class ConnectionIndicator extends ConsumerWidget {
  const ConnectionIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(webSocketConnectionProvider);

    return Tooltip(
      message: _getConnectionMessage(connectionState),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getStatusColor(connectionState).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getStatusColor(connectionState),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusIcon(connectionState),
            const SizedBox(width: 4),
            Text(
              _getStatusText(connectionState),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _getStatusColor(connectionState),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(WebSocketConnectionState state) {
    if (state.isConnecting) {
      return AppColors.warning; // Amarillo
    } else if (state.isConnected) {
      return AppColors.success; // Verde
    } else {
      return AppColors.error; // Rojo
    }
  }

  Widget _buildStatusIcon(WebSocketConnectionState state) {
    if (state.isConnecting) {
      return const SizedBox(
        width: 8,
        height: 8,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.warning,
        ),
      );
    } else if (state.isConnected) {
      return Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.success,
          shape: BoxShape.circle,
        ),
      );
    } else {
      return const Icon(
        Icons.error_outline,
        size: 12,
        color: AppColors.error,
      );
    }
  }

  String _getStatusText(WebSocketConnectionState state) {
    if (state.isConnecting) {
      return 'Conectando...';
    } else if (state.isConnected) {
      return 'En línea';
    } else {
      return 'Desconectado';
    }
  }

  String _getConnectionMessage(WebSocketConnectionState state) {
    if (state.isConnecting) {
      return 'Conectando al servidor...';
    } else if (state.isConnected) {
      final lastConnected = state.lastConnectedAt;
      if (lastConnected != null) {
        final ago = DateTime.now().difference(lastConnected);
        return 'Conectado - Hace ${_formatDuration(ago)}';
      }
      return 'Conectado al servidor';
    } else {
      final error = state.error;
      if (error != null) {
        return 'Desconectado: $error';
      }
      return 'Desconectado del servidor';
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes < 1) {
      return '${duration.inSeconds}s';
    } else if (duration.inHours < 1) {
      return '${duration.inMinutes}min';
    } else {
      return '${duration.inHours}h ${duration.inMinutes % 60}min';
    }
  }
}
