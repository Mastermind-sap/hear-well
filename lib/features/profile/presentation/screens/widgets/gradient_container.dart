import 'package:flutter/material.dart';

class GradientContainer extends StatelessWidget {
  final Widget child;
  final BorderRadius? borderRadius;
  final List<Color>? gradientColors;
  final EdgeInsetsGeometry padding;
  final double? height;
  final double? width;
  final BoxShape shape;

  const GradientContainer({
    Key? key,
    required this.child,
    this.borderRadius,
    this.gradientColors,
    this.padding = const EdgeInsets.all(16.0),
    this.height,
    this.width,
    this.shape = BoxShape.rectangle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Default gradient based on theme
    final defaultGradient = isDarkMode
        ? [Colors.grey.shade900, Colors.grey.shade800]
        : [Colors.blue.shade400, Colors.blue.shade600];
    
    return Container(
      height: height,
      width: width,
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors ?? defaultGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: shape == BoxShape.rectangle ? (borderRadius ?? BorderRadius.circular(16)) : null,
        shape: shape,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
