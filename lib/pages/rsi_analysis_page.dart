import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

// RSI分析页面
class RSIAnalysisPage extends StatefulWidget {
  const RSIAnalysisPage({super.key});

  @override
  State<RSIAnalysisPage> createState() => _RSIAnalysisPageState();
}

class _RSIAnalysisPageState extends State<RSIAnalysisPage> {
  Map<String, dynamic>? _rsiResult;
  bool _isLoadingRsi = false;
  final TextEditingController _customPriceController = TextEditingController();
  bool _useCustomPrice = false;

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

  // 计算RSI 6日
  Future<void> _calculateRSI() async {
    setState(() {
      _isLoadingRsi = true;
    });

    try {
      double customPrice = 0;
      if (_useCustomPrice && _customPriceController.text.isNotEmpty) {
        customPrice = double.tryParse(_customPriceController.text) ?? 0;
        if (customPrice <= 0) {
          Fluttertoast.showToast(msg: "请输入有效的价格", toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.CENTER);
          setState(() {
            _isLoadingRsi = false;
          });
          return;
        }
      }

      // 获取价格数据 - 使用OKX API
      final response = await http.get(
        Uri.parse('https://api.binance.com/api/v3/klines?symbol=$_selectedCoin&interval=1d&limit=100'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Accept': 'application/json',
          'Accept-Language': 'en-US,en;q=0.9',
        },
      );

      debugPrint('请求URL: ${response.request?.url}');
      debugPrint('响应状态码: ${response.statusCode}');
      debugPrint('响应头: ${response.headers}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final prices = <double>[];

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
              // 币安的收盘价是第5个元素（索引4）
              prices.add(double.parse(item[4].toString()));
            } else {
              debugPrint('数据项格式异常: $item');
            }
          }
        } else {
          debugPrint('币安API返回数据格式错误: $data');
          throw Exception('币安API返回数据格式错误');
        }

        // 如果使用自定义价格，替换最后一个价格
        if (_useCustomPrice && customPrice > 0) {
          prices[prices.length - 1] = customPrice;
        }

        // 计算RSI 6日
        final rsi = _calculateRSIValue(prices, 6);
        final currentPrice = _useCustomPrice ? customPrice : prices.last;
        final rsiStatus = _getRSIStatus(rsi);

        setState(() {
          _rsiResult = {'rsi': rsi, 'currentPrice': currentPrice, 'status': rsiStatus, 'timestamp': DateTime.now(), 'isCustomPrice': _useCustomPrice};
        });
      } else {
        if (mounted) _showMessage(context, "获取数据失败");
      }
    } catch (e) {
      if (mounted) _showMessage(context, "计算RSI失败: $e");
    } finally {
      setState(() {
        _isLoadingRsi = false;
      });
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
  String _getCoinName(String symbol) {
    final coin = _coinList.firstWhere((coin) => coin['symbol'] == symbol);
    return coin['name'].split(' ')[0]; // 返回中文名称
  }

  // 显示消息 - 兼容macOS
  void _showMessage(BuildContext context, String message) {
    if (Platform.isMacOS) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } else {
      Fluttertoast.showToast(msg: message, toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.CENTER);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${_getCoinName(_selectedCoin)} RSI 分析'), backgroundColor: Theme.of(context).colorScheme.inversePrimary),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // RSI计算选项
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('RSI 6日计算', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),

                      // 币种选择
                      const Text('选择币种', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      SizedBox(
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
                                  _rsiResult = null; // 清空之前的结果
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

                      const SizedBox(height: 16),

                      // 自定义价格开关
                      Row(
                        children: [
                          Checkbox(
                            value: _useCustomPrice,
                            onChanged: (value) {
                              setState(() {
                                _useCustomPrice = value ?? false;
                                if (!_useCustomPrice) {
                                  _customPriceController.clear();
                                }
                              });
                            },
                          ),
                          const Text('使用自定义价格'),
                        ],
                      ),

                      // 自定义价格输入框
                      if (_useCustomPrice) ...[
                        const SizedBox(height: 8),
                        TextField(
                          controller: _customPriceController,
                          decoration: const InputDecoration(labelText: '假设价格 (美元)', border: OutlineInputBorder(), hintText: '例如: 100000'),
                          keyboardType: TextInputType.number,
                        ),
                      ],

                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoadingRsi ? null : _calculateRSI,
                          child: _isLoadingRsi ? const CircularProgressIndicator(color: Colors.white) : Text('计算${_getCoinName(_selectedCoin)} RSI 6日'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // RSI结果显示
              if (_rsiResult != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _rsiResult!['isCustomPrice'] ? '${_getCoinName(_selectedCoin)} RSI 6日分析 (自定义价格)' : '${_getCoinName(_selectedCoin)} RSI 6日分析 (实时价格)',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        _buildSimpleRow('当前价格', '\$${_rsiResult!['currentPrice'].toStringAsFixed(2)}'),
                        _buildSimpleRow('RSI 6日', '${_rsiResult!['rsi'].toStringAsFixed(2)}'),
                        _buildSimpleRow('市场状态', _rsiResult!['status']),
                        _buildSimpleRow('更新时间', _rsiResult!['timestamp'].toString().substring(0, 19)),
                        if (_rsiResult!['isCustomPrice']) ...[_buildSimpleRow('价格类型', '假设价格')] else ...[_buildSimpleRow('价格类型', '实时价格')],
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // 简单的行显示，不包含复制功能
  Widget _buildSimpleRow(String label, String value) {
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
    _customPriceController.dispose();
    super.dispose();
  }
}
