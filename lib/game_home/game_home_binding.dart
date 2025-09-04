import 'package:get/get.dart';
import 'game_home_logic.dart';

class GameHomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => GameHomeLogic());
  }
}
