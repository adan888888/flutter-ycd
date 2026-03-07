import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:ycd/utils/network/api.dart';

import 'buy_records_state.dart';

/// 买入记录页面控制器
class BuyRecordsController extends GetxController {
  /// 状态管理
  final BuyRecordsState state = BuyRecordsState();

  @override
  void onInit() {
    super.onInit();
    _initializeData();
  }

  /// 初始化数据，确保两个接口都完成后再进行计算
  Future<void> _initializeData() async {
    try {
      // 同时执行两个异步操作
      await Future.wait([
        _fetchBuyRecords(),
        _fetchCurrentPrice(),
      ]);
    } catch (e) {
      debugPrint('初始化数据失败: $e');
      // 即使有错误，也要更新UI显示错误状态
    } finally {
      // 无论成功还是失败，都要触发UI更新
      update();
    }
  }

  /// 获取当前价格
  Future<void> _fetchCurrentPrice() async {
    try {
      final symbol = switch (state.currentCurrency) {
        'btc' => 'BTCUSDT',
        'eth' => 'ETHUSDT',
        'ada' => 'ADAUSDT',
        'trx' => 'TRXUSDT',
        _ => 'BTCUSDT',
      };
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
          state.currentPrice = double.parse(data['price'].toString());
          debugPrint('当前${state.currentCurrency.toUpperCase()}价格: ${state.currentPrice}');
        } else {
          debugPrint('价格数据格式错误');
        }
      } else {
        debugPrint('获取价格失败，状态码: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('获取当前价格失败: $e');
      // 价格获取失败不影响主要功能，只是无法显示收益统计
    }
  }

