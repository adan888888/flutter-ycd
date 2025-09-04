import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

// 每周定投回测页面 - 最近1年数据
class RSIStrategyBacktestPage extends StatefulWidget {
  const RSIStrategyBacktestPage({super.key});

  @override
  State<RSIStrategyBacktestPage> createState() => _RSIStrategyBacktestPageState();
}

class _RSIStrategyBacktestPageState extends State<RSIStrategyBacktestPage> {
  Map<String, dynamic>? _backtestResult;
  bool _isLoadingBacktest = false;

  // 显示消息的通用函数
  void _showMessage(BuildContext context, String message) {
    if (Platform.isMacOS) {
      // macOS使用SnackBar
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 2)));
    } else {
      // 其他平台使用Fluttertoast
      Fluttertoast.showToast(msg: message, toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.CENTER);
    }
  }

  // 币种选择 - 使用币安支持的币种
  String _selectedCoin = 'BTCUSDT';
  final List<Map<String, dynamic>> _coinList = [
    {'symbol': 'BTCUSDT', 'name': '比特币 (BTC)', 'color': Colors.orange},
    {'symbol': 'ETHUSDT', 'name': '以太坊 (ETH)', 'color': Colors.blue},
    {'symbol': 'ADAUSDT', 'name': '卡尔达诺 (ADA)', 'color': Colors.teal},
    {'symbol': 'SOLUSDT', 'name': '索拉纳 (SOL)', 'color': Colors.purple},
    {'symbol': 'DOGEUSDT', 'name': '狗狗币 (DOGE)', 'color': Colors.amber},
    {'symbol': 'TRXUSDT', 'name': '波场 (TRX)', 'color': Colors.red},
  ];

  // 执行回测
  Future<void> _runBacktest() async {
    setState(() {
      _isLoadingBacktest = true;
    });

    try {
      // 获取最近1年的价格数据 - 使用币安API
      // 1年 = 365天，加上一些缓冲，请求400天数据
      final response = await http.get(
        Uri.parse('https://api.binance.com/api/v3/klines?symbol=${_selectedCoin}&interval=1d&limit=400'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Accept': 'application/json',
          'Accept-Language': 'en-US,en;q=0.9',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final prices = <double>[];
        final dates = <DateTime>[];

        // 调试：打印API返回的数据结构
        debugPrint('币安API返回数据: $data');

        // 币安API返回格式: [[timestamp, open, high, low, close, volume, ...], ...]
        if (data is List) {
          final candles = data;
          debugPrint('币安蜡烛图数据数量: ${candles.length}');
          if (candles.isNotEmpty) {
            debugPrint('第一个数据项: ${candles.first}');
          }

          for (var item in candles) {
            if (item is List && item.length >= 6) {
              // 币安的收盘价是第5个元素（索引4），时间戳是第0个元素
              prices.add(double.parse(item[4].toString())); // 收盘价
              dates.add(DateTime.fromMillisecondsSinceEpoch(int.parse(item[0].toString()))); // 时间戳
            } else {
              debugPrint('数据项格式异常: $item');
            }
          }
        } else {
          debugPrint('币安API返回数据格式错误: $data');
          throw Exception('币安API返回数据格式错误');
        }

        // 计算每日RSI
        final rsiValues = <double>[];
        for (int i = 6; i < prices.length; i++) {
          final periodPrices = prices.sublist(i - 6, i + 1);
          final rsi = _calculateRSIValue(periodPrices, 6);
          rsiValues.add(rsi);

          // 调试信息：如果RSI为0，打印详细信息
          if (rsi == 0.0) {
            debugPrint('RSI为0的日期: ${dates[i].toString().substring(0, 10)}');
            debugPrint('价格序列: ${periodPrices.map((p) => p.toStringAsFixed(2)).toList()}');
            debugPrint('价格变化: ${periodPrices.asMap().entries.skip(1).map((e) => (periodPrices[e.key] - periodPrices[e.key - 1]).toStringAsFixed(4)).toList()}');
          }
        }

        // 执行策略回测
        final result = _executeStrategy(
          prices.sublist(6), // 从第7天开始（有RSI值）
          dates.sublist(6),
          rsiValues,
        );

        setState(() {
          _backtestResult = result;
        });
      } else {
        if (mounted) _showMessage(context, "获取数据失败");
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

      if (mounted) _showMessage(context, errorMessage);
      debugPrint("详细错误信息: $e");
    } finally {
      setState(() {
        _isLoadingBacktest = false;
      });
    }
  }

  // 执行策略逻辑 - 每周定投1700元
  Map<String, dynamic> _executeStrategy(List<double> prices, List<DateTime> dates, List<double> rsiValues) {
    double totalInvested = 0;
    double totalCoins = 0;
    final trades = <Map<String, dynamic>>[];

    // 每周定投1000元
    const weeklyAmount = 1000.0;

    // 计算有多少周（最近1年约52周）
    final totalWeeks = (dates.length / 7).floor();
    final actualWeeks = totalWeeks > 52 ? 52 : totalWeeks; // 限制为52周

    // 获取真正的当前价格（使用最后一个价格作为参考）
    final lastPrice = prices.last;
    debugPrint('数据中最后价格: $lastPrice');
    debugPrint('数据中最后日期: ${dates.last}');
    debugPrint('实际回测周数: $actualWeeks');

    for (int week = 0; week < actualWeeks; week++) {
      // 每周选择一天进行投资（这里选择每周的第一天）
      final dayIndex = week * 7;
      if (dayIndex < prices.length) {
        final price = prices[dayIndex];
        final date = dates[dayIndex];
        final rsi = rsiValues[dayIndex];

        // 买入
        final coinsBought = weeklyAmount / price;
        totalInvested += weeklyAmount;
        totalCoins += coinsBought;

        trades.add({'date': date.toString().substring(0, 10), 'price': price, 'rsi': rsi, 'amount': weeklyAmount, 'coins': coinsBought, 'week': week + 1, 'type': '定投'});
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
    debugPrint('理论市值(按当前BTC价格110850): ${totalCoins * 110850}');

    return {
      'totalInvested': totalInvested,
      'totalCoins': totalCoins,
      'currentValue': currentValue,
      'totalProfit': totalProfit,
      'profitPercentage': profitPercentage,
      'trades': trades,
      'tradeCount': trades.length,
      'currentPrice': currentPrice,
      'coinName': _getCoinName(_selectedCoin),
      'period': '最近1年',
      'weeks': actualWeeks,
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
  String _getCoinName(String symbol) {
    final coin = _coinList.firstWhere((coin) => coin['symbol'] == symbol);
    return coin['name'].split(' ')[0]; // 返回中文名称
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${_getCoinName(_selectedCoin)} 每周定投回测 - 最近1年'), backgroundColor: Theme.of(context).colorScheme.inversePrimary),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 币种选择
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('选择币种', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Container(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _coinList.length,
                          itemBuilder: (context, index) {
                            final coin = _coinList[index];
                            final isSelected = _selectedCoin == coin['symbol'];
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedCoin = coin['symbol'];
                                  _backtestResult = null; // 清空之前的结果
                                });
                              },
                              child: Container(
                                width: 100,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? coin['color'].withValues(alpha: 0.2) : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isSelected ? coin['color'] : Colors.grey[300]!, width: isSelected ? 2 : 1),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.monetization_on, color: coin['color'], size: 24),
                                    const SizedBox(height: 8),
                                    Text(
                                      coin['name'].split(' ')[1], // 显示简称 BTC, ETH, ADA, SOL
                                      style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: coin['color']),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 策略参数
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('策略参数', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),

                      // 策略说明
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('每周定投策略设置', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue)),
                            SizedBox(height: 8),
                            Text('• 每周定投: \$1000', style: TextStyle(fontSize: 12)),
                            Text('• 投资频率: 每周一次', style: TextStyle(fontSize: 12)),
                            Text('• 投资时间: 每周第一天', style: TextStyle(fontSize: 12)),
                            Text('• 回测周期: 最近1年数据 (约52周)', style: TextStyle(fontSize: 12)),
                            Text('• 策略类型: 定期定额投资', style: TextStyle(fontSize: 12)),
                            Text('• 数据来源: 币安API (日K线)', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 执行回测按钮
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoadingBacktest ? null : _runBacktest,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                          child: _isLoadingBacktest ? const CircularProgressIndicator(color: Colors.white) : Text('执行${_getCoinName(_selectedCoin)}最近1年每周定投回测'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 回测结果
              if (_backtestResult != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${_backtestResult!['coinName']} 最近1年每周定投回测结果', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        _buildResultRow('回测周期', _backtestResult!['period']),
                        _buildResultRow('实际周数', '${_backtestResult!['weeks']}周'),
                        _buildResultRow('总本钱', '\$${_backtestResult!['totalInvested'].toStringAsFixed(2)}'),
                        _buildResultRow('累计买入数量', '${_backtestResult!['totalCoins'].toStringAsFixed(6)}'),
                        _buildResultRow('当前价格', '\$${_backtestResult!['currentPrice'].toStringAsFixed(2)}'),
                        _buildResultRow('总收益', '\$${_backtestResult!['totalProfit'].toStringAsFixed(2)}'),
                        _buildResultRow('本钱加收益', '\$${(_backtestResult!['totalInvested'] + _backtestResult!['totalProfit']).toStringAsFixed(2)}'),
                        _buildResultRow('收益率', '${_backtestResult!['profitPercentage'].toStringAsFixed(2)}%'),
                        _buildResultRow('交易次数', '${_backtestResult!['tradeCount']}次'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 交易记录
                if (_backtestResult!['trades'].isNotEmpty) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('最近1年交易记录', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          Container(
                            height: 500,
                            child: ListView.builder(
                              itemCount: _backtestResult!['trades'].length,
                              itemBuilder: (context, index) {
                                final trade = _backtestResult!['trades'][index];
                                return ListTile(
                                  title: Text('第${trade['week']}周 - ${trade['date']}'),
                                  subtitle: Text(
                                    '价格: \$${trade['price'].toStringAsFixed(2)} | RSI: ${trade['rsi'].toStringAsFixed(1)} | 金额: \$${trade['amount'].toStringAsFixed(2)}',
                                  ),
                                  trailing: Text('${trade['type']}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                    child: Text('${trade['week']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  // 结果行显示
  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: const TextStyle(fontSize: 16)), Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue))],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
