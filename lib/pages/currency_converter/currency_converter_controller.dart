import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class CurrencyConverterController extends GetxController {
  // 表单控制器
  final TextEditingController amountController = TextEditingController();

  // 状态变量
  final RxString fromCurrency = 'USD'.obs;
  final RxString toCurrency = 'CNY'.obs;
  final RxDouble convertedAmount = 0.0.obs;
  final RxDouble exchangeRate = 0.0.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // 支持的货币列表
  final List<Map<String, dynamic>> currencies = [
    {'code': 'USD', 'name': '美元', 'symbol': '\$', 'flag': '🇺🇸'},
    {'code': 'CNY', 'name': '人民币', 'symbol': '¥', 'flag': '🇨🇳'},
    {'code': 'JPY', 'name': '日元', 'symbol': '¥', 'flag': '🇯🇵'},
    {'code': 'VND', 'name': '越南盾', 'symbol': '₫', 'flag': '🇻🇳'},
    {'code': 'EUR', 'name': '欧元', 'symbol': '€', 'flag': '🇪🇺'},
    {'code': 'GBP', 'name': '英镑', 'symbol': '£', 'flag': '🇬🇧'},
    {'code': 'KRW', 'name': '韩元', 'symbol': '₩', 'flag': '🇰🇷'},
    {'code': 'HKD', 'name': '港币', 'symbol': 'HK\$', 'flag': '🇭🇰'},
    {'code': 'SGD', 'name': '新加坡元', 'symbol': 'S\$', 'flag': '🇸🇬'},
    {'code': 'AUD', 'name': '澳元', 'symbol': 'A\$', 'flag': '🇦🇺'},
    {'code': 'CAD', 'name': '加元', 'symbol': 'C\$', 'flag': '🇨🇦'},
    {'code': 'CHF', 'name': '瑞士法郎', 'symbol': 'CHF', 'flag': '🇨🇭'},
    {'code': 'NZD', 'name': '新西兰元', 'symbol': 'NZ\$', 'flag': '🇳🇿'},
  ];

  @override
  void onClose() {
    amountController.dispose();
    super.onClose();
  }

  // 获取汇率
  Future<void> fetchExchangeRate() async {
    if (amountController.text.isEmpty) {
      errorMessage.value = '请输入金额';
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final amount = double.parse(amountController.text);
      if (amount <= 0) {
        errorMessage.value = '金额必须大于0';
        return;
      }

      // 使用免费的汇率API
      final response = await http.get(
        Uri.parse('https://api.exchangerate-api.com/v4/latest/${fromCurrency.value}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'];

        if (rates.containsKey(toCurrency.value)) {
          exchangeRate.value = rates[toCurrency.value].toDouble();
          convertedAmount.value = amount * exchangeRate.value;
          errorMessage.value = '';
        } else {
          errorMessage.value = '不支持的货币对';
        }
      } else {
        errorMessage.value = '获取汇率失败，请稍后重试';
      }
    } catch (e) {
      errorMessage.value = '请输入有效的数字';
    } finally {
      isLoading.value = false;
    }
  }

  // 交换货币
  void swapCurrencies() {
    final temp = fromCurrency.value;
    fromCurrency.value = toCurrency.value;
    toCurrency.value = temp;

    // 如果有转换结果，重新计算
    if (amountController.text.isNotEmpty) {
      fetchExchangeRate();
    }
  }

  // 清空输入
  void clearInput() {
    amountController.clear();
    convertedAmount.value = 0.0;
    exchangeRate.value = 0.0;
    errorMessage.value = '';
  }

  // 获取货币信息
  Map<String, dynamic>? getCurrencyInfo(String code) {
    try {
      return currencies.firstWhere((currency) => currency['code'] == code);
    } catch (e) {
      return null;
    }
  }

  // 格式化金额显示
  String formatAmount(double amount) {
    if (amount == 0) return '0.00';
    return amount.toStringAsFixed(2);
  }
}
