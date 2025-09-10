import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'rsi_analysis_controller.dart';

class RSIAnalysisView extends GetView<RSIAnalysisController> {
  const RSIAnalysisView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RSI分析'),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: const Center(
        child: Text('RSI分析页面'),
      ),
    );
  }
}
