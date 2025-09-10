import 'package:get/get.dart';

/// 买入记录状态管理
class BuyRecordsState {
  // 数据状态
  final RxList<Map<String, dynamic>> buyRecords = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxDouble currentPrice = 0.0.obs;
  final RxString currentCurrency = 'btc'.obs;

  // 重置状态
  void reset() {
    buyRecords.clear();
    isLoading.value = false;
    errorMessage.value = '';
    currentPrice.value = 0.0;
  }

  // 开始加载
  void startLoading() {
    isLoading.value = true;
    errorMessage.value = '';
  }

  // 结束加载
  void endLoading() {
    isLoading.value = false;
  }

  // 设置错误
  void setError(String error) {
    errorMessage.value = error;
    isLoading.value = false;
  }

  // 更新买入记录
  void updateBuyRecords(List<Map<String, dynamic>> records) {
    buyRecords.value = records;
    errorMessage.value = '';
    isLoading.value = false;
  }

  // 更新当前价格
  void updateCurrentPrice(double price) {
    currentPrice.value = price;
  }

  // 切换币种
  void changeCurrency(String currency) {
    currentCurrency.value = currency;
  }
}
