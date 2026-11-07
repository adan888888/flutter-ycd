import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ycd/utils/network/api.dart';
import 'package:ycd/utils/network/http_mgr.dart';
import 'package:ycd/utils/storage_util.dart';

import 'buy_records_currency.dart';
import 'buy_records_market_service.dart';
import 'buy_records_state.dart';

/// 买入记录页面控制器
class BuyRecordsController extends GetxController {
  static const _baseAmountsStorageKey = 'buy_records_base_amounts';

  /// 状态管理
  final BuyRecordsState state = BuyRecordsState();
  int _currencyRequestSequence = 0;
  int _changePercentRequestSequence = 0;

  BuyRecordsCurrency get currentCurrencyConfig =>
      findBuyRecordsCurrency(state.currentCurrency) ??
      defaultBuyRecordsCurrency;

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

  String formatSuggestedBuyAmountFor(double baseAmount,
      {double? deviationPercent}) {
    final deviation = deviationPercent ?? ma200DailyDeviationPercent;
    final amount = suggestedBuyAmountUsdt(deviation, baseAmount);
    if (amount == null) return '—';
    if (amount == 0) return '停止买入';
    return formatBuyAmountUsdt(amount);
  }

  Color suggestedBuyAmountColorFor(double baseAmount,
      {double? deviationPercent}) {
    final deviation = deviationPercent ?? ma200DailyDeviationPercent;
    final amount = suggestedBuyAmountUsdt(deviation, baseAmount);
    if (amount == null) return Colors.grey;
    if (amount == 0) return Colors.orange;
    if (amount > baseAmount) return Colors.green;
    if (amount < baseAmount) return Colors.deepOrange;
    return Colors.black;
  }

  /// 初始化数据。当前币种数据与全量 24h 涨跌并行刷新，互不阻塞 UI。
  Future<void> _initializeData() async {
    await Future.wait([
      _loadCurrentCurrencyData(),
      _fetchChangePercent24h(),
    ]);
  }

  Future<void> _fetchChangePercent24h() async {
    final requestSequence = ++_changePercentRequestSequence;
    try {
      final result =
          await fetchChangePercent24h(buyRecordsCurrencies, _marketHeaders);
      if (requestSequence != _changePercentRequestSequence) return;
      state.changePercent24h = result;
      update();
    } catch (e) {
      debugPrint('获取24小时涨跌失败: $e');
    }
  }

  /// 只加载当前币种的记录和行情。请求序号可阻止快速切换时旧响应回写。
  Future<void> _loadCurrentCurrencyData() async {
    final requestSequence = ++_currencyRequestSequence;
    final currencyId = state.currentCurrency;
    final config = currentCurrencyConfig;

    state.isLoading = true;
    state.errorMessage = null;
    state.buyRecords = [];
    state.currentPrice = null;
    state.ma200Daily = null;
    update();

    final recordsFuture = _fetchBuyRecords(currencyId);
    final quoteFuture = _fetchMarketQuoteSafely(config);

    try {
      final results = await Future.wait<Object?>([
        recordsFuture,
        quoteFuture,
      ]);
      if (!_isLatestCurrencyRequest(requestSequence, currencyId)) return;

      final recordsResult = results[0] as _BuyRecordsFetchResult;
      final quote = results[1] as MarketQuote?;
      state.buyRecords = recordsResult.records;
      state.errorMessage = recordsResult.errorMessage;
      state.currentPrice = quote?.price;
      state.ma200Daily = quote?.ma200;

      if (quote?.price != null) {
        debugPrint(
            '当前${config.label}价格(${config.exchangeName}): ${quote!.price}');
      } else {
        debugPrint('获取${config.label}价格失败 (${config.exchangeName})');
      }

      if (quote?.ma200 != null) {
        debugPrint('当前${config.label} SMA200(1d): ${quote!.ma200}');
      } else if (quote?.price != null) {
        debugPrint('${config.label} 已收盘日K数量不足，无法计算 SMA200');
      }
    } catch (e) {
      if (!_isLatestCurrencyRequest(requestSequence, currencyId)) return;
      state.buyRecords = [];
      state.currentPrice = null;
      state.ma200Daily = null;
      state.errorMessage = '加载数据失败';
      debugPrint('加载${config.label}数据失败: $e');
    } finally {
      if (_isLatestCurrencyRequest(requestSequence, currencyId)) {
        state.isLoading = false;
        update();
      }
    }
  }

  bool _isLatestCurrencyRequest(int requestSequence, String currencyId) =>
      requestSequence == _currencyRequestSequence &&
      state.currentCurrency == currencyId;

