import 'package:get/get.dart';

import 'baccarat_simulation_controller.dart';

class BaccaratSimulationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BaccaratSimulationController>(
      () => BaccaratSimulationController(),
    );
  }
}
