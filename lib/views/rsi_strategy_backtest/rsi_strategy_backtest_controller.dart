import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class RSIStrategyBacktestController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // 回测相关状态
  final RxList<Map<String, dynamic>> backtestResults = <Map<String, dynamic>>[].obs;
  final RxMap<String, dynamic>? backtestResult = RxMap<String, dynamic>();
  final RxBool isLoadingBacktest = false.obs;

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

  // 执行回测
  Future<void> runBacktest() async {
    isLoadingBacktest.value = true;
    errorMessage.value = '';

    try {
      // 获取最近1年的价格数据 - 使用币安API
      // 1年 = 365天，加上一些缓冲，请求400天数据
      final response = await http.get(
        Uri.parse('https://api.binance.com/api/v3/klines?symbol=${selectedCoin.value}&interval=1d&limit=400'),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Accept': 'application/json',
          'Accept-Language': 'en-US,en;q=0.9',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final prices = <double>[];
        final dates = <DateTime>[];

        // 币安API返回格式: [[timestamp, open, high, low, close, volume, ...], ...]
        if (data is List) {
          final candles = data;
          debugPrint('币安蜡烛图数据数量: ${candles.length}');

          for (var item in candles) {
            if (item is List && item.length >= 6) {
              // 币安的收盘价是第5个元素（索引4），时间戳是第0个元素
              prices.add(double.parse(item[4].toString())); // 收盘价
              dates.add(DateTime.fromMillisecondsSinceEpoch(int.parse(item[0].toString()))); // 时间戳
            }
          }
        } else {
          throw Exception('币安API返回数据格式错误');
        }

        // 计算每日RSI
        final rsiValues = <double>[];
        for (int i = 6; i < prices.length; i++) {
          final periodPrices = prices.sublist(i - 6, i + 1);
          final rsi = _calculateRSIValue(periodPrices, 6);
          rsiValues.add(rsi);
        }

        // 执行策略回测
        final result = _executeStrategy(
          prices.sublist(6), // 从第7天开始（有RSI值）
          dates.sublist(6),
          rsiValues,
        );

        backtestResult?.value = result;
      } else {
        _showMessage("获取数据失败");
      }
    } catch (e) {
      String errorMessage = "回测失败: ";

      if (e.toString().contains('SocketException')) {
        if (e.toString().contains('Operation not permitted')) {
          errorMessage += "网络权限被拒绝，请检查macOS网络设置";
        } else if (e.toString().contains('Connection failed')) {
          errorMessage += "网络连接失败，请检查网络连接";
        } else {
          errorMessage += "网络连接问题: ${e.toString()}";
        }
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage += "请求超时，请稍后重试";
      } else {
        errorMessage += e.toString();
      }

      _showMessage(errorMessage);
      debugPrint("详细错误信息: $e");
    } finally {
      isLoadingBacktest.value = false;
    }
  }

  // 执行策略逻辑 - 两周定投2000元
  Map<String, dynamic> _executeStrategy(List<double> prices, List<DateTime> dates, List<double> rsiValues) {
    double totalInvested = 0;
    double totalCoins = 0;
    final trades = <Map<String, dynamic>>[];

    // 两周定投2000元
    const biweeklyAmount = 2000.0;

    // 计算有多少个两周周期（最近1年约26个两周周期）
    final totalWeeks = (dates.length / 7).floor();
    final biweeklyPeriods = (totalWeeks / 2).floor(); // 两周为一个周期
    final actualPeriods = biweeklyPeriods > 26 ? 26 : biweeklyPeriods; // 限制为26个周期

    // 获取真正的当前价格（使用最后一个价格作为参考）
    final lastPrice = prices.last;
    debugPrint('数据中最后价格: $lastPrice');
    debugPrint('数据中最后日期: ${dates.last}');
    debugPrint('实际回测两周周期数: $actualPeriods');

    for (int period = 0; period < actualPeriods; period++) {
      // 每两周选择一天进行投资（这里选择每个周期的第一天）
      final dayIndex = period * 14; // 两周 = 14天
      if (dayIndex < prices.length) {
        final price = prices[dayIndex];
        final date = dates[dayIndex];
        final rsi = rsiValues[dayIndex];

        // 买入
        final coinsBought = biweeklyAmount / price;
        totalInvested += biweeklyAmount;
        totalCoins += coinsBought;

        trades.add({
          'date': date.toString().substring(0, 10),
          'price': price,
          'rsi': rsi,
          'amount': biweeklyAmount,
          'coins': coinsBought,
          'period': period + 1,
          'type': '定投'
        });
      }
    }

    // 计算最终收益 - 使用实时价格
    final currentPrice = prices.last; // 暂时使用最后价格，后续需要获取实时价格
    final currentValue = totalCoins * currentPrice;
    final totalProfit = currentValue - totalInvested;
    final profitPercentage = totalInvested > 0 ? (totalProfit / totalInvested) * 100 : 0;

    // 调试信息
    debugPrint('最后价格: $currentPrice');
    debugPrint('累计买入数量: $totalCoins');
    debugPrint('计算市值: $currentValue');

    return {
      'totalInvested': totalInvested,
      'totalCoins': totalCoins,
      'currentValue': currentValue,
      'totalProfit': totalProfit,
      'profitPercentage': profitPercentage,
      'trades': trades,
      'tradeCount': trades.length,
      'currentPrice': currentPrice,
      'coinName': getCoinName(selectedCoin.value),
      'period': '最近1年',
      'periods': actualPeriods,
    };
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

    // 计算初始平均收益和损失
    double avgGain = gains.take(period).reduce((a, b) => a + b) / period;
    double avgLoss = losses.take(period).reduce((a, b) => a + b) / period;

    // 使用Wilder's Smoothing计算RSI
    for (int i = period; i < gains.length; i++) {
      avgGain = (avgGain * (period - 1) + gains[i]) / period;
      avgLoss = (avgLoss * (period - 1) + losses[i]) / period;
    }

    // 防止除零错误和异常值
    if (avgLoss == 0) {
      if (avgGain == 0) return 50.0; // 没有变化，RSI = 50
      return 100.0; // 只有收益，RSI = 100
    }

    if (avgGain == 0) return 0.0; // 只有损失，RSI = 0

    final rs = avgGain / avgLoss;
    final rsi = 100.0 - (100.0 / (1 + rs));

    // 确保RSI在有效范围内
    if (rsi.isNaN || rsi.isInfinite) return 50.0;
    if (rsi < 0) return 0.0;
    if (rsi > 100) return 100.0;

    return rsi;
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
    backtestResult?.clear(); // 清空之前的结果
  }
}
