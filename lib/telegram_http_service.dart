import 'package:shared_preferences/shared_preferences.dart';

class TelegramHttpService {
  static const _tokenKey = 'bot_token';
  static const _chatIdKey = 'chat_id';

  Future<void> save({required String botToken, required String chatId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, botToken);
    await prefs.setString(_chatIdKey, chatId);
  }

  Future<String?> getBotToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<String?> getChatId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_chatIdKey);
  }

  Future<bool> isConfigured() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_tokenKey) && prefs.containsKey(_chatIdKey);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
