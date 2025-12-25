import 'package:flutter/material.dart';

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
    final sortedHistory = [...history]
      ..sort(
        (a, b) =>
            (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime),
      );

    if (sortedHistory.isEmpty) {
      return const Center(
        child: Text("No history available", style: TextStyle(fontSize: 16)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (onClearAll != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onClearAll,
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              label: const Text(
                "Clear All",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedHistory.length,
          itemBuilder: (_, index) {
            final record = sortedHistory[index];
            final timestamp = record['timestamp'] as DateTime;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: const Icon(Icons.history),
                title: Text("PPM: ${record['ppm']}"),
                subtitle: Text(
                  "Quality: ${record['quality']} • ${timestamp.toLocal()}",
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => onDelete(index),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
