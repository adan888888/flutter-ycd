import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// 今日下注目标达成庆祝弹窗：彩带迸发 + 奖杯弹入 + 旋转光芒 + 数字滚动。
class DailyGoalCelebrationDialog extends StatefulWidget {
  const DailyGoalCelebrationDialog({
    super.key,
    required this.count,
    required this.goal,
    this.isDarkMode = false,
  });

  final int count;
  final int goal;
  final bool isDarkMode;

  static Future<void> show({
    required int count,
    required int goal,
    bool isDarkMode = false,
  }) {
    HapticFeedback.mediumImpact();
    return Get.generalDialog<void>(
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: isDarkMode ? 0.66 : 0.48),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => DailyGoalCelebrationDialog(
        count: count,
        goal: goal,
        isDarkMode: isDarkMode,
      ),
      transitionBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
    );
  }

  @override
  State<DailyGoalCelebrationDialog> createState() => _DailyGoalCelebrationDialogState();
}

class _DailyGoalCelebrationDialogState extends State<DailyGoalCelebrationDialog> with TickerProviderStateMixin {
  static const _violet = Color(0xFF7B6CFF);
  static const _blue = Color(0xFF6E9CFF);
  static const _gold = Color(0xFFFFC53D);
  static const _orange = Color(0xFFFF9F1C);
  static const _confettiSeconds = 3.2;

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();
  late final AnimationController _confetti = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..forward();
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  late final List<_ConfettiParticle> _particles = _ConfettiParticle.burst(math.Random());

  Animation<double> _interval(double begin, double end, Curve curve) =>
      CurvedAnimation(parent: _entrance, curve: Interval(begin, end, curve: curve));

  late final _cardScale = Tween(begin: 0.72, end: 1.0).animate(_interval(0, 0.6, Curves.elasticOut));
  late final _cardFade = _interval(0, 0.25, Curves.easeOut);
  late final _trophyScale = _interval(0.18, 0.75, Curves.elasticOut);
  late final _textReveal = _interval(0.4, 0.8, Curves.easeOutCubic);
  late final _countUp = _interval(0.4, 0.95, Curves.easeOutCubic);
  late final _buttonReveal = _interval(0.6, 1, Curves.easeOutBack);

  @override
  void dispose() {
    _entrance.dispose();
    _confetti.dispose();
    _ambient.dispose();
    super.dispose();
  }

