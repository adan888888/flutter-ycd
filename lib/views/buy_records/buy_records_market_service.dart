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
