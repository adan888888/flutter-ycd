import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class BuyRecordsController extends GetxController {
  // 状态变量
  final RxList<Map<String, dynamic>> buyRecords = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxDouble currentPrice = 0.0.obs;
  final RxString currentCurrency = 'btc'.obs; // 当前选择的币种

  @override
  void onInit() {
    super.onInit();
    fetchBuyRecords();
    fetchCurrentPrice();
  }

  // 获取当前价格
  Future<void> fetchCurrentPrice() async {
    try {
      final symbol = currentCurrency.value == 'btc' ? 'BTCUSDT' : 'ETHUSDT';
      final response = await http.get(
        Uri.parse('https://api.binance.com/api/v3/ticker/price?symbol=$symbol'),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Accept': 'application/json',
          'Accept-Language': 'en-US,en;q=0.9',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map && data['price'] != null) {
          currentPrice.value = double.parse(data['price'].toString());
          print(
              '当前${currentCurrency.value.toUpperCase()}价格: ${currentPrice.value}');
        }
      }
    } catch (e) {
      print('获取当前价格失败: $e');
    }
  }

  // 获取买入记录
  Future<void> fetchBuyRecords() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final response = await http.get(
        Uri.parse('http://localhost:8080/api/buy-records'),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent':
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map && data['data'] is List) {
          final List<dynamic> records = data['data'];
          buyRecords.value = records.cast<Map<String, dynamic>>();
          print('成功获取 ${buyRecords.length} 条买入记录');
        } else {
          errorMessage.value = '数据格式错误';
        }
      } else {
        errorMessage.value = '获取数据失败: HTTP ${response.statusCode}';
      }
    } catch (e) {
      print('获取买入记录失败: $e');
      errorMessage.value = '网络错误，请检查网络连接';
    } finally {
      isLoading.value = false;
    }
  }

  // 刷新数据
  Future<void> refreshData() async {
    await Future.wait([
      fetchBuyRecords(),
      fetchCurrentPrice(),
    ]);
  }

  // 切换币种
  void changeCurrency(String currency) {
    currentCurrency.value = currency;
    fetchCurrentPrice();
  }

  // 计算盈亏
  double calculateProfitLoss(Map<String, dynamic> record) {
    if (currentPrice.value == 0) return 0.0;

    final buyPrice = record['buy_price']?.toDouble() ?? 0.0;
    final quantity = record['quantity']?.toDouble() ?? 0.0;

    if (buyPrice == 0 || quantity == 0) return 0.0;

    final currentValue = currentPrice.value * quantity;
    final buyValue = buyPrice * quantity;

    return currentValue - buyValue;
  }

  // 计算盈亏率
  double calculateProfitLossPercentage(Map<String, dynamic> record) {
    if (currentPrice.value == 0) return 0.0;

    final buyPrice = record['buy_price']?.toDouble() ?? 0.0;

    if (buyPrice == 0) return 0.0;

    return ((currentPrice.value - buyPrice) / buyPrice) * 100;
  }

  // 格式化货币显示
  String formatCurrency(double amount, {bool isPrice = false}) {
    if (isPrice) {
      return amount.toStringAsFixed(2);
    }
    return amount.toStringAsFixed(8);
  }

  // 格式化百分比
  String formatPercentage(double percentage) {
    final sign = percentage >= 0 ? '+' : '';
    return '$sign${percentage.toStringAsFixed(2)}%';
  }

  // 获取当前币种显示名称
  String get currentCurrencyDisplayName {
    return currentCurrency.value.toUpperCase();
  }

  // 计算总投资
  double get totalInvestment {
    return buyRecords.fold(0.0, (sum, record) {
      final buyPrice = record['buy_price']?.toDouble() ?? 0.0;
      final quantity = record['quantity']?.toDouble() ?? 0.0;
      return sum + (buyPrice * quantity);
    });
  }

  // 计算总当前价值
  double get totalCurrentValue {
    if (currentPrice.value == 0) return 0.0;

    return buyRecords.fold(0.0, (sum, record) {
      final quantity = record['quantity']?.toDouble() ?? 0.0;
      return sum + (currentPrice.value * quantity);
    });
  }

  // 计算总盈亏
  double get totalProfitLoss {
    return totalCurrentValue - totalInvestment;
  }

  // 计算总盈亏率
  double get totalProfitLossPercentage {
    if (totalInvestment == 0) return 0.0;
    return (totalProfitLoss / totalInvestment) * 100;
  }
}
