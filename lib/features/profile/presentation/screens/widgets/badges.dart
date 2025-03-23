import 'package:flutter/material.dart';

class Badges extends StatelessWidget {
  final String badge;
  const Badges({
    required this.badge,
    super.key});

  @override
  Widget build(BuildContext context) {
     final Map<String, IconData> badgeIcons = {
      'first_time': Icons.stars,
      'power_user': Icons.bolt,
      'weekly_streak': Icons.calendar_today,
      'explorer': Icons.explore,
      // Add more mappings as needed
    };
    
    final Map<String, Color> badgeColors = {
      'first_time': Colors.amber,
      'power_user': Colors.redAccent,
      'weekly_streak': Colors.greenAccent,
      'explorer': Colors.purpleAccent,
      // Add more mappings as needed
    };

    return Container(
      width: 80,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              shape: BoxShape.circle,
            ),
            child: Icon(
              badgeIcons[badge] ?? Icons.emoji_events,
              color: badgeColors[badge] ?? Colors.amber,
              size: 24,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _formatBadgeName(badge),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatBadgeName(String badge) {
    // Convert snake_case to Title Case
    return badge
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}