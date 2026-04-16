import 'package:flutter/material.dart';

class NeonFab extends StatefulWidget {
  final Widget icon;
  final Color color;
  final VoidCallback onTap;
  final double size;

  const NeonFab({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
    this.size = 54,
  });

  @override
  State<NeonFab> createState() => _NeonFabState();
}

class _NeonFabState extends State<NeonFab> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.87 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.6),
                blurRadius: _pressed ? 8 : 26,
              ),
              const BoxShadow(
                color: Colors.black54,
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Center(child: widget.icon),
        ),
      ),
    );
  }
}
