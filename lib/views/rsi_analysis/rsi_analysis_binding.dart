import 'package:get/get.dart';

import 'rsi_analysis_controller.dart';

class RSIAnalysisBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RSIAnalysisController>(() => RSIAnalysisController());
  }
}
