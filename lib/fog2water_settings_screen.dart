import 'package:flutter/material.dart';
import 'package:fog2water/api_client.dart';

class Fog2WaterSettingsScreen extends StatefulWidget {
  final ApiClient api;
  const Fog2WaterSettingsScreen({super.key, required this.api});

  @override
  State<Fog2WaterSettingsScreen> createState() => _SettingsState();
}

class _SettingsState extends State<Fog2WaterSettingsScreen> {
  bool isHotspotMode = true;
  bool isOnline = false;
  bool isLoading = false;

  // Controllers
  final _ssid = TextEditingController();
  final _pass = TextEditingController();
  final _name = TextEditingController(text: "fog2water");
  final _port = TextEditingController(text: "80");

  @override
  void initState() {
    super.initState();
    _checkStatus();
    _loadExistingConfig();
  }

  // Load current settings from ESP32 if online
  Future<void> _loadExistingConfig() async {
    try {
      final cfg = await widget.api.getConfig();
      setState(() {
        _ssid.text = cfg['ssid'] ?? '';
        _name.text = cfg['deviceName'] ?? 'fog2water';
        _port.text = cfg['port']?.toString() ?? '80';
        // Note: Password is never returned for security
      });
    } catch (e) {
      debugPrint("Could not load config: $e");
    }
  }

  void _checkStatus() async {
    bool status = await widget.api.checkHealth();
    if (mounted) {
      setState(() => isOnline = status);
    }
  }

  void _saveConfig() async {
    if (_ssid.text.isEmpty || _pass.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter Wi-Fi credentials")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // 1. Send configuration to ESP32 (while still on 192.168.4.1)
      await widget.api.sendConfig({
        "ssid": _ssid.text.trim(),
        "password": _pass.text,
        "deviceName": _name.text.trim(),
        "port": int.tryParse(_port.text) ?? 80,
      });

      // 2. Trigger Reboot
      await widget.api.reboot();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Settings sent! Searching for device on your Wi-Fi..."),
        ),
      );

      // 3. The "Waiting Room": Give ESP32 time to connect to your router
      // We try to discover the IP every 3 seconds for up to 30 seconds
      String? foundIp;
      for (int i = 0; i < 10; i++) {
        await Future.delayed(const Duration(seconds: 3));
        foundIp = await widget.api.discoverDeviceIP();
        if (foundIp != null) break;
      }

      if (foundIp != null) {
        widget.api.host = foundIp;
        if (mounted) {
          Navigator.pop(context, true); // Success
        }
      } else {
        throw Exception(
          "Device connected to Wi-Fi but couldn't be found by the app. Check your router.",
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text("Device Connection"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _checkStatus),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: CircleAvatar(
                radius: 6,
                backgroundColor: isOnline ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 24),

            const Text(
              "Connection Mode",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildModeSelector(),
            const SizedBox(height: 24),
            const Text(
              "Wi-Fi Credentials",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Configuration Form Area
            AnimatedOpacity(
              opacity: isHotspotMode ? 0.4 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: AbsorbPointer(
                absorbing: isHotspotMode,
                child: Column(
                  children: [
                    InputField(
                      controller: _ssid,
                      label: "Network SSID",
                      icon: Icons.wifi,
                    ),
                    const SizedBox(height: 16),
                    InputField(
                      controller: _pass,
                      label: "Network Password",
                      icon: Icons.lock,
                    ),
                    const SizedBox(height: 16),
                    InputField(
                      controller: _name,
                      label: "Device Name",
                      icon: Icons.label,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOnline
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isOnline ? Colors.green : Colors.red,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Icon(
            isOnline ? Icons.check_circle : Icons.warning_rounded,
            color: isOnline ? Colors.green : Colors.red,
            size: 40,
          ),
          const SizedBox(height: 8),
          Text(
            isOnline ? "ESP32 is Online" : "ESP32 Disconnected",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isOnline ? Colors.green[800] : Colors.red[800],
            ),
          ),
          Text(
            "Current Host: ${widget.api.host}",
            style: TextStyle(
              color: isOnline ? Colors.green[700] : Colors.red[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(4), // Subtle outer border padding
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: isHotspotMode
            ? LinearGradient(
                colors: [Colors.teal.shade400, Colors.teal.shade700],
              )
            : LinearGradient(
                colors: [Colors.grey.shade200, Colors.grey.shade300],
              ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => setState(() => isHotspotMode = !isHotspotMode),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                // Icon Circle
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isHotspotMode
                        ? Colors.teal.withValues(alpha: 0.1)
                        : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isHotspotMode ? Icons.wifi_tethering : Icons.wifi,
                    color: isHotspotMode ? Colors.teal : Colors.grey,
                  ),
                ),
                const SizedBox(width: 16),
                // Labels
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isHotspotMode ? "Direct Setup Mode" : "Home Wi-Fi Mode",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        isHotspotMode
                            ? "Connected to ESP32 Hotspot"
                            : "Connected via your Router",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Custom Switch
                Switch.adaptive(
                  value: isHotspotMode,
                  activeThumbColor: Colors.teal,
                  onChanged: (v) => setState(() => isHotspotMode = v),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (isLoading)
          const CircularProgressIndicator()
        else
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 55),
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 0,
            ),
            onPressed: isHotspotMode ? null : _saveConfig,
            child: const Text(
              "SAVE & CONNECT",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () => widget.api.reboot(),
          icon: const Icon(Icons.restart_alt, color: Colors.orange),
          label: const Text(
            "Reboot Device",
            style: TextStyle(color: Colors.orange),
          ),
        ),
      ],
    );
  }
}

class InputField extends StatelessWidget {
  const InputField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: label.toLowerCase().contains("password"),
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
