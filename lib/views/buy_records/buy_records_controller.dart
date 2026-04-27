import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:ycd/utils/network/api.dart';

import 'buy_records_state.dart';

/// 买入记录页面控制器
class BuyRecordsController extends GetxController {
  static const int _emaPeriod = 21;
  static const int _emaKlineLimit = 250;

  /// 状态管理
  final BuyRecordsState state = BuyRecordsState();

  Map<String, String> get _marketHeaders => const {
    'User-Agent':
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    'Accept': 'application/json',
    'Accept-Language': 'en-US,en;q=0.9',
  };

  String get _currentSymbol => switch (state.currentCurrency) {
        'btc' => 'BTCUSDT',
        'eth' => 'ETHUSDT',
        'ada' => 'ADAUSDT',
        'trx' => 'TRXUSDT',
        _ => 'BTCUSDT',
      };

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
      state.ema21w = null;
      final symbol = _currentSymbol;
      final responses = await Future.wait([
        http
            .get(
              Uri.parse('https://api.binance.com/api/v3/ticker/price?symbol=$symbol'),
              headers: _marketHeaders,
            )
            .timeout(const Duration(seconds: 30)),
        http
            .get(
              Uri.parse(
                'https://api.binance.com/api/v3/klines?symbol=$symbol&interval=1w&limit=$_emaKlineLimit',
              ),
              headers: _marketHeaders,
            )
            .timeout(const Duration(seconds: 30)),
      ]);

      final priceResponse = responses[0];
      if (priceResponse.statusCode == 200) {
        final data = json.decode(priceResponse.body);
        if (data is Map && data['price'] != null) {
          state.currentPrice = double.parse(data['price'].toString());
          debugPrint('当前${state.currentCurrency.toUpperCase()}价格: ${state.currentPrice}');
        } else {
          debugPrint('价格数据格式错误');
        }
      } else {
        debugPrint('获取价格失败，状态码: ${priceResponse.statusCode}');
      }

      final klineResponse = responses[1];
      if (klineResponse.statusCode == 200) {
        final data = json.decode(klineResponse.body);
        if (data is List && data.length >= _emaPeriod) {
          final closes = _extractClosedWeeklyCloses(data);

          if (closes.length >= _emaPeriod) {
            state.ema21w = _calculateEma(closes, _emaPeriod);
            debugPrint('当前${state.currentCurrency.toUpperCase()} 21W EMA: ${state.ema21w}');
          } else {
            debugPrint('已收盘周K数量不足，无法计算 ${_emaPeriod}W EMA');
          }
        }
      } else {
        debugPrint('获取K线失败，状态码: ${klineResponse.statusCode}');
      }
    } catch (e) {
      debugPrint('获取当前价格失败: $e');
      // 价格获取失败不影响主要功能，只是无法显示收益统计
    }
  }

  double _calculateEma(List<double> values, int period) {
    assert(values.length >= period);
    final multiplier = 2 / (period + 1);
    double ema = values.take(period).reduce((a, b) => a + b) / period;
    for (int i = period; i < values.length; i++) {
      ema = ((values[i] - ema) * multiplier) + ema;
    }
    return ema;
  }

  List<double> _extractClosedWeeklyCloses(List<dynamic> candles) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final closes = <double>[];

    for (final item in candles) {
      if (item is! List || item.length <= 6) continue;

      final closeTime = int.tryParse(item[6].toString());
      final closePrice = double.tryParse(item[4].toString());
      if (closeTime == null || closePrice == null) continue;

      // 排除尚未收盘的周线，尽量与常见图表默认展示的周线指标口径一致。
      if (closeTime > nowMs) continue;

      closes.add(closePrice);
    }

    return closes;
  }

  double? get ema21wDeviationPercent {
    final current = state.currentPrice;
    final ema = state.ema21w;
    if (current == null || ema == null || ema == 0) return null;
    return ((current - ema) / ema) * 100;
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

        if (data is Map && data['code'] == 0) {
          if (data['data'] != null) {
            // 接口 created_at 升序 [最旧…最新]，倒置后 state 为 [最新…最旧]，列表从上到下即最新在上。
            state.buyRecords = List<Map<String, dynamic>>.from(
              (data['data'] as List).reversed,
            );
          } else {
            // data为null时，显示暂无购买
            state.buyRecords = [];
          }
        } else if (data is List) {
          state.buyRecords =
              List<Map<String, dynamic>>.from(data.reversed);
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

  /// 格式化 21W EMA（TRX 保留四位小数，其他两位）
  String formatEmaPrice(dynamic price) {
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

  /// 累计统计：列表为 [最新…最旧]，[reversedIndex] 对应该行；
  /// 按时间从最早到该行（含）累计（即下标 reversedIndex…length-1）。
  Map<String, dynamic> calculateCumulativeStatsForRow(int reversedIndex) {
    if (state.buyRecords.isEmpty ||
        reversedIndex < 0 ||
        reversedIndex >= state.buyRecords.length) {
      return {};
    }

    double totalCost = 0;
    double totalQuantity = 0;

    for (int j = reversedIndex; j < state.buyRecords.length; j++) {
      final record = state.buyRecords[j];
      final price = record['buy_price'] as num?;
      final amount = record['buy_amount'] as num?;

      if (price != null && amount != null) {
        totalCost += amount;
        totalQuantity += amount / price;
      }
    }

    if (totalQuantity == 0) return {};

    final averagePrice = totalCost / totalQuantity;
    final n = state.buyRecords.length - reversedIndex;
    debugPrint('累计统计调试 (时间最早起共$n笔到当前行):');
    debugPrint('总成本: $totalCost USDT');
    debugPrint('总数量: $totalQuantity BTC');
    debugPrint('均价: $averagePrice USDT/BTC');

    return {'totalCost': totalCost, 'totalQuantity': totalQuantity, 'averagePrice': averagePrice};
  }

  /// 累计收益：时间顺序同上，从最早买入累加到当前行（含）。
  Map<String, dynamic> calculateCurrentProfitStatsForRow(int reversedIndex) {
    if (state.buyRecords.isEmpty ||
        state.currentPrice == null ||
        reversedIndex < 0 ||
        reversedIndex >= state.buyRecords.length) {
      return {};
    }

    double totalBuyAmount = 0;
    double totalBtcQuantity = 0;

    for (int j = reversedIndex; j < state.buyRecords.length; j++) {
      final record = state.buyRecords[j];
      final buyPrice = record['buy_price'] as num?;
      final buyAmount = record['buy_amount'] as num?;

      if (buyPrice != null && buyAmount != null) {
        totalBuyAmount += buyAmount;
        totalBtcQuantity += buyAmount / buyPrice;
      }
    }

    if (totalBtcQuantity == 0) return {};

    final currentValue = totalBtcQuantity * state.currentPrice!;
    final profit = currentValue - totalBuyAmount;
    final profitPercentage = (profit / totalBuyAmount) * 100;
    final n = state.buyRecords.length - reversedIndex;

    debugPrint('累计收益调试 (时间最早起共$n笔到当前行):');
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

  /// 与 [calculateCumulativeStatsForRow] 相同（参数为「最新在前」时的行下标），兼容旧视图方法名。
  Map<String, dynamic> calculateCumulativeStats(int reversedIndex) =>
      calculateCumulativeStatsForRow(reversedIndex);

  /// 与 [calculateCurrentProfitStatsForRow] 相同，兼容旧视图方法名。
  Map<String, dynamic> calculateCurrentProfitStats(int reversedIndex) =>
      calculateCurrentProfitStatsForRow(reversedIndex);

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
