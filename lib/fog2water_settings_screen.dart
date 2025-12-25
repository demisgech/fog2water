import 'package:flutter/material.dart';
import 'package:fog2water/telegram_http_service.dart';

class Fog2WaterSettingsScreen extends StatefulWidget {
  const Fog2WaterSettingsScreen({super.key});

  @override
  State<Fog2WaterSettingsScreen> createState() =>
      _Fog2WaterSettingsScreenState();
}

class _Fog2WaterSettingsScreenState extends State<Fog2WaterSettingsScreen> {
  final _tokenCtrl = TextEditingController();
  final _chatCtrl = TextEditingController();
  final settings = TelegramHttpService();

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final token = await settings.getBotToken();
    final chatId = await settings.getChatId();

    setState(() {
      _tokenCtrl.text = token ?? '';
      _chatCtrl.text = chatId ?? '';
      loading = false;
    });
  }

  Future<void> save() async {
    await settings.save(
      botToken: _tokenCtrl.text.trim(),
      chatId: _chatCtrl.text.trim(),
    );

    // Notify previous screen to refresh
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text('Telegram Settings'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  spacing: 20,
                  children: [
                    Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          spacing: 18,
                          children: [
                            InputField(
                              controller: _tokenCtrl,
                              label: "Bot Token",
                              icon: Icons.key,
                            ),
                            InputField(
                              controller: _chatCtrl,
                              label: "Chat ID",
                              icon: Icons.chat,
                            ),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: save,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text(
                                  'Save Settings',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Confirmation that token exists
                    if (_tokenCtrl.text.isNotEmpty)
                      InfoTitle(
                        text: 'Bot token stored successfully',
                        icon: Icons.verified,
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

class InputField extends StatelessWidget {
  const InputField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class InfoTitle extends StatelessWidget {
  const InfoTitle({super.key, required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.green),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: Colors.green)),
      ],
    );
  }
}
