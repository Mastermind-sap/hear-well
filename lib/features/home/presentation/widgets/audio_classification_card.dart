import 'package:flutter/material.dart';

class AudioClassificationCard extends StatelessWidget {
  final List<String> yamnetPredictions;
  final List<double> yamnetScores;

  const AudioClassificationCard({
    Key? key,
    required this.yamnetPredictions,
    required this.yamnetScores,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

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
                colorScheme.surfaceVariant.withOpacity(0.8),
                colorScheme.surfaceVariant,
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
                  const Icon(
                    Icons.analytics,
                    size: 24,
                    color: Colors.blueAccent,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Audio Classification",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
