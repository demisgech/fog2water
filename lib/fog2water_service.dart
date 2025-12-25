import 'dart:convert';
import 'package:fog2water/telegram_http_service.dart';
import 'package:http/http.dart' as http;

class Fog2WaterService {
  final _telegramSettings = TelegramHttpService();

  int _lastUpdateId = 0;

  Future<Map<String, dynamic>> fetchWaterData() async {
    final botToken = await _telegramSettings.getBotToken();
    final chatId = await _telegramSettings.getChatId();

    if (botToken == null || chatId == null) {
      throw Exception('Telegram bot not configured');
    }

    await _sendCheckCommand(botToken, chatId);
    await Future.delayed(const Duration(seconds: 2));
    return await _readTelegramResponse(botToken);
  }

  Future<void> _sendCheckCommand(String botToken, String chatId) async {
    final uri = Uri.https(
      'api.telegram.org',
      '/bot${botToken.replaceAll(RegExp(r'\s+'), '')}/sendMessage',
      {},
    );
    // With this mock server URL
    // final uri = Uri.http('10.2.74.75:4000', '/sendMessage');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'chat_id': chatId, 'text': '/check'}),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to send /check command: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<Map<String, dynamic>> _readTelegramResponse(String botToken) async {
    final uri = Uri.https(
      'api.telegram.org',
      '/bot${botToken.replaceAll(RegExp(r'\s+'), '')}/getUpdates',
      {'offset': (_lastUpdateId + 1).toString()},
    );

    // mock server
    // final uri = Uri.http('10.2.74.75:4000', '/getUpdates', {
    //   'offset': (_lastUpdateId + 1).toString(),
    // });
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to read Telegram updates: ${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    final List updates = decoded['result'];

    if (updates.isEmpty) {
      throw Exception('No response from ESP32');
    }

    final last = updates.last;
    _lastUpdateId = last['update_id'];

    final String message = last['message']['text'];
    return _parseMessage(message);
  }

  Map<String, dynamic> _parseMessage(String message) {
    final ppmMatch = RegExp(
      r'PPM Level\s*:\s*(\d+)',
      caseSensitive: false,
    ).firstMatch(message);

    final qualityMatch = RegExp(
      r'Quality\s*:\s*(.*)',
      caseSensitive: false,
    ).firstMatch(message);

    return {
      // "water_level": 0, // Not sent by ESP32 yet
      // "pH": 0,
      // "temperature": 0,
      "ppm": ppmMatch != null ? int.parse(ppmMatch.group(1)!) : 0,
      "quality": qualityMatch?.group(1) ?? "Unknown",
    };
  }
}
