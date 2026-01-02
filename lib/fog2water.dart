import 'package:flutter/material.dart';
import 'package:fog2water/api_client.dart';
import 'package:fog2water/fog2water_settings_screen.dart';
import 'package:fog2water/history_list.dart';
import 'package:fog2water/metric_card.dart';
import 'dart:async';

class Fog2Water extends StatefulWidget {
  final ApiClient api;
  const Fog2Water({super.key, required this.api});

  @override
  State<Fog2Water> createState() => _Fog2WaterState();
}

class _Fog2WaterState extends State<Fog2Water> {
  Map<String, dynamic> data = {};
  List<Map<String, dynamic>> history = []; // store historical readings
  Timer? timer;
  String? errorMessage;

  Future<void> _fetchData() async {
    try {
      final result = await widget.api.getTds();
      setState(() {
        data = result;
        history.add({
          "timestamp": DateTime.now(),
          "ppm": result['ppm'],
          "quality": result['quality'],
        });
        errorMessage = null;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    }
  }

  Future<void> _goToSettings(BuildContext context) async {
    // We wait for the result from the settings screen
    final bool? updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Fog2WaterSettingsScreen(api: widget.api),
      ),
    );

    // If the settings screen returns 'true', it means the IP changed
    // or a reboot happened, so we reset the dashboard state.
    if (updated == true) {
      setState(() {
        history.clear(); // Optional: clear old IP history
        data = {};
      });
      _fetchData();
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
    timer = Timer.periodic(const Duration(seconds: 60), (_) => _fetchData());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: _buildAppBar(context),
      body: data.isEmpty && errorMessage == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Column(
                  children: [
                    // Dynamic Liquid Indicator (Hero Element)
                    _buildLiquidHero(),
                    const SizedBox(height: 24),

                    // Metric Grid
                    Row(
                      children: [
                        Expanded(
                          child: MetricCard(
                            label: "PPM Level",
                            icon: Icons.waves,
                            value: "${data['ppm'] ?? 0}",
                            subtext: "Particles",
                            color: Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: MetricCard(
                            label: "Water Quality",
                            icon: Icons.verified_user_outlined,
                            value: data['quality'] ?? "N/A",
                            subtext: "Status",
                            color: Colors.teal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // History Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Recent Readings",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (history.isNotEmpty)
                          TextButton(
                            onPressed: () => setState(() => history.clear()),
                            child: const Text("Clear All"),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    HistoryList(
                      history: history.reversed.toList(), // Show latest first
                      onDelete: (index) => setState(
                        () => history.removeAt(history.length - 1 - index),
                      ),
                      onClearAll: () => setState(() => history.clear()),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.black87,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Fog2Water",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            errorMessage != null ? "Offline" : "Live Monitoring",
            style: TextStyle(
              fontSize: 12,
              color: errorMessage != null ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => _goToSettings(context),
        ),
      ],
    );
  }

  Widget _buildLiquidHero() {
    double ppm = (data['ppm'] ?? 0).toDouble();
    // Logic for color based on quality
    Color liquidColor = ppm < 150
        ? Colors.blueAccent
        : (ppm < 400 ? Colors.orange : Colors.redAccent);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [liquidColor.withValues(alpha: 0.1), Colors.white],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: liquidColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          // The "Water Drop" Visualizer
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 140,
                width: 140,
                child: CircularProgressIndicator(
                  value: (ppm / 1000).clamp(0.0, 1.0),
                  strokeWidth: 8,
                  backgroundColor: Colors.grey.shade200,
                  color: liquidColor,
                ),
              ),
              Column(
                children: [
                  Text(
                    "${ppm.toInt()}",
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "PPM",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            data['quality']?.toString().toUpperCase() ?? "UNKNOWN",
            style: TextStyle(
              color: liquidColor,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
