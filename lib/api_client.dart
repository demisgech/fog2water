import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

import 'package:network_info_plus/network_info_plus.dart';

class ApiClient {
  String host;
  int port;
  final _info = NetworkInfo();
  ApiClient({required this.host, this.port = 80});

  String get _baseUrl => 'http://$host:$port';

  // MAGIC: Finds the ESP32 IP on your current Wi-Fi network
  Future<String?> discoverDeviceIP() async {
    final String? ip = await _info.getWifiIP();
    if (ip == null) return null;

    // Get the subnet (e.g., 192.168.1)
    final String subnet = ip.substring(0, ip.lastIndexOf('.'));

    // Scan all 255 addresses in parallel for speed
    final futures = List.generate(255, (i) async {
      final target = '$subnet.${i + 1}';
      try {
        final res = await http
            .get(Uri.parse('http://$target:$port/api/health'))
            .timeout(const Duration(milliseconds: 500));
        if (res.statusCode == 200) return target;
      } catch (_) {}
      return null;
    });

    final results = await Future.wait(futures);
    return results.firstWhere((element) => element != null, orElse: () => null);
  }

  // Check if the device is reachable
  Future<bool> checkHealth() async {
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/api/health'))
          .timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getTds() async {
    final res = await http.get(Uri.parse('$_baseUrl/api/tds'));
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> getConfig() async {
    final res = await http.get(Uri.parse('$_baseUrl/api/config'));
    return jsonDecode(res.body);
  }

  Future<void> sendConfig(Map<String, dynamic> config) async {
    await http.post(
      Uri.parse('$_baseUrl/api/config'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(config),
    );
  }

  Future<void> reboot() async =>
      await http.post(Uri.parse('$_baseUrl/api/reboot'));
}
