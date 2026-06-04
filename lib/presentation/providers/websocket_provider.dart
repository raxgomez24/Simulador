import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/websocket_datasource.dart';

/// Provider compartido para WebSocketDataSource
/// Todas las partes de la app que necesiten WebSocket deben usar este provider
final webSocketDataSourceProvider = Provider<WebSocketDataSource>((ref) {
  final dataSource = WebSocketDataSource();

  // Disponer el datasource cuando el provider se dispose
  ref.onDispose(() => dataSource.dispose());

  return dataSource;
});
