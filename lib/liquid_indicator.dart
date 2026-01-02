import 'package:flutter/material.dart';

class LiquidIndicator extends StatelessWidget {
  final double ppm;
  const LiquidIndicator({super.key, required this.ppm});

  @override
  Widget build(BuildContext context) {
    // Map PPM to a color: 0-50 (Blue), 100-300 (Yellow), 500+ (Red)
    Color waterColor = Colors.blue;
    if (ppm > 150) waterColor = Colors.orange;
    if (ppm > 500) waterColor = Colors.redAccent;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              height: 150,
              width: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300, width: 4),
                color: Colors.white,
              ),
            ),
            // Simple fill representation
            ClipOval(
              child: Container(
                height: 140,
                width: 140,
                alignment: Alignment.bottomCenter,
                child: AnimatedContainer(
                  duration: const Duration(seconds: 1),
                  height: (ppm.clamp(0, 1000) / 1000) * 140, // Scale 0-1000 ppm
                  width: 140,
                  color: waterColor.withValues(alpha: 0.6),
                ),
              ),
            ),
            Text(
              "${ppm.toInt()}\nPPM",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          ppm > 300 ? "Filtration Required" : "Safe to Drink",
          style: TextStyle(color: waterColor, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
