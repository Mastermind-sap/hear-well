import 'package:echo_aid/core/widgets/pulsing_dot_widget.dart';
import 'package:flutter/material.dart';

class ScanningStatusIndicator extends StatelessWidget {
  final String message;
  final Color color;
  
  const ScanningStatusIndicator({
    Key? key,
    required this.message,
    required this.color,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: PulsingDotWidget(color: color),
          ),
          const SizedBox(width: 12),
          Text(
            message,
            style: theme.textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
