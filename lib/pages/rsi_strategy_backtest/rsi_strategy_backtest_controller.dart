import 'package:get/get.dart';

class RSIStrategyBacktestController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // 回测相关状态
  final RxList<Map<String, dynamic>> backtestResults =
      <Map<String, dynamic>>[].obs;

  void runBacktest() {
    // 运行回测
  }
}
