import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BuyRecordsPage extends StatefulWidget {
  const BuyRecordsPage({super.key});

  @override
  State<BuyRecordsPage> createState() => _BuyRecordsPageState();
}

class _BuyRecordsPageState extends State<BuyRecordsPage> {
  List<Map<String, dynamic>> _buyRecords = [];
  bool _isLoading = false;
  String? _errorMessage;
  double? _currentPrice;
  String _currentCurrency = 'btc'; // 当前选择的币种

  @override
  void initState() {
    super.initState();
    _fetchBuyRecords();
    _fetchCurrentPrice();
  }

  // 获取当前价格
  Future<void> _fetchCurrentPrice() async {
    try {
      final symbol = _currentCurrency == 'btc' ? 'BTCUSDT' : 'ETHUSDT';
      final response = await http.get(
        Uri.parse('https://api.binance.com/api/v3/ticker/price?symbol=$symbol'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Accept': 'application/json',
          'Accept-Language': 'en-US,en;q=0.9',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map && data['price'] != null) {
          setState(() {
            _currentPrice = double.parse(data['price'].toString());
          });
          debugPrint('当前${_currentCurrency.toUpperCase()}价格: $_currentPrice');
        }
      }
    } catch (e) {
      debugPrint('获取当前价格失败: $e');
    }
  }

