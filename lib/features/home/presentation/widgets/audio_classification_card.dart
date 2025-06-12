import 'package:flutter/material.dart';

class AudioClassificationCard extends StatelessWidget {
  final List<String> yamnetPredictions;
  final List<double> yamnetScores;
  final List<String> dangerLabels;

  const AudioClassificationCard({
    Key? key,
    required this.yamnetPredictions,
    required this.yamnetScores,
    required this.dangerLabels,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    // Check if the top prediction is a danger or alert sound
    final isDanger =
        yamnetPredictions.isNotEmpty &&
        dangerLabels.contains(yamnetPredictions[0]);

    return Center(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Container(
          width: screenWidth * 0.9, // Fixed width relative to screen size
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                isDanger
                    ? Colors.red.withOpacity(0.8)
                    : colorScheme.surfaceVariant.withOpacity(0.8),
                isDanger ? Colors.red : colorScheme.surfaceVariant,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isDanger ? Icons.warning : Icons.analytics,
                    size: 24,
                    color: isDanger ? Colors.yellow : Colors.blueAccent,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isDanger ? "Danger Alert!" : "Audio Classification",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDanger ? Colors.yellow : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                "YAMNet Predictions:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (yamnetPredictions.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(yamnetPredictions.length, (index) {
                    final prediction = yamnetPredictions[index];
                    final score = yamnetScores[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prediction,
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurface.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: score,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              score < 0.5
                                  ? Colors.green
                                  : score < 0.8
                                  ? Colors.orange
                                  : Colors.red,
                            ),
                            minHeight: 8,
                          ),
                        ],
                      ),
                    );
                  }),
                )
              else
                Text(
                  "No predictions available.",
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
