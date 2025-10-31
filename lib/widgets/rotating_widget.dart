import 'package:flutter/material.dart';

enum RotationEffect { clockwise, counterClockwise, bounce, pulse }

class RotatingWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final RotationEffect effect;
  final bool isAnimating;
  final double turns; // For bounce effect
  final Curve curve;

  const RotatingWidget({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 2),
    this.effect = RotationEffect.clockwise,
    this.isAnimating = true,
    this.turns = 1.0,
    this.curve = Curves.linear,
  });

  @override
  State<RotatingWidget> createState() => _RotatingWidgetState();
}

class _RotatingWidgetState extends State<RotatingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _setupAnimation();
  }

  @override
  void didUpdateWidget(RotatingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration ||
        widget.effect != oldWidget.effect ||
        widget.turns != oldWidget.turns ||
        widget.curve != oldWidget.curve) {
      _controller.duration = widget.duration;
      _setupAnimation();
    }

    if (widget.isAnimating != oldWidget.isAnimating) {
      widget.isAnimating ? _controller.repeat() : _controller.stop();
    }
  }

  void _setupAnimation() {
    final double endValue;
    switch (widget.effect) {
      case RotationEffect.clockwise:
        endValue = 1.0;
        break;
      case RotationEffect.counterClockwise:
        endValue = -1.0;
        break;
      case RotationEffect.bounce:
        endValue = widget.turns * 2;
        break;
      case RotationEffect.pulse:
        endValue = 1.5; // Slight scale up
        break;
    }

    _animation = Tween<double>(
      begin: 0,
      end: endValue,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    if (widget.isAnimating) {
      if (widget.effect == RotationEffect.bounce) {
        _controller.repeat(reverse: true);
      } else {
        _controller.repeat();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isAnimating) return widget.child;

    switch (widget.effect) {
      case RotationEffect.clockwise:
      case RotationEffect.counterClockwise:
        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _controller.value * 2.0 * 3.14159,
              child: child,
            );
          },
          child: widget.child,
        );
      case RotationEffect.bounce:
        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _animation.value * 3.14159,
              child: widget.child,
            );
          },
        );
      case RotationEffect.pulse:
        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + 0.1 * _animation.value,
              child: widget.child,
            );
          },
        );
    }
  }
}
