import 'package:flutter/material.dart';

enum BuyRecordsMarketSource { binance, okx, gate }

/// 买币记录页支持的币种（交易对均为 /USDT）
class BuyRecordsCurrency {
  const BuyRecordsCurrency({
    required this.id,
    required this.label,
    required this.marketSource,
    required this.marketSymbol,
    required this.exchangeName,
    required this.color,
    required this.baseAmount,
    this.priceDecimals = 2,
    this.maDecimals = 2,
    this.costDecimals = 3,
  });

  final String id;
  final String label;
  final BuyRecordsMarketSource marketSource;
  /// Binance: BTCUSDT；OKX: OKB-USDT；Gate: CRCLON_USDT
  final String marketSymbol;
  final String exchangeName;
  final Color color;
  /// 基准买入金额（USDT），建议买入按相对 200MA 偏离档位在此基准上增减。
  final double baseAmount;
  final int priceDecimals;
  final int maDecimals;
  final int costDecimals;
}

const List<BuyRecordsCurrency> buyRecordsCurrencies = [
  BuyRecordsCurrency(
    id: 'trx',
    label: 'TRX',
    marketSource: BuyRecordsMarketSource.binance,
    marketSymbol: 'TRXUSDT',
    exchangeName: 'Binance',
    color: Colors.red,
    baseAmount: 100,
    priceDecimals: 4,
    maDecimals: 4,
    costDecimals: 5,
  ),
  BuyRecordsCurrency(
    id: 'btc',
    label: 'BTC',
    marketSource: BuyRecordsMarketSource.binance,
    marketSymbol: 'BTCUSDT',
    exchangeName: 'Binance',
    color: Colors.orange,
    baseAmount: 1000,
  ),
  BuyRecordsCurrency(
    id: 'eth',
    label: 'ETH',
    marketSource: BuyRecordsMarketSource.binance,
    marketSymbol: 'ETHUSDT',
    exchangeName: 'Binance',
    color: Colors.blue,
    baseAmount: 500,
  ),
  BuyRecordsCurrency(
    id: 'bnb',
    label: 'BNB',
    marketSource: BuyRecordsMarketSource.binance,
    marketSymbol: 'BNBUSDT',
    exchangeName: 'Binance',
    color: Colors.yellow,
    baseAmount: 300,
  ),
  BuyRecordsCurrency(
    id: 'xaut',
    label: 'XAUT',
    marketSource: BuyRecordsMarketSource.okx,
    marketSymbol: 'XAUT-USDT',
    exchangeName: 'OKX',
    color: Colors.amber,
    baseAmount: 100,
  ),
  BuyRecordsCurrency(
    id: 'okb',
    label: 'OKB',
    marketSource: BuyRecordsMarketSource.okx,
    marketSymbol: 'OKB-USDT',
    exchangeName: 'OKX',
    color: Colors.blueGrey,
    baseAmount: 100,
  ),
  BuyRecordsCurrency(
    id: 'link',
    label: 'LINK',
    marketSource: BuyRecordsMarketSource.binance,
    marketSymbol: 'LINKUSDT',
    exchangeName: 'Binance',
    color: Colors.cyan,
    baseAmount: 200,
  ),
  BuyRecordsCurrency(
    id: 'crclon',
    label: 'CRCLON',
    marketSource: BuyRecordsMarketSource.gate,
    marketSymbol: 'CRCLON_USDT',
    exchangeName: 'Gate',
    color: Colors.teal,
    baseAmount: 100,
  ),
  BuyRecordsCurrency(
    id: 'doge',
    label: 'DOGE',
    marketSource: BuyRecordsMarketSource.binance,
    marketSymbol: 'DOGEUSDT',
    exchangeName: 'Binance',
    color: Colors.brown,
    baseAmount: 100,
    priceDecimals: 4,
    maDecimals: 4,
  ),
  BuyRecordsCurrency(
    id: 'ada',
    label: 'ADA',
    marketSource: BuyRecordsMarketSource.okx,
    marketSymbol: 'ADA-USDT',
    exchangeName: 'OKX',
    color: Colors.green,
    baseAmount: 100,
  ),
  BuyRecordsCurrency(
    id: 'night',
    label: 'NIGHT',
    marketSource: BuyRecordsMarketSource.okx,
    marketSymbol: 'NIGHT-USDT',
    exchangeName: 'OKX',
    color: Colors.indigo,
    baseAmount: 100,
  ),
];

BuyRecordsCurrency? findBuyRecordsCurrency(String id) {
  for (final item in buyRecordsCurrencies) {
    if (item.id == id) return item;
  }
  return null;
}

BuyRecordsCurrency get defaultBuyRecordsCurrency =>
    findBuyRecordsCurrency('btc') ?? buyRecordsCurrencies.first;

/// 根据现价相对 200MA 的偏离百分比，在 [baseAmount] 基准上计算建议买入金额（USDT）。
/// [deviationPercent] = (现价 - 200MA) / 200MA * 100
double? suggestedBuyAmountUsdt(double? deviationPercent, double baseAmount) {
  if (deviationPercent == null) return null;

  if (deviationPercent > 20) return 0;

  if (deviationPercent >= 0) {
    if (deviationPercent >= 15) return baseAmount * 0.25;
    if (deviationPercent >= 10) return baseAmount * 0.50;
    if (deviationPercent >= 5) return baseAmount * 0.75;
    return baseAmount;
  }

  final abs = deviationPercent.abs();
  if (abs >= 20) return baseAmount * 2.0;
  if (abs >= 15) return baseAmount * 1.75;
  if (abs >= 10) return baseAmount * 1.50;
  if (abs >= 5) return baseAmount * 0.75;
  return baseAmount;
}

String formatBuyAmountUsdt(double amount) {
  if (amount == amount.roundToDouble()) {
    return '\$${amount.toStringAsFixed(0)}';
  }
  return '\$${amount.toStringAsFixed(2)}';
}
