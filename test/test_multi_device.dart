import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';

/// Multi-Device Testing Utilities
///
/// This script provides automated testing capabilities for WebSocket
/// connections and server status verification before manual testing.

void main() {
  group('Multi-Device Pre-flight Checks', () {
    test('WebSocket Server is running on port 8080', () async {
      final result = await Process.run('lsof', ['-i', ':8080']);
      expect(result.exitCode, equals(0));
      expect(result.stdout.toString(), contains('http-alt'));
      print('✅ WebSocket Server is RUNNING on port 8080');
    });

    test('Flutter Web Server is running on port 9000', () async {
      final result = await Process.run('lsof', ['-i', ':9000']);
      expect(result.exitCode, equals(0));
      expect(result.stdout.toString(), contains('cslistener'));
      print('✅ Flutter Web Server is RUNNING on port 9000');
    });

    test('Can reach web server', () async {
      final client = HttpClient();
      try {
        final request = await client.getUrl(Uri.parse('http://192.168.40.1:9000'));
        final response = await request.close();
        expect(response.statusCode, equals(200));
        print('✅ Web server is reachable at http://192.168.40.1:9000');
      } catch (e) {
        throw Exception('❌ Cannot reach web server: $e');
      } finally {
        client.close();
      }
    });

    test('Can establish WebSocket connection', () async {
      try {
        final socket = await WebSocket.connect('ws://192.168.40.1:8080');

        // Wait for connection message
        socket.listen((message) {
          final data = jsonDecode(message as String);
          print('📨 Received WebSocket message: $data');
        });

        await Future.delayed(Duration(seconds: 2));
        socket.close();

        print('✅ WebSocket connection successful');
      } catch (e) {
        throw Exception('❌ WebSocket connection failed: $e');
      }
    });
  });

  group('Multi-Device Flow Simulation', () {
    test('Admin can connect and authenticate', () async {
      // Simulate admin connection
      try {
        final socket = await WebSocket.connect('ws://192.168.40.1:8080');

        // Send admin authentication
        final authMessage = {
          'type': 'auth',
          'username': 'admin',
          'password': 'admin123',
        };

        socket.add(jsonEncode(authMessage));

        // Wait for response
        final response = await socket.first;
        final data = jsonDecode(response as String);

        expect(data['type'], equals('auth_success'));
        print('✅ Admin authentication successful');

        socket.close();
      } catch (e) {
        throw Exception('❌ Admin authentication failed: $e');
      }
    });

    test('Multiple users can connect simultaneously', () async {
      final sockets = <WebSocket>[];

      try {
        // Connect 3 users
        for (int i = 1; i <= 3; i++) {
          final socket = await WebSocket.connect('ws://192.168.40.1:8080');
          sockets.add(socket);
          print('✅ User $i connected successfully');
        }

        // Verify all are connected
        expect(sockets.length, equals(3));
        print('✅ All 3 users connected simultaneously');

        // Cleanup
        for (final socket in sockets) {
          await socket.close();
        }
      } catch (e) {
        // Cleanup on error
        for (final socket in sockets) {
          await socket.close();
        }
        throw Exception('❌ Multi-user connection failed: $e');
      }
    });
  });

  group('Performance Tests', () {
    test('WebSocket latency < 500ms', () async {
      final socket = await WebSocket.connect('ws://192.168.40.1:8080');

      final stopwatch = Stopwatch()..start();

      socket.add(jsonEncode({'type': 'ping', 'timestamp': DateTime.now().toIso8601String()}));

      await socket.first;
      stopwatch.stop();

      await socket.close();

      final latency = stopwatch.elapsedMilliseconds;
      print('⏱️ WebSocket latency: ${latency}ms');

      expect(latency, lessThan(500));
      print('✅ WebSocket latency within acceptable range');
    });

    test('Server handles multiple connections without crash', () async {
      final sockets = <WebSocket>[];

      try {
        // Create 10 simultaneous connections
        final futures = List.generate(10, (i) =>
          WebSocket.connect('ws://192.168.40.1:8080')
        );

        sockets.addAll(await Future.wait(futures));

        expect(sockets.length, equals(10));
        print('✅ Server handled 10 simultaneous connections');

        // Cleanup
        for (final socket in sockets) {
          await socket.close();
        }
      } catch (e) {
        // Cleanup on error
        for (final socket in sockets) {
          await socket.close();
        }
        throw Exception('❌ Server crash test failed: $e');
      }
    });
  });

  group('Manual Testing Instructions', () {
    test('Display manual testing guide', () async {
      print('\n' + '='*80);
      print('MANUAL MULTI-DEVICE TESTING GUIDE');
      print('='*80);
      print('\n📋 PRE-FLIGHT CHECKS:');
      print('  [✓] Open 3 browser windows with: http://192.168.40.1:9000');
      print('  [✓] Window 1: Login as admin/admin123');
      print('  [✓] Window 2: Register as "usuario_test_1"');
      print('  [✓] Window 3: Register as "usuario_test_2"');
      print('  [✓] Verify all windows show "Connected" status\n');

      print('🎯 TEST FLOW 1: Admin Starts Round');
      print('  1. Admin clicks "Iniciar Nueva Ronda"');
      print('  2. Verify ALL windows show "Ronda Activa"');
      print('  3. Verify all windows show same round ID');
      print('  4. Expected sync time: < 2 seconds\n');

      print('🎯 TEST FLOW 2: Users Invest');
      print('  1. User 1 invests \$1000 in "Startup Tech"');
      print('  2. User 2 invests \$1500 in "Real Estate"');
      print('  3. Verify ALL windows show updated ranking');
      print('  4. Verify ranking order is consistent across devices');
      print('  5. Expected sync time: < 1 second per investment\n');

      print('🎯 TEST FLOW 3: Admin Pauses Round');
      print('  1. Admin clicks "Pausar Ronda"');
      print('  2. Verify ALL windows show "Ronda Pausada"');
      print('  3. Try to invest as User 1 - should be blocked');
      print('  4. Admin clicks "Reanudar Ronda"');
      print('  5. Verify ALL windows return to "Ronda Activa"\n');

      print('🎯 TEST FLOW 4: Admin Ends Round');
      print('  1. Admin clicks "Terminar Ronda"');
      print('  2. Verify ALL windows show "Ronda Finalizada"');
      print('  3. Verify final ranking is consistent');
      print('  4. Verify no more investments can be made\n');

      print('🚀 STRESS TEST: Simultaneous Actions');
      print('  1. Admin starts new round');
      print('  2. Users 1 & 2 make 5 investments each, alternating quickly');
      print('  3. Monitor for crashes or errors');
      print('  4. Verify all investments are recorded correctly');
      print('  5. Verify no duplicates or lost investments\n');

      print('🔄 RECONNECTION TEST');
      print('  1. User 1 disconnects network (WiFi off)');
      print('  2. Wait 5 seconds');
      print('  3. User 1 reconnects network (WiFi on)');
      print('  4. Admin makes a visible change (pause/resume)');
      print('  5. Verify User 1 receives the change and syncs properly\n');

      print('='*80);
      print('📊 DOCUMENTATION:');
      print('  - Update results in: MULTI_DEVICE_TESTING_REPORT.md');
      print('  - Collect browser console logs');
      print('  - Record any errors or unexpected behavior');
      print('  - Take screenshots of key states');
      print('='*80 + '\n');

      expect(true, isTrue); // Always passes, just displays instructions
    });
  });
}