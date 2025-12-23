import 'package:flutter/material.dart';
import 'package:fog2water/error_screen.dart';
import 'package:fog2water/metric_card.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';

class Fog2Water extends StatefulWidget {
  const Fog2Water({super.key});

  @override
  State<Fog2Water> createState() => _Fog2WaterState();
}

class _Fog2WaterState extends State<Fog2Water> {
  Map<String, dynamic> data = {};
  Timer? timer;
  String? errorMessage;

  Future<void> fetchData() async {
    try {
      final response = await http.get(Uri.parse('http://YOUR_ESP_IP/data'));
      if (response.statusCode == 200) {
        setState(() {
          data = json.decode(response.body);
          errorMessage = null; // Clear previous errors
        });
      } else {
        setState(() {
          errorMessage = 'Server error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching data: $e';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchData();
    timer = Timer.periodic(const Duration(seconds: 5), (_) => fetchData());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show error screen if any error occurred
    if (errorMessage != null) {
      return Scaffold(
        body: ErrorScreen(message: errorMessage, onPressed: fetchData),
      );
    }

    // Normal dashboard view
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[400],
        title: const Text('Fog2Water Dashboard'),
      ),
      body: Container(
        height: MediaQuery.sizeOf(context).height,
        width: double.infinity,

        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0xFFB2FF59), Color(0xFF33691E)],
            center: Alignment.topLeft,
            radius: 1.5,
          ),
        ),
        child:
            // data.isEmpty
            //     ? const Center(child: CircularProgressIndicator())
            //     :
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  MetricCard(
                    label: "Water Level",
                    value: "${data['water_level'] ?? 0} L",
                    icon: Icons.water_drop,
                    color: Colors.blueAccent,
                  ),
                  MetricCard(
                    label: "pH Level",
                    icon: Icons.science,
                    value: data['pH'] ?? 0,
                    color: Colors.deepPurple,
                  ),
                  MetricCard(
                    label: "Temperature",
                    icon: Icons.thermostat,
                    color: Colors.redAccent,
                    value: '${data["temperature"] ?? 0} °C',
                  ),
                  MetricCard(
                    label: "Quality",
                    icon: Icons.check_circle,
                    value: data['quality'] ?? "N/A",
                    color: Colors.green,
                  ),
                ],
              ),
            ),
      ),
    );
  }
}
