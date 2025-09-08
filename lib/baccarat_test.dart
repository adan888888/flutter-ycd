import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const BaccaratSimulatorApp());

class BaccaratSimulatorApp extends StatelessWidget {
  const BaccaratSimulatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: BaccaratSimulatorPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class BaccaratSimulatorPage extends StatefulWidget {
  const BaccaratSimulatorPage({super.key});

  @override
  State<BaccaratSimulatorPage> createState() => _BaccaratSimulatorPageState();
}

class _BaccaratSimulatorPageState extends State<BaccaratSimulatorPage> {
  final Random _rng = Random();
  int totalRounds = 100000;

  int wins = 0;
  int losses = 0;
  int push = 0;

  void runSimulation() {
    int win = 0;
    int lose = 0;

    for (int i = 0; i < totalRounds; i++) {
      // 模拟下注：60% 押庄，40% 押闲
      bool betBanker = _rng.nextDouble() < 0.8;

      // 模拟开牌：真实概率（不含和）
      bool outcomeBanker = _rng.nextDouble() < 0.5068;

      if (betBanker == outcomeBanker) {
        win++;
      } else {
        lose++;
      }
    }

    setState(() {
      wins = win;
      losses = lose;
    });
  }

  @override
  void initState() {
    super.initState();
    runSimulation();
  }

  @override
  Widget build(BuildContext context) {
    final winRate = (wins / totalRounds * 100).toStringAsFixed(2);
    final winLossDiff = wins - losses;

    return Scaffold(
      appBar: AppBar(title: const Text('🎲 Baccarat Simulation')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('模拟局数: $totalRounds', style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 20),
              Text('✔️ 赢了: $wins',
                  style: const TextStyle(fontSize: 20, color: Colors.green)),
              Text('❌ 输了: $losses',
                  style: const TextStyle(fontSize: 20, color: Colors.red)),
              const SizedBox(height: 20),
              Text('📊 胜率: $winRate%',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              Text('🏆 赢比输多: $winLossDiff 局',
                  style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: const Icon(Icons.replay),
                label: const Text('重新模拟'),
                onPressed: runSimulation,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
