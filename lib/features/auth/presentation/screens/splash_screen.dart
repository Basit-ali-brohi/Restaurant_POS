import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tones.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/providers/bootstrap_provider.dart';
import 'login_screen.dart';

/// SCREEN 1 — Splash. A canvas-drawn gold emblem strokes itself in, settles,
/// then flips cleanly into the Login panel.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _draw;
  late final AnimationController _exit;
  late final Animation<double> _emblem;
  late final Animation<double> _wordmark;
  late final Animation<double> _flip;

  @override
  void initState() {
    super.initState();
    _draw = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _exit = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650));

    _emblem = CurvedAnimation(parent: _draw, curve: Curves.easeInOutCubic);
    _wordmark = CurvedAnimation(
        parent: _draw, curve: const Interval(0.55, 1.0, curve: Curves.easeOut));
    _flip = CurvedAnimation(parent: _exit, curve: Curves.easeInOut);

    _run();
  }

  Future<void> _run() async {
    // Wait for BOTH the emblem to draw in AND real app bootstrap to finish.
    await Future.wait([
      _draw.forward(),
      ref.read(bootstrapProvider.future),
    ]);
    if (!mounted) return;
    await _exit.forward();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, _, _) => const LoginScreen(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _draw.dispose();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTones(ref.watch(themeProvider));

    return Scaffold(
      backgroundColor: t.canvas,
      body: Stack(
        children: [
          // Soft radial gold glow.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.2),
                  radius: 0.9,
                  colors: [
                    AppColors.accent.withValues(alpha: t.isDark ? 0.16 : 0.10),
                    t.canvas,
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_draw, _exit]),
              builder: (context, _) {
                // Flip + lift away on exit.
                final flip = _flip.value * math.pi; // 0 -> half turn
                return Opacity(
                  opacity: 1 - _exit.value,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0012)
                      ..rotateX(flip),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 132,
                          height: 132,
                          child: CustomPaint(
                            painter: _EmblemPainter(progress: _emblem.value),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Opacity(
                          opacity: _wordmark.value,
                          child: Column(
                            children: [
                              Text('CloudPOS Pro',
                                  style: TextStyle(
                                      color: t.textPrimary,
                                      fontSize: 30,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 2)),
                              const SizedBox(height: 4),
                              const Text('MANAGEMENT SUITE',
                                  style: TextStyle(
                                      color: AppColors.accent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 4)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        Opacity(
                          opacity: _wordmark.value,
                          child: SizedBox(
                            width: 120,
                            child: LinearProgressIndicator(
                              minHeight: 2.5,
                              backgroundColor: t.border,
                              valueColor: const AlwaysStoppedAnimation(
                                  AppColors.accent),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Canvas-drawn dining emblem: a gold ring that strokes in, with crossed
/// fork & knife revealed inside.
class _EmblemPainter extends CustomPainter {
  _EmblemPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Ring background.
    final ringBg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = AppColors.accent.withValues(alpha: 0.15);
    canvas.drawCircle(center, radius, ringBg);

    // Ring sweep (draws in with progress).
    final sweep = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        colors: [Color(0xFFB8902A), Color(0xFFEACB62), Color(0xFFB8902A)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      progress * 2 * math.pi,
      false,
      sweep,
    );

    // Cutlery fades/scales in during the second half.
    final reveal = ((progress - 0.4) / 0.6).clamp(0.0, 1.0);
    if (reveal <= 0) return;

    final cutlery = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.2
      ..color = AppColors.accentLight.withValues(alpha: reveal);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    final s = 0.7 + 0.3 * reveal;
    canvas.scale(s, s);

    // Fork (left).
    const forkX = -14.0;
    canvas.drawLine(const Offset(forkX, -22), const Offset(forkX, 18), cutlery);
    for (final dx in [-6.0, 0.0, 6.0]) {
      canvas.drawLine(
          Offset(forkX + dx, -22), Offset(forkX + dx, -8), cutlery);
    }
    canvas.drawLine(
        const Offset(forkX - 6, -8), const Offset(forkX + 6, -8), cutlery);

    // Knife (right).
    const knifeX = 14.0;
    canvas.drawLine(
        const Offset(knifeX, -22), const Offset(knifeX, 18), cutlery);
    final blade = Path()
      ..moveTo(knifeX, -22)
      ..quadraticBezierTo(knifeX + 9, -14, knifeX, -2)
      ..close();
    canvas.drawPath(
        blade,
        Paint()
          ..style = PaintingStyle.fill
          ..color = AppColors.accentLight.withValues(alpha: reveal * 0.5));

    canvas.restore();
  }

  @override
  bool shouldRepaint(_EmblemPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
