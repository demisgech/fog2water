import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fog2water/api_client.dart';
import 'package:fog2water/fog2water.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Default to Hotspot IP initially
  final api = ApiClient(host: "192.168.4.1", port: 80);

  late AnimationController _controller;
  late Animation<double> _animation;
  String _loadingText = "Initializing...";

  @override
  void initState() {
    super.initState();

    // Floating cloud animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0,
      end: 15,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    setState(() => _loadingText = "Looking for Fog2Water...");

    // 1. Try to find the device on the local Wi-Fi network first
    try {
      String? foundIp = await api.discoverDeviceIP().timeout(
        const Duration(seconds: 2),
        onTimeout: () => null,
      );

      if (foundIp != null) {
        api.host = foundIp;
        setState(() => _loadingText = "Device found at $foundIp");
      } else {
        setState(() => _loadingText = "Connecting to Direct Hotspot...");
      }
    } catch (e) {
      debugPrint("Discovery error: $e");
    }

    // 2. Short delay to show the "Found" status for smooth UX
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (_, __, ___) => Fog2Water(api: api),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1e3c72), Color(0xFF2a5298), Color(0xFF6dd5ed)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 3),
            // Animated Cloud Icon
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _animation.value),
                  child: child,
                );
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.cloud,
                    size: 120,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  const Icon(Icons.waves, size: 50, color: Colors.white),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "Fog2Water",
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const Text(
              "SMART HARVESTING SYSTEM",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w300,
                color: Colors.white70,
                letterSpacing: 4,
              ),
            ),
            const Spacer(flex: 2),
            // Loading status
            Text(
              _loadingText,
              style: const TextStyle(color: Colors.white60, fontSize: 14),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
