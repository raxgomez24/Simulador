import 'dart:io';

/// Utilidades de red para detectar IP local y mostrar URL de conexión
/// Útil para modo multi-dispositivo donde otros usuarios se conectan a este servidor
class NetworkUtils {
  /// Detecta automáticamente la dirección IP local de la máquina
  /// Busca IPs en rangos típicos de redes locales (192.168.x.x, 10.x.x.x, 172.x.x.x)
  ///
  /// Retorna:
  /// - La primera dirección IPv4 encontrada en rango de red privada
  /// - null si no encuentra ninguna IP válida
  static Future<String?> getLocalIPAddress() async {
    try {
      // Obtener todas las interfaces de red (async)
      final interfaces = await NetworkInterface.list(includeLinkLocal: false, includeLoopback: false);

      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          // Solo considerar direcciones IPv4
          if (addr.type == InternetAddressType.IPv4) {
            final ip = addr.address;

            // Filtrar rangos de IPs privadas
            if (ip.startsWith('192.168.') ||
                ip.startsWith('10.') ||
                (ip.startsWith('172.') && _isPrivate172(ip))) {
              return ip;
            }
          }
        }
      }
    } catch (e) {
      // Silenciar error en producción
    }
    return null;
  }

  /// Verifica si una IP 172.x.x.x es privada (rango 172.16.0.0 - 172.31.255.255)
  static bool _isPrivate172(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return false;
    try {
      final secondOctet = int.parse(parts[1]);
      return secondOctet >= 16 && secondOctet <= 31;
    } catch (e) {
      return false;
    }
  }

  /// Obtiene la URL completa del servidor para que otros dispositivos se conecten
  ///
  /// Ejemplo de uso:
  /// ```dart
  /// final url = await NetworkUtils.getServerURL();
  /// print('Conéctate a: $url'); // "Conéctate a: http://192.168.1.100:9000"
  /// ```
  static Future<String> getServerURL() async {
    final ip = await getLocalIPAddress();
    if (ip != null) {
      return 'http://$ip:9000';
    }
    return 'http://localhost:9000';
  }

  /// Obtiene información de conexión formateada para mostrar en UI
  ///
  /// Retorna un mapa con:
  /// - url: URL completa del servidor
  /// - ip: dirección IP (o localhost)
  /// - port: puerto del servidor
  /// - instructions: instrucciones para conectarse
  static Future<Map<String, String>> getConnectionInfo() async {
    final ip = await getLocalIPAddress() ?? 'localhost';
    return {
      'url': 'http://$ip:9000',
      'ip': ip,
      'port': '9000',
      'instructions': 'Conéctate al WiFi y abre esta URL en tu navegador',
    };
  }
}
