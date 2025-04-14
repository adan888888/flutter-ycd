import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(CoinFlipImageApp());
}

class CoinFlipImageApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CoinFlipImagePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CoinFlipImagePage extends StatefulWidget {
  @override
  _CoinFlipImagePageState createState() => _CoinFlipImagePageState();
}

class _CoinFlipImagePageState extends State<CoinFlipImagePage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final Random _rng = Random();

  bool isHeads = true;
  bool isFlipping = false;
  double totalRotation = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ))
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            isHeads = _rng.nextBool();
            isFlipping = false;
            totalRotation = 0;
          });
          _controller.reset();
        }
      });
  }
  void _flipCoin() {
    if (isFlipping) return;

    setState(() {
      isHeads = _rng.nextBool(); // 决定正反面
      isFlipping = true;
    });

    // 动态计算最终角度：N 圈 + 最终角度
    double baseTurns = 5;
    double finalAngle = baseTurns * pi * 2 + (isHeads ? 0 : pi);

    _animation = Tween<double>(begin: 0, end: finalAngle).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut)
    )..addListener(() {
      setState(() {});
    })..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          isFlipping = false;
        });
        _controller.reset();
      }
    });

    _controller.forward();
  }

  Widget _buildCoinFace() {
    double angle = _animation.value;
    bool showHeads = ((angle ~/ pi) % 2 == 0);

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.rotationY(angle),
      child: Image.asset(
        showHeads ? 'assets/images/heads.png' : 'assets/images/tails.png',
        key: ValueKey(showHeads),
        width: 200,
        height: 200,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('🪙 Flip Coin (Realistic Style)')),
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCoinFace(),
            SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _flipCoin,
              icon: Icon(Icons.flip),
              label: Text('Flip Coin'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                textStyle: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
