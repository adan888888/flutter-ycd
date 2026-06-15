import 'package:flutter/material.dart';

import 'baccarat_playing_card_widget.dart';

/// 闲家/庄家手牌区域，发牌结束后可闪动底包背景
class BaccaratHandPanel extends StatefulWidget {
  const BaccaratHandPanel({
    super.key,
    required this.title,
    required this.cards,
    required this.total,
    required this.color,
    required this.flash,
  });

  final String title;
  final List<Map<String, dynamic>> cards;
  final int total;
  final Color color;
  final bool flash;

  @override
  State<BaccaratHandPanel> createState() => _BaccaratHandPanelState();
}

class _BaccaratHandPanelState extends State<BaccaratHandPanel> with SingleTickerProviderStateMixin {
  late final AnimationController _flashController;
  late final Animation<double> _flash;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _flash = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 25),
    ]).animate(CurvedAnimation(parent: _flashController, curve: Curves.easeInOut));
    if (widget.flash) {
      _flashController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant BaccaratHandPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.flash && !oldWidget.flash) {
      _flashController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _flash,
      builder: (context, child) {
        final pulse = _flash.value;
        return Container(
          padding: const EdgeInsets.all(12),
          constraints: const BoxConstraints(minWidth: 150),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.08 + pulse * 0.34),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.color.withValues(alpha: 0.55 + pulse * 0.45),
              width: 1 + pulse * 2.5,
            ),
            boxShadow: pulse > 0.05
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.25 * pulse),
                      blurRadius: 10 * pulse,
                      spreadRadius: 1.5 * pulse,
                    ),
                  ]
                : null,
          ),
          child: child,
        );
      },
      child: Column(
        children: [
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: widget.color,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 76,
            child: widget.cards.isEmpty
                ? Center(
                    child: Text(
                      '待发牌',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < widget.cards.length; i++)
                        BaccaratPlayingCardWidget(
                          key: ValueKey('${widget.title}_${i}_${widget.cards[i]['display']}'),
                          display: widget.cards[i]['display'] as String,
                          suit: widget.cards[i]['suit'] as String,
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Text(
              widget.cards.isEmpty ? '点数: -' : '点数: ${widget.total}',
              key: ValueKey('${widget.title}-${widget.total}-${widget.cards.length}'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: widget.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
