import 'dart:convert';

import 'package:http/http.dart' as http;

import 'buy_records_currency.dart';

class MarketQuote {
  const MarketQuote({this.price, this.ma200});

  final double? price;
  final double? ma200;
}

const int _smaPeriod = 200;
const int _dailyKlineLimit = 300;

/// 各币种近 24 小时涨跌幅（百分数，如 -4.74 表示跌 4.74%）。取不到的币种值为 null。
Future<Map<String, double?>> fetchChangePercent24h(
  List<BuyRecordsCurrency> currencies,
  Map<String, String> headers,
) async {
  final result = <String, double?>{for (final item in currencies) item.id: null};
  final groups = <BuyRecordsMarketSource, List<BuyRecordsCurrency>>{};
  for (final item in currencies) {
    groups.putIfAbsent(item.marketSource, () => []).add(item);
  }

  await Future.wait([
    _fillBinanceChange24h(groups[BuyRecordsMarketSource.binance] ?? const [], result, headers),
    _fillOkxChange24h(groups[BuyRecordsMarketSource.okx] ?? const [], result, headers),
    _fillGateChange24h(groups[BuyRecordsMarketSource.gate] ?? const [], result, headers),
    _fillEastmoneyChange24h(groups[BuyRecordsMarketSource.eastmoney] ?? const [], result, headers),
  ]);
  return result;
}

Future<MarketQuote> fetchMarketQuote(
  BuyRecordsCurrency currency,
  Map<String, String> headers,
) async {
  switch (currency.marketSource) {
    case BuyRecordsMarketSource.binance:
      return _fetchBinanceQuote(currency.marketSymbol, headers);
    case BuyRecordsMarketSource.okx:
      return _fetchOkxQuote(currency.marketSymbol, headers);
    case BuyRecordsMarketSource.gate:
      return _fetchGateQuote(currency.marketSymbol, headers);
    case BuyRecordsMarketSource.eastmoney:
      return _fetchEastmoneyQuote(currency.marketSymbol, headers);
  }
}

Future<MarketQuote> _fetchBinanceQuote(
  String symbol,
  Map<String, String> headers,
) async {
  final responses = await Future.wait([
    http
        .get(
          Uri.parse('https://api.binance.com/api/v3/ticker/price?symbol=$symbol'),
          headers: headers,
        )
        .timeout(const Duration(seconds: 30)),
    http
        .get(
          Uri.parse(
            'https://api.binance.com/api/v3/klines?symbol=$symbol&interval=1d&limit=$_dailyKlineLimit',
          ),
          headers: headers,
        )
        .timeout(const Duration(seconds: 30)),
  ]);

  double? price;
  if (responses[0].statusCode == 200) {
    final data = json.decode(responses[0].body);
    if (data is Map && data['price'] != null) {
      price = double.tryParse(data['price'].toString());
    }
  }

  double? ma200;
  if (responses[1].statusCode == 200) {
    final data = json.decode(responses[1].body);
    if (data is List) {
      ma200 = _ma200FromDailyCloses(_binanceDailyCloses(data));
    }
  }

  return MarketQuote(price: price, ma200: ma200);
}

Future<MarketQuote> _fetchOkxQuote(
  String instId,
  Map<String, String> headers,
) async {
  final responses = await Future.wait([
    http
        .get(
          Uri.parse(
            'https://www.okx.com/api/v5/market/ticker?instId=${Uri.encodeComponent(instId)}',
          ),
          headers: headers,
        )
        .timeout(const Duration(seconds: 30)),
    http
        .get(
          Uri.parse(
            'https://www.okx.com/api/v5/market/candles?instId=${Uri.encodeComponent(instId)}&bar=1D&limit=$_dailyKlineLimit',
          ),
          headers: headers,
        )
        .timeout(const Duration(seconds: 30)),
  ]);

  double? price;
  double? ma200;
  List<dynamic>? rawCandles;

  if (responses[1].statusCode == 200) {
    final data = json.decode(responses[1].body);
    if (data is Map && data['code'].toString() == '0' && data['data'] is List) {
      rawCandles = data['data'] as List;
      ma200 = _ma200FromDailyCloses(_okxDailyCloses(rawCandles));
    }
  }

  if (responses[0].statusCode == 200) {
    final data = json.decode(responses[0].body);
    if (data is Map &&
        data['code'].toString() == '0' &&
        data['data'] is List &&
        (data['data'] as List).isNotEmpty) {
      final row = (data['data'] as List).first;
      if (row is Map && row['last'] != null) {
        price = double.tryParse(row['last'].toString());
      }
    }
  }

  price ??= _okxLatestClose(rawCandles);

  return MarketQuote(price: price, ma200: ma200);
}