  Future<MarketQuote?> _fetchMarketQuoteSafely(
      BuyRecordsCurrency config) async {
    try {
      return await fetchMarketQuote(config, _marketHeaders);
    } catch (e) {
      debugPrint('获取${config.label}行情失败: $e');
      return null;
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

  /// 获取指定币种的买入记录。异步回调只返回结果，不直接修改页面状态。
  Future<_BuyRecordsFetchResult> _fetchBuyRecords(String currencyId) async {
    final completer = Completer<_BuyRecordsFetchResult>();
    try {
      BXGet<dynamic>(
        Api.buyRecords,
        params: {'currency': currencyId},
        isShowLoading: false,
        showError: false,
        success: (isSuccess, code, message, results) {
          if (completer.isCompleted) return;
          if (isSuccess) {
            try {
              // 接口 created_at 升序 [最旧…最新]，倒置后页面为 [最新…最旧]。
              final records = List<Map<String, dynamic>>.from(results.reversed);
              debugPrint('$currencyId 买入记录API返回条数: ${records.length}');
              completer.complete(_BuyRecordsFetchResult(records: records));
            } catch (e) {
              debugPrint('解析$currencyId买入记录失败: $e');
              completer.complete(
                const _BuyRecordsFetchResult(errorMessage: '数据解析失败'),
              );
            }
          } else {
            completer.complete(
              _BuyRecordsFetchResult(
                errorMessage: message.isNotEmpty ? message : '获取数据失败',
              ),
            );
          }
        },
        failed: (message, _) {
          if (completer.isCompleted) return;
          debugPrint('获取$currencyId买入记录失败: $message');
          completer.complete(
            _BuyRecordsFetchResult(
              errorMessage: message.isNotEmpty ? message : '请求失败',
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('发起$currencyId买入记录请求失败: $e');
      if (!completer.isCompleted) {
        completer.complete(
          const _BuyRecordsFetchResult(errorMessage: '请求失败'),
        );
      }
    }
    return completer.future;
  }

  /// 格式化成本价
  String formatCostPrice(dynamic price) => _formatCoinPrice(price);

  /// 格式化当前价格。按原价截断，不四舍五入。
  String formatCurrentPrice(dynamic price) => _formatCoinPrice(price);

  /// 格式化 SMA200（200 日均线 / 支撑线）
  String formatMaPrice(dynamic price) => _formatCoinPrice(price);

  /// 币价小数位不固定。超出 12 位时直接截掉，不四舍五入，并去掉末尾的 0。
  String _formatCoinPrice(dynamic price) {
    try {
      if (price is num) {
        return '\$${_truncateDecimal(price.toDouble(), 12)}';
      }
      return price.toString();
    } catch (e) {
      return price.toString();
    }
  }

  String _truncateDecimal(double value, int maxDecimals) {
    if (value == 0) return '0';
    final negative = value < 0;
    final text = value.abs().toString().toLowerCase();
    final match =
        RegExp(r'^(\d+)(?:\.(\d+))?(?:e([+-]?\d+))?$').firstMatch(text);
    if (match == null) return value.toString();

    final digits = '${match.group(1)}${match.group(2) ?? ''}';
    final exp = int.tryParse(match.group(3) ?? '') ?? 0;
    final point = match.group(1)!.length + exp;
    String body;
    if (point <= 0) {
      body = '0.${'0' * (-point)}$digits';
    } else if (point >= digits.length) {
      body = digits + '0' * (point - digits.length);
    } else {
      body = '${digits.substring(0, point)}.${digits.substring(point)}';
    }

    final parts = body.split('.');
    if (parts.length == 1) return negative ? '-$body' : body;
    var fraction = parts[1];
    if (fraction.length > maxDecimals) {
      fraction = fraction.substring(0, maxDecimals);
    }
    fraction = fraction.replaceFirst(RegExp(r'0+$'), '');
    final shown = fraction.isEmpty ? parts[0] : '${parts[0]}.$fraction';
    return negative ? '-$shown' : shown;
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
  String formatTransactionPrice(dynamic price) => _formatCoinPrice(price);

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

  /// 格式化累计数量：大数少小数位，小数币种多保留
  String formatQuantity(dynamic quantity) {
    try {
      if (quantity is! num) return quantity.toString();
      final value = quantity.toDouble();
      if (value >= 1000) return value.toStringAsFixed(2);
      if (value >= 1) return value.toStringAsFixed(4);
      return value.toStringAsFixed(8);
    } catch (e) {
      return quantity.toString();
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

    return {
      'totalCost': totalCost,
      'totalQuantity': totalQuantity,
      'averagePrice': averagePrice
    };
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
      unawaited(_loadCurrentCurrencyData());
    }
  }

  /// 刷新所有数据
  Future<void> refreshAllData() async {
    await _initializeData();
  }
}

class _BuyRecordsFetchResult {
  const _BuyRecordsFetchResult({
    this.records = const [],
    this.errorMessage,
  });

  final List<Map<String, dynamic>> records;
  final String? errorMessage;
}
