import 'package:get/get.dart';

import 'investment_calculator_controller.dart';

class InvestmentCalculatorBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<InvestmentCalculatorController>(
      () => InvestmentCalculatorController(),
    );
  }
}