  // 获取买入记录数据
  Future<void> _fetchBuyRecords() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/buyRecords?currency=$_currentCurrency'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
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
            setState(() {
              _buyRecords = List<Map<String, dynamic>>.from(dataList);
            });
          } else {
            // data为null时，显示暂无购买
            setState(() {
              _buyRecords = [];
            });
          }
        } else if (data is List) {
          setState(() {
            _buyRecords = List<Map<String, dynamic>>.from(data);
          });
        } else {
          setState(() {
            _errorMessage = '数据格式错误: ${data['msg'] ?? '未知错误'}';
          });
        }
      } else {
        setState(() {
          _errorMessage = '获取数据失败: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '请求失败: $e';
      });
      debugPrint('获取买入记录失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 格式化价格
  String _formatPrice(dynamic price) {
    try {
      if (price is num) {
        return '\$${price.toStringAsFixed(2)}';
      }
      return price.toString();
    } catch (e) {
      return price.toString();
    }
  }

  // 格式化价格 (保留四位小数)
  String _formatPriceWithDecimals(dynamic price) {
    try {
      if (price is num) {
        return '\$${price.toStringAsFixed(4)}';
      }
      return price.toString();
    } catch (e) {
      return price.toString();
    }
  }

  // 格式化价格 (整数，无小数)
  String _formatPriceInteger(dynamic price) {
    try {
      if (price is num) {
        return '\$${price.toInt()}';
      }
      return price.toString();
    } catch (e) {
      return price.toString();
    }
  }

  // 格式化价格 (保留两位小数)
  String _formatPriceTwoDecimals(dynamic price) {
    try {
      if (price is num) {
        return '\$${price.toStringAsFixed(2)}';
      }
      return price.toString();
    } catch (e) {
      return price.toString();
    }
  }

  // 格式化价格 (保留四位小数)
  String _formatPriceFourDecimals(dynamic price) {
    try {
      if (price is num) {
        return '\$${price.toStringAsFixed(4)}';
      }
      return price.toString();
    } catch (e) {
      return price.toString();
    }
  }

  // 计算累计统计信息 (到第n笔记录为止)
  Map<String, dynamic> _calculateCumulativeStats(int recordCount) {
    if (_buyRecords.isEmpty || recordCount <= 0) {
      return {};
    }

    double totalCost = 0;
    double totalQuantity = 0;

    // 只计算前n笔记录
    for (int i = 0; i < recordCount && i < _buyRecords.length; i++) {
      final record = _buyRecords[i];
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

  // 计算累计收益统计 (基于当前实时价格)
  Map<String, dynamic> _calculateCurrentProfitStats(int recordIndex) {
    if (_buyRecords.isEmpty || _currentPrice == null || recordIndex < 0 || recordIndex >= _buyRecords.length) {
      return {};
    }

    // 计算累计的买入金额和BTC数量
    double totalBuyAmount = 0;
    double totalBtcQuantity = 0;

    for (int i = 0; i <= recordIndex; i++) {
      final record = _buyRecords[i];
      final buyPrice = record['buy_price'] as num?;
      final buyAmount = record['buy_amount'] as num?;

      if (buyPrice != null && buyAmount != null) {
        totalBuyAmount += buyAmount;
        totalBtcQuantity += buyAmount / buyPrice;
      }
    }

    if (totalBtcQuantity == 0) return {};

    // 累计当前价值
    final currentValue = totalBtcQuantity * _currentPrice!;

    // 累计收益
    final profit = currentValue - totalBuyAmount;

    // 累计收益率
    final profitPercentage = (profit / totalBuyAmount) * 100;

    debugPrint('累计收益调试 (前${recordIndex + 1}笔):');
    debugPrint('累计买入金额: $totalBuyAmount');
    debugPrint('累计BTC数量: $totalBtcQuantity');
    debugPrint('当前价格: $_currentPrice');
    debugPrint('累计当前价值: $currentValue');
    debugPrint('累计收益: $profit');
    debugPrint('累计收益率: ${profitPercentage.toStringAsFixed(2)}%');

    return {'totalBuyAmount': totalBuyAmount, 'totalBtcQuantity': totalBtcQuantity, 'currentValue': currentValue, 'profit': profit, 'profitPercentage': profitPercentage};
  }

  // 切换币种
  void _switchCurrency(String currency) {
    if (_currentCurrency != currency) {
      setState(() {
        _currentCurrency = currency;
      });
      // 切换币种后重新获取数据
      _fetchBuyRecords();
      _fetchCurrentPrice();
    }
  }

  // 刷新所有数据
  Future<void> _refreshAllData() async {
    // 同时刷新买入记录和当前价格
    await Future.wait([_fetchBuyRecords(), _fetchCurrentPrice()]);
  }

  // 构建币种选择器
  Widget _buildCurrencySelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('选择币种', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[700])),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildCurrencyCard('btc', 'BTC', Colors.orange),
                const SizedBox(width: 12),
                _buildCurrencyCard('eth', 'ETH', Colors.blue),
                const SizedBox(width: 12),
                _buildCurrencyCard('ada', 'ADA', Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 构建币种选择卡片
  Widget _buildCurrencyCard(String currency, String label, Color color) {
    final isSelected = _currentCurrency == currency;
    return Expanded(
      child: InkWell(
        onTap: () => _switchCurrency(currency),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.1) : Colors.grey[100],
            border: Border.all(color: isSelected ? color : Colors.grey[300]!, width: isSelected ? 2 : 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('($label)', style: TextStyle(color: isSelected ? color : Colors.grey[600], fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 12)),
              const SizedBox(height: 4),
              Icon(Icons.attach_money, size: 24, color: isSelected ? color : Colors.grey[600]),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('买入记录'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshAllData, tooltip: '刷新数据')],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(), SizedBox(height: 16), Text('正在加载买入记录...')]));
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: const TextStyle(fontSize: 16, color: Colors.red), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchBuyRecords, child: const Text('重试')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchBuyRecords,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 币种切换区域
          _buildCurrencySelector(),
          const SizedBox(height: 16),
          // 买入记录列表区域
          if (_buyRecords.isEmpty)
            // 没有记录时显示提示
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [Icon(Icons.inbox_outlined, size: 64, color: Colors.grey), SizedBox(height: 16), Text('暂无买入记录', style: TextStyle(fontSize: 16, color: Colors.grey))],
              ),
            )
          else
            // 有记录时显示列表
            ...List.generate(_buyRecords.length, (index) {
              final recordIndex = _buyRecords.length - 1 - index; // 倒序索引
              final record = _buyRecords[recordIndex];
              return _buildRecordCard(record, recordIndex);
            }),
        ],
      ),
    );
  }

  Widget _buildRecordCard(Map<String, dynamic> record, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('第${index + 1}笔#', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue)),
            Row(
              children: [
                Expanded(child: _buildCompactRecordDetails(record)),
              ],
            ),

            const Divider(height: 8),

            // 累计投资统计 (前N笔)
            _buildCumulativeStats(index + 1),

            // 只有最后一条记录才显示与当前价格的比较，并且只在有内容时才显示分隔线
            if (_currentPrice != null && index == _buyRecords.length - 1) ...[const Divider(height: 6), _buildCurrentProfitStats(index)],
          ],
        ),
      ),
    );
  }

  Widget _buildCompactRecordDetails(Map<String, dynamic> record) {
    return Row(
      children: [
        const Text('买入价格: ', style: TextStyle(fontSize: 10, color: Colors.grey)),
        Text(_formatPriceWithDecimals(record['buy_price']), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
        const SizedBox(width: 20),
        const Text('数量: ', style: TextStyle(fontSize: 10, color: Colors.grey)),
        Text(record['buy_amount']?.toString() ?? '未知', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Row(
      children: [
        Text('$label ', style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(width: 8), // 添加右侧间距
      ],
    );
  }

  Widget _buildCumulativeStats(int recordCount) {
    final stats = _calculateCumulativeStats(recordCount);
    if (stats.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 2),
        Row(
          children: [
            _buildStatItem('总成本', _formatPriceInteger(stats['totalCost']), Colors.black),
            _buildStatItem('均价', _formatPriceTwoDecimals(stats['averagePrice']), Colors.black),
            Expanded(child: _buildStatItem('总数量', stats['totalQuantity'].toStringAsFixed(8), Colors.grey)),
          ],
        ),
      ],
    );
  }

  Widget _buildCurrentProfitStats(int index) {
    final profitStats = _calculateCurrentProfitStats(index);
    if (profitStats.isEmpty) return const SizedBox.shrink();

    final profit = profitStats['profit'] as double;
    final isProfit = profit >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        const Text('统计信息', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.purple)),
        const SizedBox(height: 2),
        Column(
          children: [
            _buildStatItem('收益率    ', '${profitStats['profitPercentage'].toStringAsFixed(2)}%', isProfit ? Colors.green : Colors.red),
            _buildStatItem('累计收益', _formatPriceFourDecimals(profit), isProfit ? Colors.green : Colors.red),
          ],
        ),
        const SizedBox(height: 3),
        _buildStatItem('当前价格', _formatPrice(_currentPrice!), Colors.blue),
      ],
    );
  }
}