Future<MarketQuote> _fetchGateQuote(
  String currencyPair,
  Map<String, String> headers,
) async {
  final pair = Uri.encodeComponent(currencyPair);
  final responses = await Future.wait([
    http
        .get(
          Uri.parse('https://api.gateio.ws/api/v4/spot/tickers?currency_pair=$pair'),
          headers: headers,
        )
        .timeout(const Duration(seconds: 30)),
    http
        .get(
          Uri.parse(
            'https://api.gateio.ws/api/v4/spot/candlesticks?currency_pair=$pair&interval=1d&limit=$_dailyKlineLimit',
          ),
          headers: headers,
        )
        .timeout(const Duration(seconds: 30)),
  ]);

  double? price;
  if (responses[0].statusCode == 200) {
    final data = json.decode(responses[0].body);
    if (data is List && data.isNotEmpty) {
      final row = data.first;
      if (row is Map && row['last'] != null) {
        price = double.tryParse(row['last'].toString());
      }
    }
  }

  double? ma200;
  if (responses[1].statusCode == 200) {
    final data = json.decode(responses[1].body);
    if (data is List) {
      ma200 = _ma200FromDailyCloses(_gateDailyCloses(data));
    }
  }

  return MarketQuote(price: price, ma200: ma200);
}

Future<void> _fillBinanceChange24h(
  List<BuyRecordsCurrency> currencies,
  Map<String, double?> result,
  Map<String, String> headers,
) async {
  if (currencies.isEmpty) return;
  try {
    final symbols = jsonEncode(currencies.map((item) => item.marketSymbol).toList());
    final response = await http
        .get(
          Uri.https('api.binance.com', '/api/v3/ticker/24hr', {'symbols': symbols}),
          headers: headers,
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) return;
    final data = json.decode(response.body);
    if (data is! List) return;
    final bySymbol = <String, double>{};
    for (final row in data) {
      if (row is! Map) continue;
      final symbol = row['symbol']?.toString();
      final percent = double.tryParse(row['priceChangePercent']?.toString() ?? '');
      if (symbol != null && percent != null) bySymbol[symbol] = percent;
    }
    for (final item in currencies) {
      result[item.id] = bySymbol[item.marketSymbol];
    }
  } catch (_) {}
}

Future<void> _fillOkxChange24h(
  List<BuyRecordsCurrency> currencies,
  Map<String, double?> result,
  Map<String, String> headers,
) async {
  await Future.wait(currencies.map((item) async {
    try {
      final response = await http
          .get(
            Uri.https('www.okx.com', '/api/v5/market/ticker', {'instId': item.marketSymbol}),
            headers: headers,
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) return;
      final data = json.decode(response.body);
      if (data is! Map || data['code'].toString() != '0' || data['data'] is! List) return;
      final rows = data['data'] as List;
      if (rows.isEmpty || rows.first is! Map) return;
      final row = rows.first as Map;
      final last = double.tryParse(row['last']?.toString() ?? '');
      final open = double.tryParse(row['open24h']?.toString() ?? '');
      if (last == null || open == null || open == 0) return;
      result[item.id] = (last - open) / open * 100;
    } catch (_) {}
  }));
}

Future<void> _fillGateChange24h(
  List<BuyRecordsCurrency> currencies,
  Map<String, double?> result,
  Map<String, String> headers,
) async {
  await Future.wait(currencies.map((item) async {
    try {
      final response = await http
          .get(
            Uri.https('api.gateio.ws', '/api/v4/spot/tickers', {'currency_pair': item.marketSymbol}),
            headers: headers,
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) return;
      final data = json.decode(response.body);
      if (data is! List || data.isEmpty || data.first is! Map) return;
      final percent = double.tryParse((data.first as Map)['change_percentage']?.toString() ?? '');
      if (percent != null) result[item.id] = percent;
    } catch (_) {}
  }));
}

Future<void> _fillEastmoneyChange24h(
  List<BuyRecordsCurrency> currencies,
  Map<String, double?> result,
  Map<String, String> headers,
) async {
  if (currencies.isEmpty) return;
  try {
    final response = await http
        .get(
          Uri.https('push2.eastmoney.com', '/api/qt/ulist.np/get', {
            'fltt': '2',
            'secids': currencies.map((item) => item.marketSymbol).join(','),
            'fields': 'f12,f3',
          }),
          headers: headers,
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) return;
    final data = json.decode(response.body);
    if (data is! Map || data['data'] is! Map) return;
    final diff = (data['data'] as Map)['diff'];
    if (diff is! List) return;
    final byCode = <String, double>{};
    for (final row in diff) {
      if (row is! Map) continue;
      final code = row['f12']?.toString().toUpperCase();
      final percent = row['f3'] is num ? (row['f3'] as num).toDouble() : double.tryParse(row['f3']?.toString() ?? '');
      if (code != null && percent != null) byCode[code] = percent;
    }
    for (final item in currencies) {
      final code = item.marketSymbol.split('.').last.toUpperCase();
      result[item.id] = byCode[code];
    }
  } catch (_) {}
}

