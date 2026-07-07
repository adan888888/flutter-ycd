import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ycd/utils/network/api.dart';
import 'package:ycd/utils/network/http_mgr.dart';
import 'package:ycd/utils/permission_util.dart';
import 'package:ycd/utils/storage_util.dart';

import 'buy_records_currency.dart';
import 'buy_records_market_service.dart';
import 'buy_records_state.dart';

/// 买入记录页面控制器
class BuyRecordsController extends GetxController {
  static const _baseAmountsStorageKey = 'buy_records_base_amounts';

  /// 状态管理
  final BuyRecordsState state = BuyRecordsState();

  BuyRecordsCurrency get currentCurrencyConfig =>
      findBuyRecordsCurrency(state.currentCurrency) ?? defaultBuyRecordsCurrency;

  double get effectiveBaseAmount => baseAmountFor(currentCurrencyConfig);

  double baseAmountFor(BuyRecordsCurrency currency) =>
      state.customBaseAmounts[currency.id] ?? currency.baseAmount;

  bool hasCustomBaseAmount(String currencyId) =>
      state.customBaseAmounts.containsKey(currencyId);

  Map<String, String> get _marketHeaders => const {
    'User-Agent':
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    'Accept': 'application/json',
    'Accept-Language': 'en-US,en;q=0.9',
  };

  @override
  void onInit() {
    super.onInit();
    if (!PermissionUtil.guardProFeature()) return;
    _loadCustomBaseAmounts();
    _initializeData();
  }

