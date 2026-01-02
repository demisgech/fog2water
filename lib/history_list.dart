import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistoryList extends StatelessWidget {
  final List<Map<String, dynamic>> history;
  final void Function(int index) onDelete;
  final VoidCallback? onClearAll;

  const HistoryList({
    super.key,
    required this.history,
    required this.onDelete,
    this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    // Sort to show newest readings at the top
    final sortedHistory = [...history]
      ..sort(
        (a, b) =>
            (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime),
      );

    if (sortedHistory.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.auto_graph, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              "No readings recorded yet",
              style: TextStyle(
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedHistory.length,
          itemBuilder: (_, index) {
            final record = sortedHistory[index];
            final timestamp = record['timestamp'] as DateTime;
            final double ppm = (record['ppm'] ?? 0).toDouble();

            // Logic to determine color based on PPM
            Color statusColor = ppm < 150
                ? Colors.teal
                : (ppm < 400 ? Colors.orange : Colors.redAccent);

            return IntrinsicHeight(
              child: Row(
                children: [
                  // --- Timeline Visual Area ---
                  Column(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: statusColor.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Container(
                          width: 2,
                          color: index == sortedHistory.length - 1
                              ? Colors.transparent
                              : Colors.grey.shade200,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),

                  // --- Content Card Area ---
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      "${ppm.toInt()} PPM",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildQualityChip(
                                      record['quality'],
                                      statusColor,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat(
                                    'hh:mm a • MMM dd',
                                  ).format(timestamp),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.grey.shade400,
                            ),
                            onPressed: () => onDelete(index),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildQualityChip(String? quality, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        (quality ?? "N/A").toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
