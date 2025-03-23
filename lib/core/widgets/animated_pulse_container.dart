import 'package:flutter/material.dart';

class AnimatedPulseContainer extends StatefulWidget {
  final Widget child;
  final double minScale;
  final double maxScale;
  final Duration duration;
  final BoxDecoration? decoration;
  final EdgeInsetsGeometry padding;
  
  const AnimatedPulseContainer({
    Key? key,
    required this.child,
    this.minScale = 1.0,
    this.maxScale = 1.15,
    this.duration = const Duration(seconds: 2),
    this.decoration,
    this.padding = EdgeInsets.zero,
  }) : super(key: key);
  
  @override
  State<AnimatedPulseContainer> createState() => _AnimatedPulseContainerState();
}

class _AnimatedPulseContainerState extends State<AnimatedPulseContainer> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(
      CurvedAnimation(
        parent: _pulseController, 
        curve: Curves.easeInOut,
      ),
    );
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            decoration: widget.decoration,
            padding: widget.padding,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
