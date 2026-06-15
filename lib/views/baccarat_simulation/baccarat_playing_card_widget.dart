import 'package:flutter/material.dart';

/// 单张扑克牌展示（带发牌入场动画）
class BaccaratPlayingCardWidget extends StatefulWidget {
  const BaccaratPlayingCardWidget({
    super.key,
    required this.display,
    required this.suit,
  });

  final String display;
  final String suit;

  @override
  State<BaccaratPlayingCardWidget> createState() => _BaccaratPlayingCardWidgetState();
}

class _BaccaratPlayingCardWidgetState extends State<BaccaratPlayingCardWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, -0.55), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _scale = Tween<double>(begin: 0.82, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _suitColor {
    if (widget.suit == '♥' || widget.suit == '♦') {
      return Colors.red.shade700;
    }
    return Colors.black87;
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            width: 52,
            height: 72,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              widget.display,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _suitColor,
                height: 1.1,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
