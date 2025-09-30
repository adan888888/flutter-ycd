import 'package:get/get.dart';

/// 汇率换算状态管理
class CurrencyConverterState {
  // 表单状态
  final RxString fromCurrency = 'USD'.obs;
  final RxString toCurrency = 'CNY'.obs;
  final RxDouble convertedAmount = 0.0.obs;
  final RxDouble exchangeRate = 0.0.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // 重置状态
  void reset() {
    convertedAmount.value = 0.0;
    exchangeRate.value = 0.0;
    isLoading.value = false;
    errorMessage.value = '';
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

  // 更新转换结果
  void updateConversionResult(double rate, double amount) {
    exchangeRate.value = rate;
    convertedAmount.value = amount;
    errorMessage.value = '';
    isLoading.value = false;
  }

  // 交换货币
  void swapCurrencies() {
    final temp = fromCurrency.value;
    fromCurrency.value = toCurrency.value;
    toCurrency.value = temp;
  }
}
