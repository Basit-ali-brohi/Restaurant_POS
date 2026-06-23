import 'dart:math';
import 'package:flutter/material.dart';

class AnimatedMeshGradient extends StatefulWidget {
  final bool isDarkMode;
  const AnimatedMeshGradient({super.key, this.isDarkMode = true});

  @override
  State<AnimatedMeshGradient> createState() => _AnimatedMeshGradientState();
}

class _AnimatedMeshGradientState extends State<AnimatedMeshGradient>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  // Define 4 moving points
  late List<MeshPoint> _points;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
    
    _updatePoints();
  }

  @override
  void didUpdateWidget(AnimatedMeshGradient oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDarkMode != widget.isDarkMode) {
      _updatePoints();
    }
  }

  void _updatePoints() {
    if (widget.isDarkMode) {
      _points = [
        MeshPoint(color: const Color(0xFF1E293B), offset: const Offset(0.2, 0.2)),
        MeshPoint(color: const Color(0xFF0F172A), offset: const Offset(0.8, 0.2)),
        MeshPoint(color: const Color(0xFF334155), offset: const Offset(0.2, 0.8)),
        MeshPoint(color: const Color(0xFF1E1E2E), offset: const Offset(0.8, 0.8)),
      ];
    } else {
      _points = [
        MeshPoint(color: const Color(0xFFE2E8F0), offset: const Offset(0.2, 0.2)),
        MeshPoint(color: const Color(0xFFF1F5F9), offset: const Offset(0.8, 0.2)),
        MeshPoint(color: const Color(0xFFCBD5E1), offset: const Offset(0.2, 0.8)),
        MeshPoint(color: const Color(0xFFF8FAFC), offset: const Offset(0.8, 0.8)),
      ];
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _MeshGradientPainter(
            progress: _controller.value,
            points: _points,
            isDarkMode: widget.isDarkMode,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class MeshPoint {
  final Color color;
  final Offset offset;
  
  MeshPoint({required this.color, required this.offset});
}

class _MeshGradientPainter extends CustomPainter {
  final double progress;
  final List<MeshPoint> points;
  final bool isDarkMode;

  _MeshGradientPainter({required this.progress, required this.points, required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..blendMode = BlendMode.screen;

    // Base background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC), // Deep Slate vs Light Gray
    );

    // Animate points
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      
      // Calculate animated position using sine waves for organic movement
      final double dx = point.offset.dx + 
          sin(progress * 2 * pi + i) * 0.15;
      final double dy = point.offset.dy + 
          cos(progress * 2 * pi + i * 1.5) * 0.15;
          
      final center = Offset(dx * size.width, dy * size.height);
      final radius = size.width * 0.8;

      final gradient = RadialGradient(
        colors: [
          point.color.withOpacity(0.6),
          point.color.withOpacity(0.0),
        ],
        radius: 0.8,
      );

      paint.shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      );

      canvas.drawCircle(center, radius, paint);
    }
    
    // Optional: Add a subtle overlay for blending
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..blendMode = BlendMode.overlay,
    );
  }

  @override
  bool shouldRepaint(covariant _MeshGradientPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
