import 'package:get/get.dart';

import 'buy_records_controller.dart';

/// 买入记录页面依赖注入
class BuyRecordsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BuyRecordsController>(() => BuyRecordsController());
  }
}
