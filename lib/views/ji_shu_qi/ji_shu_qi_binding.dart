import 'package:get/get.dart';

import 'ji_shu_qi_controller.dart';

class JiShuQiBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => JiShuQiController());
  }
}
