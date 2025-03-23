import 'package:flutter/material.dart';

class SignupHeader extends StatelessWidget {
  const SignupHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    Size size = MediaQuery.of(context).size;
    double width = size.width;
    double avatarRadius = width * 0.15;

    return Column(
      children: [
        // Avatar with gradient border
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: isDark
                ? [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ]
                : [
                    theme.colorScheme.primary.withOpacity(0.8),
                    theme.colorScheme.secondary.withOpacity(0.8),
                  ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: CircleAvatar(
            backgroundColor: isDark 
              ? theme.colorScheme.surface 
              : theme.colorScheme.background,
            radius: avatarRadius,
            child: Icon(
              Icons.person,
              size: 80,
              color: theme.colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
        ),
        
        // We'll keep the text if needed, but can be removed if not in login screen
        SizedBox(height: 16),
      ],
    );
  }
}
