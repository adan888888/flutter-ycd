import 'package:get/get.dart';
import 'package:ycd/utils/bx_loading.dart';

import 'login_controller.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    BXLoading.reset();
    Get.lazyPut(() => LoginController());
  }
}