  void _loadCustomBaseAmounts() {
    final raw = StorageUtil.getString(_baseAmountsStorageKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      state.customBaseAmounts = map.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      );
    } catch (e) {
      debugPrint('加载基准买入配置失败: $e');
    }
  }

  Future<void> updateBaseAmount(String currencyId, double amount) async {
    if (amount <= 0) return;
    state.customBaseAmounts[currencyId] = amount;
    await StorageUtil.saveString(
      _baseAmountsStorageKey,
      jsonEncode(state.customBaseAmounts),
    );
    update();
  }

  Future<void> resetBaseAmount(String currencyId) async {
    state.customBaseAmounts.remove(currencyId);
    await StorageUtil.saveString(
      _baseAmountsStorageKey,
      jsonEncode(state.customBaseAmounts),
    );
    update();
  }

  Future<double?> fetchMaDeviationPercentFor(BuyRecordsCurrency config) async {
    try {
      final quote = await fetchMarketQuote(config, _marketHeaders);
      final price = quote.price;
      final ma = quote.ma200;
      if (price == null || ma == null || ma == 0) return null;
      return ((price - ma) / ma) * 100;
    } catch (e) {
      debugPrint('获取${config.label}偏离失败: $e');
      return null;
    }
  }

  String formatSuggestedBuyAmountFor(double baseAmount, {double? deviationPercent}) {
    final deviation = deviationPercent ?? ma200DailyDeviationPercent;
    final amount = suggestedBuyAmountUsdt(deviation, baseAmount);
    if (amount == null) return '—';
    if (amount == 0) return '停止买入';
    return formatBuyAmountUsdt(amount);
  }

  Color suggestedBuyAmountColorFor(double baseAmount, {double? deviationPercent}) {
    final deviation = deviationPercent ?? ma200DailyDeviationPercent;
    final amount = suggestedBuyAmountUsdt(deviation, baseAmount);
    if (amount == null) return Colors.grey;
    if (amount == 0) return Colors.orange;
    if (amount > baseAmount) return Colors.green;
    if (amount < baseAmount) return Colors.deepOrange;
    return Colors.black;
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

  /// 获取当前价格与 200 日均线
  Future<void> _fetchCurrentPrice() async {
    final currencyId = state.currentCurrency;
    final config = currentCurrencyConfig;

    try {
      state.currentPrice = null;
      state.ma200Daily = null;

      final quote = await fetchMarketQuote(config, _marketHeaders);
      if (state.currentCurrency != currencyId) return;

      state.currentPrice = quote.price;
      state.ma200Daily = quote.ma200;

      if (quote.price != null) {
        debugPrint('当前${config.label}价格(${config.exchangeName}): ${quote.price}');
      } else {
        debugPrint('获取${config.label}价格失败 (${config.exchangeName})');
      }

      if (quote.ma200 != null) {
        debugPrint('当前${config.label} SMA200(1d): ${quote.ma200}');
      } else if (quote.price != null) {
        debugPrint('${config.label} 已收盘日K数量不足，无法计算 SMA200');
      }
    } catch (e) {
      debugPrint('获取${config.label}行情失败: $e');
    }
  }

  double? get ma200DailyDeviationPercent {
    final current = state.currentPrice;
    final ma = state.ma200Daily;
    if (current == null || ma == null || ma == 0) return null;
    return ((current - ma) / ma) * 100;
  }

  /// 相对 200 日均线偏离档位给出的建议买入金额（USDT）
  double? get suggestedBuyAmount =>
      suggestedBuyAmountUsdt(ma200DailyDeviationPercent, effectiveBaseAmount);

  String formatSuggestedBuyAmount() =>
      formatSuggestedBuyAmountFor(effectiveBaseAmount);

  Color suggestedBuyAmountColor() =>
      suggestedBuyAmountColorFor(effectiveBaseAmount);

  /// 获取买入记录数据
  Future<void> _fetchBuyRecords() async {
    state.isLoading = true;
    state.errorMessage = null;
    final completer = Completer<void>();
    BXGet<dynamic>(
      Api.buyRecords,
      params: {'currency': state.currentCurrency},
      isShowLoading: false,
      showError: false,
      success: (isSuccess, code, message, results) {
        if (isSuccess) {
          // 接口 created_at 升序 [最旧…最新]，倒置后 state 为 [最新…最旧]，列表从上到下即最新在上。
          state.buyRecords = List<Map<String, dynamic>>.from(results.reversed);
          debugPrint('买入记录API返回条数: ${state.buyRecords.length}');
        } else {
          state.buyRecords = [];
          state.errorMessage = message.isNotEmpty ? message : '获取数据失败';
        }
        state.isLoading = false;
        if (!completer.isCompleted) completer.complete();
      },
      failed: (message, _) {
        state.buyRecords = [];
        state.errorMessage = message.isNotEmpty ? message : '请求失败';
        debugPrint('获取买入记录失败: $message');
        state.isLoading = false;
        if (!completer.isCompleted) completer.complete();
      },
    );
    await completer.future;
  }

  /// 格式化成本价
  String formatCostPrice(dynamic price) {
    try {
      if (price is num) {
        return '\$${price.toStringAsFixed(currentCurrencyConfig.costDecimals)}';
      }
      return price.toString();
    } catch (e) {
      return price.toString();
    }
  }

  /// 格式化当前价格
  String formatCurrentPrice(dynamic price) {
    try {
      if (price is num) {
        return '\$${price.toStringAsFixed(currentCurrencyConfig.priceDecimals)}';
      }
      return price.toString();
    } catch (e) {
      return price.toString();
    }
  }

  /// 格式化 SMA200（200 日均线 / 支撑线）
  String formatMaPrice(dynamic price) {
    try {
      if (price is num) {
        return '\$${price.toStringAsFixed(currentCurrencyConfig.maDecimals)}';
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

  /// 格式化成交价格
  String formatTransactionPrice(dynamic price) {
    try {
      if (price is num) {
        return '\$${price.toStringAsFixed(currentCurrencyConfig.costDecimals)}';
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
    debugPrint('总数量: $totalQuantity ${currentCurrencyConfig.label}');
    debugPrint('均价: $averagePrice USDT/${currentCurrencyConfig.label}');

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
    debugPrint('累计${currentCurrencyConfig.label}数量: $totalBtcQuantity');
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
