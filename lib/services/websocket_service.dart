import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/api_constants.dart';
import '../data/datasources/remote/websocket_datasource.dart';

final webSocketServiceProvider =
    AsyncNotifierProvider<WebSocketService, void>(WebSocketService.new);

class WebSocketService extends AsyncNotifier<void> {
  WebSocketDataSource? _dataSource;
  StreamSubscription? _messageSubscription;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  @override
  FutureOr<void> build() async {
    _dataSource = WebSocketDataSource();
  }

  Future<void> connect({String? url}) async {
    final wsUrl = url ?? ApiConstants.defaultWebSocketUrl;
    await _dataSource?.connect(wsUrl);

    _messageSubscription?.cancel();
    _messageSubscription = _dataSource!.messageStream.listen(
      _messageController.add,
      onError: _messageController.addError,
    );

    state = const AsyncValue.data(null);
  }

  void send(Map<String, dynamic> data) {
    _dataSource?.send(data);
  }

  bool get isConnected => _dataSource?.isConnected ?? false;

  Future<void> disconnect() async {
    await _messageSubscription?.cancel();
    await _dataSource?.disconnect();
    _messageSubscription = null;
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
}

final connectionStatusProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(webSocketServiceProvider.notifier);
  return Stream.periodic(const Duration(seconds: 1), (_) {
    return service.isConnected;
  });
});