/// 东方财富日 K 只有一个接口：最新一根的收盘价即当前点位（盘中实时更新）。
Future<MarketQuote> _fetchEastmoneyQuote(
  String secid,
  Map<String, String> headers,
) async {
  final response = await http
      .get(
        Uri.parse(
          'https://push2his.eastmoney.com/api/qt/stock/kline/get?secid=${Uri.encodeComponent(secid)}'
          '&fields1=f1,f2,f3&fields2=f51,f53&klt=101&fqt=0&end=20500101&lmt=$_dailyKlineLimit',
        ),
        headers: headers,
      )
      .timeout(const Duration(seconds: 30));

  if (response.statusCode != 200) return const MarketQuote();
  final data = json.decode(response.body);
  if (data is! Map || data['data'] is! Map) return const MarketQuote();
  final klines = (data['data'] as Map)['klines'];
  if (klines is! List) return const MarketQuote();

  final closeUtcHour = _eastmoneyCloseUtcHour(secid);
  final nowUtc = DateTime.now().toUtc();
  final closes = <double>[];
  double? price;

  for (final item in klines) {
    final parts = item.toString().split(',');
    if (parts.length < 2) continue;
    final day = DateTime.tryParse(parts[0]);
    final close = double.tryParse(parts[1]);
    if (day == null || close == null) continue;
    price = close;
    final closedAt = DateTime.utc(day.year, day.month, day.day, closeUtcHour);
    if (nowUtc.isBefore(closedAt)) continue;
    closes.add(close);
  }

  return MarketQuote(price: price, ma200: _ma200FromDailyCloses(closes));
}

/// 当日 K 线的收盘时刻（UTC 小时）。A 股 15:00 北京时间；美股 16:00 纽约时间，按冬令时 21:00 UTC 取较晚值。
int _eastmoneyCloseUtcHour(String secid) => secid.startsWith('100.') ? 21 : 7;

List<double> _binanceDailyCloses(List<dynamic> candles) {
  final nowMs = DateTime.now().millisecondsSinceEpoch;
  final closes = <double>[];

  for (final item in candles) {
    if (item is! List || item.length <= 6) continue;
    final closeTime = int.tryParse(item[6].toString());
    final closePrice = double.tryParse(item[4].toString());
    if (closeTime == null || closePrice == null) continue;
    if (closeTime > nowMs) continue;
    closes.add(closePrice);
  }

  return closes;
}

List<double> _okxDailyCloses(List<dynamic> candles) {
  final nowMs = DateTime.now().millisecondsSinceEpoch;
  final rows = <List<dynamic>>[];

  for (final item in candles) {
    if (item is List && item.length >= 5) {
      rows.add(item);
    }
  }

  rows.sort((a, b) {
    final ta = int.tryParse(a[0].toString()) ?? 0;
    final tb = int.tryParse(b[0].toString()) ?? 0;
    return ta.compareTo(tb);
  });

  final closes = <double>[];
  for (final item in rows) {
    final openTime = int.tryParse(item[0].toString());
    final closePrice = double.tryParse(item[4].toString());
    if (openTime == null || closePrice == null) continue;

    final confirmed = item.length > 8 ? item[8].toString() == '1' : openTime <= nowMs;
    if (!confirmed) continue;

    closes.add(closePrice);
  }

  return closes;
}

double? _okxLatestClose(List<dynamic>? candles) {
  if (candles == null || candles.isEmpty) return null;

  final rows = <List<dynamic>>[];
  for (final item in candles) {
    if (item is List && item.length >= 5) {
      rows.add(item);
    }
  }
  if (rows.isEmpty) return null;

  rows.sort((a, b) {
    final ta = int.tryParse(a[0].toString()) ?? 0;
    final tb = int.tryParse(b[0].toString()) ?? 0;
    return ta.compareTo(tb);
  });

  return double.tryParse(rows.last[4].toString());
}

List<double> _gateDailyCloses(List<dynamic> candles) {
  final nowMs = DateTime.now().millisecondsSinceEpoch;
  final rows = <List<dynamic>>[];

  for (final item in candles) {
    if (item is List && item.length >= 3) {
      rows.add(item);
    }
  }

  rows.sort((a, b) {
    final ta = int.tryParse(a[0].toString()) ?? 0;
    final tb = int.tryParse(b[0].toString()) ?? 0;
    return ta.compareTo(tb);
  });

  final closes = <double>[];
  for (final item in rows) {
    final openTimeSec = int.tryParse(item[0].toString());
    final closePrice = double.tryParse(item[2].toString());
    if (openTimeSec == null || closePrice == null) continue;
    if (openTimeSec * 1000 > nowMs) continue;
    closes.add(closePrice);
  }

  return closes;
}

double? _ma200FromDailyCloses(List<double> closes) {
  if (closes.length < _smaPeriod) return null;
  var sum = 0.0;
  final slice = closes.sublist(closes.length - _smaPeriod);
  for (final value in slice) {
    sum += value;
  }
  return sum / _smaPeriod;
}
