import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:life_os/features/mirror/models/star.dart';

class NebulaCanvas extends StatefulWidget {
  final List<Star> stars;
  final List<StarThread> threads;
  final Function(Star) onStarTapped;
  final Star? selectedStar;

  const NebulaCanvas({
    super.key,
    required this.stars,
    required this.threads,
    required this.onStarTapped,
    this.selectedStar,
  });

  @override
  State<NebulaCanvas> createState() => _NebulaCanvasState();
}

class _NebulaCanvasState extends State<NebulaCanvas> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  DateTime _lastTime = DateTime.now();
  double _pulsePhase = 0;
  
  // "The Pulse" wave
  Offset? _pulseOrigin;
  double _pulseRadius = 0;
  double _pulseStrength = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _controller.addListener(_onTick);
  }

  void _onTick() {
    final now = DateTime.now();
    final dt = (now.difference(_lastTime).inMilliseconds / 1000.0).clamp(0.0, 0.1);
    _lastTime = now;
    _pulsePhase += dt * 0.8; // Slow pulse

    // Animate "The Pulse" wave
    if (_pulseStrength > 0) {
      _pulseRadius += dt * 400; // Wave speed
      _pulseStrength -= dt * 0.8; // Fade out
      if (_pulseStrength < 0) {
        _pulseStrength = 0;
        _pulseOrigin = null;
      }
    }

    if (mounted) {
      final size = MediaQuery.of(context).size;
      for (final star in widget.stars) {
        // Apply repulsion from pulse wave
        if (_pulseOrigin != null && _pulseStrength > 0) {
          final distToOrigin = (star.position - _pulseOrigin!).distance;
          final waveHitZone = _pulseRadius;
          if ((distToOrigin - waveHitZone).abs() < 50) {
            final direction = (star.position - _pulseOrigin!);
            if (direction.distance > 0) {
              final normalized = direction / direction.distance;
              star.velocity += normalized * _pulseStrength * 30;
            }
          }
        }
        
        // Apply drag to slow down stars gradually
        star.velocity = star.velocity * 0.995;
        star.update(size, dt);
      }
      setState(() {});
    }
  }

  void _triggerPulse(Offset origin) {
    HapticFeedback.heavyImpact();
    setState(() {
      _pulseOrigin = origin;
      _pulseRadius = 0;
      _pulseStrength = 1.0;
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) => _handleTap(details.localPosition),
      onLongPressStart: (details) => _triggerPulse(details.localPosition),
      child: CustomPaint(
        painter: _NebulaPainter(
          stars: widget.stars,
          threads: widget.threads,
          pulsePhase: _pulsePhase,
          pulseOrigin: _pulseOrigin,
          pulseRadius: _pulseRadius,
          pulseStrength: _pulseStrength,
          selectedStar: widget.selectedStar,
        ),
        size: Size.infinite,
      ),
    );
  }

  void _handleTap(Offset tapPosition) {
    for (final star in widget.stars) {
      final distance = (star.position - tapPosition).distance;
      if (distance < star.radius + 20) { // Touch padding
        widget.onStarTapped(star);
        return;
      }
    }
  }
}

class _NebulaPainter extends CustomPainter {
  final List<Star> stars;
  final List<StarThread> threads;
  final double pulsePhase;
  final Offset? pulseOrigin;
  final double pulseRadius;
  final double pulseStrength;
  final Star? selectedStar;

  _NebulaPainter({
    required this.stars,
    required this.threads,
    required this.pulsePhase,
    this.pulseOrigin,
    this.pulseRadius = 0,
    this.pulseStrength = 0,
    this.selectedStar,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw "The Pulse" wave
    if (pulseOrigin != null && pulseStrength > 0) {
      final wavePaint = Paint()
        ..color = Colors.white.withValues(alpha: pulseStrength * 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 + pulseStrength * 5
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10 + pulseStrength * 20);
      canvas.drawCircle(pulseOrigin!, pulseRadius, wavePaint);
    }

    // Draw smart correlation threads (from computed correlations)
    for (final thread in threads) {
      final pulse = 0.7 + 0.3 * sin(pulsePhase * 0.5);
      
      // Gradient color based on cross-type vs same-type
      final isCrossType = thread.star1.type != thread.star2.type;
      final baseColor = isCrossType 
          ? Colors.white 
          : thread.star1.color;
      
      final paint = Paint()
        ..color = baseColor.withValues(alpha: thread.strength * 0.4 * pulse * (selectedStar != null ? 1.5 : 1))
        ..strokeWidth = (selectedStar != null && (thread.star1 == selectedStar || thread.star2 == selectedStar))
            ? 2 + thread.strength * 4
            : 1 + thread.strength * 2
        ..style = PaintingStyle.stroke
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 + thread.strength * 3);
      
      // If a star is selected, only draw threads connected to it brightly
      if (selectedStar != null) {
        if (thread.star1 == selectedStar || thread.star2 == selectedStar) {
          paint.color = baseColor.withValues(alpha: thread.strength * 0.8 * pulse);
        } else {
          paint.color = baseColor.withValues(alpha: thread.strength * 0.1 * pulse);
        }
      }
      
      canvas.drawLine(thread.star1.position, thread.star2.position, paint);
    }

    // Draw stars
    for (final star in stars) {
      final pulse = 0.8 + 0.2 * sin(pulsePhase + star.position.dx * 0.01);
      
      // Core
      final isInsight = star.type == StarType.insight;
      final color = isInsight ? const Color(0xFFFFD700) : star.color;
      final corePulse = isInsight ? (1.2 + 0.3 * sin(pulsePhase * 1.5)) : pulse;

      // Dim stars that aren't the selected one or connected to it
      double opacityMultiplier = 1.0;
      if (selectedStar != null) {
        final isRelated = threads.any((t) => 
          (t.star1 == selectedStar && t.star2 == star) || 
          (t.star2 == selectedStar && t.star1 == star)
        );
        if (star != selectedStar && !isRelated) {
          opacityMultiplier = 0.2;
        } else if (star == selectedStar) {
          opacityMultiplier = 1.5;
        }
      }

      // Outer glow (large, soft)
      final glowPaint = Paint()
        ..color = color.withValues(alpha: (isInsight ? 0.3 : 0.15) * corePulse * opacityMultiplier.clamp(0, 1))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, star.radius * (isInsight ? 5 : 3));
      canvas.drawCircle(star.position, star.radius * (isInsight ? 3 : 2), glowPaint);

      // Mid glow
      final midGlowPaint = Paint()
        ..color = color.withValues(alpha: (isInsight ? 0.5 : 0.3) * corePulse * opacityMultiplier.clamp(0, 1))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, star.radius * (isInsight ? 2.5 : 1.5));
      canvas.drawCircle(star.position, star.radius * (isInsight ? 1.8 : 1.2), midGlowPaint);

      final corePaint = Paint()
        ..color = color.withValues(alpha: (0.7 + 0.3 * corePulse) * opacityMultiplier.clamp(0, 1))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, star.radius * 0.3);
      canvas.drawCircle(star.position, star.radius * corePulse, corePaint);

      // Bright center point
      final centerPaint = Paint()
        ..color = Colors.white.withValues(alpha: (0.6 + 0.4 * corePulse) * opacityMultiplier.clamp(0, 1));
      canvas.drawCircle(star.position, star.radius * 0.25 * corePulse, centerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _NebulaPainter oldDelegate) => true;
}
