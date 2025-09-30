import 'package:get/get.dart';

import 'rsi_strategy_backtest_controller.dart';

class RSIStrategyBacktestBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RSIStrategyBacktestController>(
        () => RSIStrategyBacktestController());
  }
}
