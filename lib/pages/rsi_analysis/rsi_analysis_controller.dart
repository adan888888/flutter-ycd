import 'package:get/get.dart';

class RSIAnalysisController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // RSI相关状态
  final RxList<Map<String, dynamic>> rsiData = <Map<String, dynamic>>[].obs;

  void refreshData() {
    // 刷新RSI数据
  }
}