  void _close() {
    HapticFeedback.selectionClick();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final screen = MediaQuery.sizeOf(context);
    final cardWidth = math.min(screen.width - 56, 320.0);

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: _close),
          ),
          Center(
            child: FadeTransition(
              opacity: _cardFade,
              child: ScaleTransition(
                scale: _cardScale,
                child: GestureDetector(
                  onTap: () {},
                  child: _buildCard(cardWidth, isDark),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _confetti,
                builder: (_, __) => CustomPaint(
                  painter: _ConfettiPainter(
                    particles: _particles,
                    elapsed: _confetti.value * _confettiSeconds,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(double width, bool isDark) {
    final surface = isDark ? const Color(0xFF16212F) : Colors.white;
    final primaryText = isDark ? const Color(0xFFF5F7FA) : const Color(0xFF0B072B);
    final secondaryText = isDark ? const Color(0xFFAAB3C1) : const Color(0xFF6B7280);
    final chipFill = isDark ? const Color(0xFF1C2939) : const Color(0xFFF3F8FF);
    final border = isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE9EBF4);

    return Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(surface, _gold, isDark ? 0.10 : 0.14)!,
            surface,
            surface,
          ],
          stops: const [0, 0.42, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: _violet.withValues(alpha: isDark ? 0.35 : 0.25),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 150, child: _buildTrophy()),
          _reveal(
            Text(
              '今日目标达成！',
              style: TextStyle(
                color: primaryText,
                fontSize: 23,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _reveal(
            Text(
              '坚持就是最稳的策略，今天辛苦啦',
              textAlign: TextAlign.center,
              style: TextStyle(color: secondaryText, fontSize: 13.5, height: 1.4),
            ),
          ),
          const SizedBox(height: 16),
          _reveal(_buildStatChip(chipFill, border, primaryText, secondaryText)),
          const SizedBox(height: 20),
          ScaleTransition(
            scale: _buttonReveal,
            child: _buildButton(),
          ),
        ],
      ),
    );
  }

  Widget _reveal(Widget child) {
    return AnimatedBuilder(
      animation: _textReveal,
      builder: (_, c) => Opacity(
        opacity: _textReveal.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - _textReveal.value)),
          child: c,
        ),
      ),
      child: child,
    );
  }

  Widget _buildTrophy() {
    return AnimatedBuilder(
      animation: Listenable.merge([_ambient, _trophyScale]),
      builder: (_, __) {
        final spin = _ambient.value * 2 * math.pi;
        final pulse = 1 + 0.04 * math.sin(spin * 3);
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Transform.rotate(
              angle: spin,
              child: CustomPaint(
                size: const Size.square(190),
                painter: _RaysPainter(
                  color: _gold.withValues(alpha: widget.isDarkMode ? 0.22 : 0.30),
                ),
              ),
            ),
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _gold.withValues(alpha: 0.45),
                    _gold.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
            ..._sparkles(spin),
            Transform.scale(
              scale: _trophyScale.value * pulse,
              child: Transform.rotate(
                angle: 0.25 * (1 - _trophyScale.value.clamp(0.0, 1.0)),
                child: ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFE58A), _gold, _orange],
                  ).createShader(bounds),
                  child: const Icon(Icons.emoji_events_rounded, size: 84),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _sparkles(double spin) {
    const spots = [
      (Offset(-58, -34), 16.0, 0.0),
      (Offset(60, -44), 12.0, 1.7),
      (Offset(54, 30), 14.0, 3.1),
      (Offset(-50, 38), 10.0, 4.4),
    ];
    return [
      for (final (offset, size, phase) in spots)
        Transform.translate(
          offset: offset,
          child: Opacity(
            opacity: (0.35 + 0.65 * (0.5 + 0.5 * math.sin(spin * 4 + phase))) * _trophyScale.value.clamp(0.0, 1.0),
            child: Icon(Icons.auto_awesome, size: size, color: _gold),
          ),
        ),
    ];
  }

  Widget _buildStatChip(Color fill, Color border, Color primaryText, Color secondaryText) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: AnimatedBuilder(
        animation: _countUp,
        builder: (_, __) {
          final shown = (widget.count * _countUp.value).round();
          return FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('已完成', style: TextStyle(color: secondaryText, fontSize: 13)),
                const SizedBox(width: 8),
                Text(
                  '$shown',
                  style: const TextStyle(
                    color: _violet,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  ' / ${widget.goal}',
                  style: TextStyle(color: primaryText, fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 6),
                Text('次下注', style: TextStyle(color: secondaryText, fontSize: 13)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildButton() {
    return GestureDetector(
      onTap: _close,
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(23),
          gradient: const LinearGradient(colors: [_violet, _blue]),
          boxShadow: [
            BoxShadow(
              color: _violet.withValues(alpha: 0.4),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Text(
          '太棒了，继续保持',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _RaysPainter extends CustomPainter {
  _RaysPainter({required this.color});

  final Color color;

  static const _rayCount = 12;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, color.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    const sweep = math.pi / _rayCount;
    for (var i = 0; i < _rayCount; i++) {
      final start = i * 2 * sweep;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(Rect.fromCircle(center: center, radius: radius), start, sweep, false)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RaysPainter oldDelegate) => oldDelegate.color != color;
}

class _ConfettiParticle {
  _ConfettiParticle({
    required this.origin,
    required this.velocity,
    required this.delay,
    required this.life,
    required this.color,
    required this.size,
    required this.rotation,
    required this.spin,
    required this.flip,
    required this.isCircle,
  });

  /// 相对画布的发射点（0~1）
  final Offset origin;
  final Offset velocity;
  final double delay;
  final double life;
  final Color color;
  final Size size;
  final double rotation;
  final double spin;
  final double flip;
  final bool isCircle;

  static const _colors = [
    Color(0xFF7B6CFF),
    Color(0xFFFFC53D),
    Color(0xFFFF6B8B),
    Color(0xFF4CD4B0),
    Color(0xFF6E9CFF),
    Color(0xFFFF9F1C),
  ];

  static List<_ConfettiParticle> burst(math.Random random) {
    double between(double a, double b) => a + random.nextDouble() * (b - a);

    _ConfettiParticle make(Offset origin, double angle, double speed, double delay) {
      return _ConfettiParticle(
        origin: origin,
        velocity: Offset(math.cos(angle), math.sin(angle)) * speed,
        delay: delay,
        life: between(2.0, 2.8),
        color: _colors[random.nextInt(_colors.length)],
        size: Size(between(6, 10), between(3.5, 5.5)),
        rotation: between(0, 2 * math.pi),
        spin: between(-8, 8),
        flip: between(4, 12),
        isCircle: random.nextDouble() < 0.22,
      );
    }

    return [
      for (var i = 0; i < 56; i++)
        make(
          const Offset(0.5, 0.36),
          -math.pi / 2 + between(-1.35, 1.35),
          between(420, 980),
          between(0, 0.08),
        ),
      for (var i = 0; i < 30; i++)
        make(
          const Offset(0.0, 1.0),
          -math.pi / 2 + between(0.25, 0.75),
          between(900, 1400),
          between(0.12, 0.3),
        ),
      for (var i = 0; i < 30; i++)
        make(
          const Offset(1.0, 1.0),
          -math.pi / 2 - between(0.25, 0.75),
          between(900, 1400),
          between(0.12, 0.3),
        ),
    ];
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.particles, required this.elapsed});

  final List<_ConfettiParticle> particles;
  final double elapsed;

  static const _drag = 1.7;
  static const _gravity = 620.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in particles) {
      final t = elapsed - p.delay;
      if (t <= 0 || t >= p.life) continue;

      final damp = (1 - math.exp(-_drag * t)) / _drag;
      final x = p.origin.dx * size.width + p.velocity.dx * damp;
      final y = p.origin.dy * size.height + p.velocity.dy * damp + 0.5 * _gravity * t * t * 0.55;
      final fade = t > p.life * 0.7 ? 1 - (t - p.life * 0.7) / (p.life * 0.3) : 1.0;

      paint.color = p.color.withValues(alpha: fade.clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation + p.spin * t);
      canvas.scale(math.cos(p.flip * t), 1);
      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size.height * 0.75, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: p.size.width, height: p.size.height),
            const Radius.circular(1.2),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => oldDelegate.elapsed != elapsed;
}
