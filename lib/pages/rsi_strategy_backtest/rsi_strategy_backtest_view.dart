import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'rsi_strategy_backtest_controller.dart';

class RSIStrategyBacktestView extends GetView<RSIStrategyBacktestController> {
  const RSIStrategyBacktestView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RSI策略回测'),
        backgroundColor: Colors.purple.shade600,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: const Center(
        child: Text('RSI策略回测页面'),
      ),
    );
  }
}
