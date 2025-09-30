import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class RSIAnalysisController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // RSI相关状态
  final RxList<Map<String, dynamic>> rsiData = <Map<String, dynamic>>[].obs;
  final RxMap<String, dynamic>? rsiResult = RxMap<String, dynamic>();
  final RxBool isLoadingRsi = false.obs;
  final TextEditingController customPriceController = TextEditingController();
  final RxBool useCustomPrice = false.obs;

  // 币种选择
  final RxString selectedCoin = 'BTCUSDT'.obs;
  final List<Map<String, dynamic>> coinList = [
    {'symbol': 'BTCUSDT', 'name': '比特币 (BTC)', 'color': Colors.orange},
    {'symbol': 'ETHUSDT', 'name': '以太坊 (ETH)', 'color': Colors.blue},
    {'symbol': 'ADAUSDT', 'name': '卡尔达诺 (ADA)', 'color': Colors.teal},
    {'symbol': 'SOLUSDT', 'name': '索拉纳 (SOL)', 'color': Colors.purple},
    {'symbol': 'DOGEUSDT', 'name': '狗狗币 (DOGE)', 'color': Colors.amber},
    {'symbol': 'TRXUSDT', 'name': '波场 (TRX)', 'color': Colors.red},
  ];

  @override
  void onClose() {
    customPriceController.dispose();
    super.onClose();
  }

  // 计算RSI 6日
  Future<void> calculateRSI() async {
    isLoadingRsi.value = true;
    errorMessage.value = '';

    try {
      double customPrice = 0;
      if (useCustomPrice.value && customPriceController.text.isNotEmpty) {
        customPrice = double.tryParse(customPriceController.text) ?? 0;
        if (customPrice <= 0) {
          _showMessage("请输入有效的价格");
          isLoadingRsi.value = false;
          return;
        }
      }

      // 获取价格数据 - 使用币安API
      final response = await http.get(
        Uri.parse('https://api.binance.com/api/v3/klines?symbol=${selectedCoin.value}&interval=1d&limit=100'),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Accept': 'application/json',
          'Accept-Language': 'en-US,en;q=0.9',
        },
      );

      debugPrint('请求URL: ${response.request?.url}');
      debugPrint('响应状态码: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final prices = <double>[];

        // 币安API返回格式: [[timestamp, open, high, low, close, volume, ...], ...]
        if (data is List) {
          final candles = data;
          debugPrint('币安蜡烛图数据数量: ${candles.length}');

          for (var item in candles) {
            if (item is List && item.length >= 6) {
              // 币安的收盘价是第5个元素（索引4）
              prices.add(double.parse(item[4].toString()));
            }
          }
        } else {
          throw Exception('币安API返回数据格式错误');
        }

        // 如果使用自定义价格，替换最后一个价格
        if (useCustomPrice.value && customPrice > 0) {
          prices[prices.length - 1] = customPrice;
        }

        // 计算RSI 6日
        final rsi = _calculateRSIValue(prices, 6);
        final currentPrice = useCustomPrice.value ? customPrice : prices.last;
        final rsiStatus = _getRSIStatus(rsi);

        rsiResult?.value = {
          'rsi': rsi,
          'currentPrice': currentPrice,
          'status': rsiStatus,
          'timestamp': DateTime.now(),
          'isCustomPrice': useCustomPrice.value
        };
      } else {
        _showMessage("获取数据失败");
      }
    } catch (e) {
      _showMessage("计算RSI失败: $e");
    } finally {
      isLoadingRsi.value = false;
    }
  }

  // RSI计算逻辑
  double _calculateRSIValue(List<double> prices, int period) {
    if (prices.length < period + 1) return 50.0;

    final gains = <double>[];
    final losses = <double>[];

    // 计算价格变化
    for (int i = 1; i < prices.length; i++) {
      final change = prices[i] - prices[i - 1];
      gains.add(change > 0 ? change : 0);
      losses.add(change < 0 ? -change : 0);
    }

    // 计算平均收益和损失
    double avgGain = gains.take(period).reduce((a, b) => a + b) / period;
    double avgLoss = losses.take(period).reduce((a, b) => a + b) / period;

    // 计算RSI
    for (int i = period; i < gains.length; i++) {
      avgGain = (avgGain * (period - 1) + gains[i]) / period;
      avgLoss = (avgLoss * (period - 1) + losses[i]) / period;
    }

    if (avgLoss == 0) return 100.0;
    final rs = avgGain / avgLoss;
    return 100.0 - (100.0 / (1 + rs));
  }

  // 获取RSI状态
  String _getRSIStatus(double rsi) {
    if (rsi >= 70) return "超买";
    if (rsi <= 30) return "超卖";
    if (rsi >= 50) return "强势";
    return "弱势";
  }

  // 获取币种名称
  String getCoinName(String symbol) {
    final coin = coinList.firstWhere((coin) => coin['symbol'] == symbol);
    return coin['name'].split(' ')[0]; // 返回中文名称
  }

  // 显示消息 - 兼容macOS
  void _showMessage(String message) {
    if (Platform.isMacOS) {
      Get.snackbar('提示', message);
    } else {
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
      );
    }
  }

  // 切换币种
  void selectCoin(String symbol) {
    selectedCoin.value = symbol;
    rsiResult?.clear(); // 清空之前的结果
  }

  // 切换自定义价格
  void toggleCustomPrice(bool value) {
    useCustomPrice.value = value;
    if (!value) {
      customPriceController.clear();
    }
  }

  void refreshData() {
    calculateRSI();
  }
}