  /// 获取买入记录数据
  Future<void> _fetchBuyRecords() async {
    state.isLoading = true;
    state.errorMessage = null;

    try {
      final response = await http.get(
        Uri.parse('${Api.baseUrl}${Api.buyRecords}?currency=${state.currentCurrency}'),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Accept': 'application/json',
          'Accept-Language': 'en-US,en;q=0.9',
        },
      ).timeout(const Duration(seconds: 30));

      debugPrint('请求URL: ${response.request?.url}');
      debugPrint('响应状态码: ${response.statusCode}');
      debugPrint('响应头: ${response.headers}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('买入记录API返回数据: $data');

        if (data is Map && data['code'] == 1) {
          if (data['data'] != null) {
            final dataList = data['data'] as List;
            state.buyRecords = List<Map<String, dynamic>>.from(dataList);
          } else {
            // data为null时，显示暂无购买
            state.buyRecords = [];
          }
        } else if (data is List) {
          state.buyRecords = List<Map<String, dynamic>>.from(data);
        } else {
          state.errorMessage = '数据格式错误: ${data['msg'] ?? '未知错误'}';
        }
      } else {
        state.errorMessage = '获取数据失败: ${response.statusCode}';
      }
    } catch (e) {
      state.errorMessage = '请求失败: $e';
      debugPrint('获取买入记录失败: $e');
    } finally {
      state.isLoading = false;
    }
  }

  /// 格式化成本价（TRX 保留五位小数，其他三位）
  String formatCostPrice(dynamic price) {
    try {
      if (price is num) {
        final decimals = state.currentCurrency == 'trx' ? 5 : 3;
        return '\$${price.toStringAsFixed(decimals)}';
      }
      return price.toString();
    } catch (e) {
      return price.toString();
    }
  }

  /// 格式化当前价格（TRX 保留四位小数，其他两位）
  String formatCurrentPrice(dynamic price) {
    try {
      if (price is num) {
        final decimals = state.currentCurrency == 'trx' ? 4 : 2;
        return '\$${price.toStringAsFixed(decimals)}';
      }
      return price.toString();
    } catch (e) {
      return price.toString();
    }
  }

  /// 格式化价格
  String formatPrice(dynamic price) {
    try {
      if (price is num) {
        return '\$${price.toStringAsFixed(2)}';
      }
      return price.toString();
    } catch (e) {
      return price.toString();
    }
  }

  /// 格式化成交价格（TRX 保留五位小数，其他三位）
  String formatTransactionPrice(dynamic price) {
    try {
      if (price is num) {
        final decimals = state.currentCurrency == 'trx' ? 5 : 3;
        return '\$${price.toStringAsFixed(decimals)}';
      }
      return price.toString();
    } catch (e) {
      return price.toString();
    }
  }

  /// 格式化价格 (保留四位小数)
  String formatPriceWithDecimals(dynamic price) {
    try {
      if (price is num) {
        return '\$${price.toStringAsFixed(3)}';
      }
      return price.toString();
    } catch (e) {
      return price.toString();
    }
  }

  /// 格式化价格 (整数，无小数)
  String formatPriceInteger(dynamic price) {
    try {
      if (price is num) {
        return '\$${price.toInt()}';
      }
      return price.toString();
    } catch (e) {
      return price.toString();
    }
  }

  /// 格式化价格 (保留两位小数)
  String formatPriceTwoDecimals(dynamic price) {
    try {
      if (price is num) {
        return '\$${price.toStringAsFixed(3)}';
      }
      return price.toString();
    } catch (e) {
      return price.toString();
    }
  }

  /// 格式化价格 (保留四位小数)
  String formatPriceFourDecimals(dynamic price) {
    try {
      if (price is num) {
        return '\$${price.toStringAsFixed(4)}';
      }
      return price.toString();
    } catch (e) {
      return price.toString();
    }
  }

  /// 计算累计统计信息 (到第n笔记录为止)
  Map<String, dynamic> calculateCumulativeStats(int recordCount) {
    if (state.buyRecords.isEmpty || recordCount <= 0) {
      return {};
    }

    double totalCost = 0;
    double totalQuantity = 0;

    // 只计算前n笔记录
    for (int i = 0; i < recordCount && i < state.buyRecords.length; i++) {
      final record = state.buyRecords[i];
      final price = record['buy_price'] as num?;
      final amount = record['buy_amount'] as num?;

      if (price != null && amount != null) {
        totalCost += amount; // 累计投入美元金额
        totalQuantity += amount / price; // 累计BTC数量 = 美元金额 ÷ BTC价格
      }
    }

    if (totalQuantity == 0) return {};

    // 均价 = 总成本 ÷ 总数量
    final averagePrice = totalCost / totalQuantity;

    debugPrint('累计统计调试 (前$recordCount笔):');
    debugPrint('总成本: $totalCost USDT');
    debugPrint('总数量: $totalQuantity BTC');
    debugPrint('均价: $averagePrice USDT/BTC');

    return {'totalCost': totalCost, 'totalQuantity': totalQuantity, 'averagePrice': averagePrice};
  }

  /// 计算累计收益统计 (基于当前实时价格)
  Map<String, dynamic> calculateCurrentProfitStats(int recordIndex) {
    if (state.buyRecords.isEmpty ||
        state.currentPrice == null ||
        recordIndex < 0 ||
        recordIndex >= state.buyRecords.length) {
      return {};
    }

    // 计算累计的买入金额和BTC数量
    double totalBuyAmount = 0;
    double totalBtcQuantity = 0;

    for (int i = 0; i <= recordIndex; i++) {
      final record = state.buyRecords[i];
      final buyPrice = record['buy_price'] as num?;
      final buyAmount = record['buy_amount'] as num?;

      if (buyPrice != null && buyAmount != null) {
        totalBuyAmount += buyAmount;
        totalBtcQuantity += buyAmount / buyPrice;
      }
    }

    if (totalBtcQuantity == 0) return {};

    // 累计当前价值
    final currentValue = totalBtcQuantity * state.currentPrice!;

    // 累计收益
    final profit = currentValue - totalBuyAmount;

    // 累计收益率
    final profitPercentage = (profit / totalBuyAmount) * 100;

    debugPrint('累计收益调试 (前${recordIndex + 1}笔):');
    debugPrint('累计买入金额: $totalBuyAmount');
    debugPrint('累计BTC数量: $totalBtcQuantity');
    debugPrint('当前价格: ${state.currentPrice}');
    debugPrint('累计当前价值: $currentValue');
    debugPrint('累计收益: $profit');
    debugPrint('累计收益率: ${profitPercentage.toStringAsFixed(2)}%');

    return {
      'totalBuyAmount': totalBuyAmount,
      'totalBtcQuantity': totalBtcQuantity,
      'currentValue': currentValue,
      'profit': profit,
      'profitPercentage': profitPercentage
    };
  }

  /// 切换币种
  void switchCurrency(String currency) {
    if (state.currentCurrency != currency) {
      state.currentCurrency = currency;
      // 切换币种后重新获取数据，确保两个接口都完成后再更新UI
      _initializeData();
    }
  }

  /// 刷新所有数据
  Future<void> refreshAllData() async {
    // 使用统一的初始化方法，确保两个接口都完成后再更新UI
    await _initializeData();
  }
}
