import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'baccarat_simulation_state.dart';

/// 8 副牌换靴洗牌动画：左右各 200 张搓入中间（视觉层叠 + 真实计数）
class BaccaratShuffleOverlay extends StatefulWidget {
  const BaccaratShuffleOverlay({super.key});

  static const Duration animationDuration = Duration(milliseconds: 2800);

  static const double riffleStart = 0.0;
  static const double riffleEnd = 0.88;
  static const double settleStart = 0.88;

  /// 左右牌堆固定横向距离（一开始就在两侧，不再从中间往外分）
  static const double sideStackApart = 108.0;

  /// 左右各 200 张，共 400 张交替搓入中间
  static const int cardsPerSide = 200;
  static const int totalRiffleCards = cardsPerSide * 2;

  /// 侧边/中间最多绘制的可见牌层（避免 400 个 Widget）
  static const int maxVisibleLayers = 12;
  static const int maxCenterTopLayers = 12;

  /// 中间牌堆底部锚点（固定，牌堆向上长高）
  static const double centerStackBottomY = 92;

  @override
  State<BaccaratShuffleOverlay> createState() => _BaccaratShuffleOverlayState();
}

class _BaccaratShuffleOverlayState extends State<BaccaratShuffleOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: BaccaratShuffleOverlay.animationDuration,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _phase(double t, double start, double end) {
    if (t <= start) return 0;
    if (t >= end) return 1;
    return (t - start) / (end - start);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.64),
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _controller.value;
            final riffleT = Curves.linear.transform(
              _phase(t, BaccaratShuffleOverlay.riffleStart, BaccaratShuffleOverlay.riffleEnd),
            );
            final settle = Curves.easeOutCubic.transform(
              _phase(t, BaccaratShuffleOverlay.settleStart, 1.0),
            );
            final riffleDone = t >= BaccaratShuffleOverlay.riffleEnd;

            final cardsProgress = riffleT * BaccaratShuffleOverlay.totalRiffleCards;
            final landedCount = cardsProgress.floor().clamp(0, BaccaratShuffleOverlay.totalRiffleCards);
            final flying = cardsProgress - landedCount;
            final isFlying = flying > 0.001 && landedCount < BaccaratShuffleOverlay.totalRiffleCards;
            final flyingFromLeft = landedCount.isEven;

            final leftOnStack = _remainingOnStack(
              dealtSideCount: (landedCount + 1) ~/ 2,
              isFlyingFromThisSide: isFlying && flyingFromLeft,
            );
            final rightOnStack = _remainingOnStack(
              dealtSideCount: landedCount ~/ 2,
              isFlyingFromThisSide: isFlying && !flyingFromLeft,
            );

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 340,
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      if (settle < 0.98) ...[
                        _buildSideStack(isLeft: true, count: leftOnStack),
                        _buildSideStack(isLeft: false, count: rightOnStack),
                        _buildCenterPile(landedCount),
                        if (isFlying)
                          _buildFlyingCard(
                            fromLeft: flyingFromLeft,
                            progress: Curves.easeInOut.transform(flying.clamp(0.0, 1.0)),
                            landedCount: landedCount,
                            sideCount: flyingFromLeft ? leftOnStack : rightOnStack,
                          ),
                      ],
                      if (settle > 0.05) _buildFinalDeck(settle),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  riffleDone && settle > 0.85 ? '洗牌完成' : '正在洗牌...',
                  style: TextStyle(
                    color: Colors.amber.shade100,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${BaccaratSimulationState.shoeDeckCount}副牌 · ${BaccaratSimulationState.shoeTotalCards}张'
                  '${!riffleDone ? ' · $landedCount/${BaccaratShuffleOverlay.totalRiffleCards}' : ''}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 15,
                  ),
                ),
                if (!riffleDone)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '左 $leftOnStack 张 · 右 $rightOnStack 张',
                      style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.55)),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  int _remainingOnStack({required int dealtSideCount, required bool isFlyingFromThisSide}) {
    var remain = BaccaratShuffleOverlay.cardsPerSide - dealtSideCount;
    if (isFlyingFromThisSide) remain -= 1;
    return remain.clamp(0, BaccaratShuffleOverlay.cardsPerSide);
  }

  Offset _sideStackOrigin(bool isLeft, int count) {
    // 牌堆越搓越少，位置略向中间收拢，强化「两边 → 中间」
    final ratio = count / BaccaratShuffleOverlay.cardsPerSide;
    final apart = BaccaratShuffleOverlay.sideStackApart * (0.4 + 0.6 * ratio);
    return Offset(isLeft ? -apart : apart, -22);
  }

  double _centerBulkHeight(int landedCount) {
    final ratio = landedCount / BaccaratShuffleOverlay.totalRiffleCards;
    return 14 + ratio * 86;
  }

  double _centerStackTop(int landedCount) {
    return BaccaratShuffleOverlay.centerStackBottomY - _centerBulkHeight(landedCount);
  }

  Offset _centerTopCardOffset(int layerIndex) {
    return Offset(
      (layerIndex % 2 == 0 ? -1 : 1) * (layerIndex % 3 + 1) * 0.45,
      -layerIndex * 1.05,
    );
  }

  Widget _buildSideStack({
    required bool isLeft,
    required int count,
  }) {
    if (count <= 0) return const SizedBox.shrink();

    final origin = _sideStackOrigin(isLeft, count);
    const tilt = 0.14;
    final ratio = count / BaccaratShuffleOverlay.cardsPerSide;
    final bulkHeight = 18 + ratio * 82;
    final visibleLayers = math.min(count, BaccaratShuffleOverlay.maxVisibleLayers);

    return Transform.translate(
      offset: origin,
      child: Transform.rotate(
        angle: isLeft ? -tilt : tilt,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              width: 48,
              height: bulkHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isLeft
                      ? [Colors.red.shade900.withValues(alpha: 0.55), Colors.red.shade800]
                      : [Colors.blue.shade900.withValues(alpha: 0.55), Colors.blue.shade800],
                ),
                border: Border.all(color: Colors.white24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
            for (var i = 0; i < visibleLayers; i++)
              Transform.translate(
                offset: Offset(i * (isLeft ? -0.7 : 0.7), -i * 1.0 - 4),
                child: _miniCardBack(fromLeft: isLeft, compact: true),
              ),
            if (count > BaccaratShuffleOverlay.maxVisibleLayers)
              Positioned(
                bottom: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterPile(int landedCount) {
    if (landedCount <= 0) return const SizedBox.shrink();

    final bulkHeight = _centerBulkHeight(landedCount);
    final topLayers = math.min(landedCount, BaccaratShuffleOverlay.maxCenterTopLayers);
    final startIndex = landedCount - topLayers;
    final internalLayers = math.min(10, (bulkHeight / 3.5).floor());

    return Transform.translate(
      offset: Offset(0, BaccaratShuffleOverlay.centerStackBottomY - bulkHeight),
      child: SizedBox(
        width: 54,
        height: bulkHeight,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              left: 0,
              bottom: 0,
              child: Container(
                width: 4,
                height: bulkHeight,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(2)),
                  color: Colors.white.withValues(alpha: 0.35),
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 4,
                height: bulkHeight,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(2)),
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: 50,
                height: bulkHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.red.shade800.withValues(alpha: 0.75),
                      Colors.purple.shade900.withValues(alpha: 0.6),
                      Colors.blue.shade900.withValues(alpha: 0.85),
                    ],
                  ),
                  border: Border.all(color: Colors.white24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.32),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
            for (var i = 0; i < internalLayers; i++)
              Positioned(
                bottom: 3 + i * 3.2,
                left: 4,
                right: 4,
                child: Container(
                  height: 2.2,
                  decoration: BoxDecoration(
                    color: (i.isEven ? Colors.red : Colors.blue).withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            for (var i = 0; i < topLayers; i++)
              Positioned(
                bottom: bulkHeight - 62 + i * 1.05,
                left: 27 - 22 + _centerTopCardOffset(i).dx,
                child: _miniCardBack(fromLeft: (startIndex + i).isEven, compact: true),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlyingCard({
    required bool fromLeft,
    required double progress,
    required int landedCount,
    required int sideCount,
  }) {
    final start = _sideStackOrigin(fromLeft, sideCount + 1);
    final end = Offset(0, _centerStackTop(landedCount));
    final arc = math.sin(progress * math.pi) * -12;
    final pos = Offset(
      start.dx + (end.dx - start.dx) * progress,
      start.dy + (end.dy - start.dy) * progress + arc,
    );
    final rotate = (fromLeft ? -0.18 : 0.18) * (1 - progress);

    return Transform.translate(
      offset: pos,
      child: Transform.rotate(
        angle: rotate,
        child: _miniCardBack(fromLeft: fromLeft, compact: true),
      ),
    );
  }

  Widget _buildFinalDeck(double settle) {
    final visible = settle.clamp(0.0, 1.0);
    return Transform.scale(
      scale: 0.84 + visible * 0.16,
      child: Opacity(
        opacity: visible,
        child: Container(
          width: 78,
          height: 104,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.red.shade800, Colors.blue.shade900],
            ),
            border: Border.all(color: Colors.amber.shade200, width: 1.6),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withValues(alpha: 0.25),
                blurRadius: 16,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.casino, color: Colors.amber.shade100, size: 28),
              const SizedBox(height: 6),
              Text(
                '8副',
                style: TextStyle(
                  color: Colors.amber.shade100,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniCardBack({required bool fromLeft, bool compact = false}) {
    final colors = fromLeft
        ? [Colors.red.shade700, Colors.red.shade900]
        : [Colors.blue.shade700, Colors.blue.shade900];

    return Container(
      width: compact ? 44 : 52,
      height: compact ? 62 : 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.75), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _DiamondPatternPainter(
          color: Colors.white.withValues(alpha: fromLeft ? 0.16 : 0.12),
        ),
      ),
    );
  }
}

class _DiamondPatternPainter extends CustomPainter {
  _DiamondPatternPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final cx = size.width / 2;
    final cy = size.height / 2;
    const d = 7.0;
    for (var row = -2; row <= 2; row++) {
      for (var col = -1; col <= 1; col++) {
        final ox = cx + col * d * 2.2;
        final oy = cy + row * d * 1.6;
        final path = Path()
          ..moveTo(ox, oy - d)
          ..lineTo(ox + d, oy)
          ..lineTo(ox, oy + d)
          ..lineTo(ox - d, oy)
          ..close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DiamondPatternPainter oldDelegate) => false;
}
