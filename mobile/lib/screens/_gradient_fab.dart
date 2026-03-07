import 'package:flutter/material.dart';

class GradientFab extends StatefulWidget {
  final VoidCallback onPressed;

  const GradientFab({required this.onPressed, super.key});

  @override
  State<GradientFab> createState() => _GradientFabState();
}

class _GradientFabState extends State<GradientFab>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _pressed = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          _pressed = false;
        });
        widget.onPressed();
      },
      onTapCancel: () {
        setState(() {
          _pressed = false;
        });
      },
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2563EB),
                Color(0xFF4F46E5),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withOpacity(0.35),
                blurRadius: 26,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.add,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}

