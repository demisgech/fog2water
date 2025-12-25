import 'package:flutter/material.dart';
import 'package:fog2water/error_screen.dart';
import 'package:fog2water/fog2water_service.dart';
import 'package:fog2water/fog2water_settings_screen.dart';
import 'package:fog2water/history_list.dart';
import 'package:fog2water/metric_card.dart';
import 'dart:async';

class Fog2Water extends StatefulWidget {
  const Fog2Water({super.key});

  @override
  State<Fog2Water> createState() => _Fog2WaterState();
}

class _Fog2WaterState extends State<Fog2Water> {
  final _fog2WaterService = Fog2WaterService();
  Map<String, dynamic> data = {};
  List<Map<String, dynamic>> history = []; // store historical readings
  Timer? timer;
  String? errorMessage;

  Future<void> _fetchData() async {
    try {
      final result = await _fog2WaterService.fetchWaterData();
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

  @override
  void initState() {
    super.initState();
    _fetchData();
    timer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchData());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return Scaffold(
        body: ErrorScreen(
          message: errorMessage,
          onPressed: () {
            setState(() {
              errorMessage = null;
              _fetchData();
            });
          },
        ),
      );
    }

    // Normal dashboard view
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        title: const Text('Fog2Water Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const Fog2WaterSettingsScreen(),
                ),
              );

              if (updated == true) {
                _fetchData(); // refresh dashboard
              }
            },
          ),
        ],
      ),
      body: Container(
        height: MediaQuery.sizeOf(context).height,
        width: double.infinity,

        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7F9FB), Color(0xFFEFF3F6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: data.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      alignment: WrapAlignment.center,
                      runAlignment: WrapAlignment.center,
                      children: [
                        MetricCard(
                          label: "PPM Level",
                          icon: Icons.science,
                          value: data['ppm'] ?? 0,
                          color: Colors.deepPurple,
                        ),

                        MetricCard(
                          label: "Quality",
                          icon: Icons.check_circle,
                          value: data['quality'] ?? "N/A",
                          color: Colors.green,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    HistoryList(
                      history: history,
                      onDelete: (index) {
                        setState(() {
                          history.removeAt(index);
                        });
                      },
                      onClearAll: () {
                        setState(() {
                          history.clear();
                        });
                      },
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
