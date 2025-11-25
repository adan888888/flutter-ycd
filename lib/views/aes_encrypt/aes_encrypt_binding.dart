import 'package:get/get.dart';
import 'aes_encrypt_controller.dart';

class AesEncryptBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AesEncryptController>(
      () => AesEncryptController(),
    );
  }
}

