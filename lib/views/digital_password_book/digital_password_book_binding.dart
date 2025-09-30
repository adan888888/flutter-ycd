import 'package:get/get.dart';

import 'digital_password_book_controller.dart';

class DigitalPasswordBookBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut<DigitalPasswordBookController>(() => DigitalPasswordBookController());
}
