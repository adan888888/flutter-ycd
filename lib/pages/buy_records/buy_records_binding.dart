import 'package:get/get.dart';

import 'buy_records_controller.dart';

class BuyRecordsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BuyRecordsController>(
      () => BuyRecordsController(),
    );
  }
}
