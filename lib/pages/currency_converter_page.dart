import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// 汇率换算页面
class CurrencyConverterPage extends StatefulWidget {
  const CurrencyConverterPage({super.key});

  @override
  State<CurrencyConverterPage> createState() => _CurrencyConverterPageState();
}

class _CurrencyConverterPageState extends State<CurrencyConverterPage> {
  final TextEditingController _amountController = TextEditingController();
  String _fromCurrency = 'USD';
  String _toCurrency = 'CNY';
  double _convertedAmount = 0.0;
  double _exchangeRate = 0.0;
  bool _isLoading = false;
  String? _errorMessage;

  // 支持的货币列表
  final List<Map<String, dynamic>> _currencies = [
    {'code': 'USD', 'name': '美元', 'symbol': '\$', 'flag': '🇺🇸'},
    {'code': 'CNY', 'name': '人民币', 'symbol': '¥', 'flag': '🇨🇳'},
    {'code': 'EUR', 'name': '欧元', 'symbol': '€', 'flag': '🇪🇺'},
    {'code': 'GBP', 'name': '英镑', 'symbol': '£', 'flag': '🇬🇧'},
    {'code': 'JPY', 'name': '日元', 'symbol': '¥', 'flag': '🇯🇵'},
    {'code': 'KRW', 'name': '韩元', 'symbol': '₩', 'flag': '🇰🇷'},
    {'code': 'HKD', 'name': '港币', 'symbol': 'HK\$', 'flag': '🇭🇰'},
    {'code': 'SGD', 'name': '新加坡元', 'symbol': 'S\$', 'flag': '🇸🇬'},
    {'code': 'AUD', 'name': '澳元', 'symbol': 'A\$', 'flag': '🇦🇺'},
    {'code': 'CAD', 'name': '加元', 'symbol': 'C\$', 'flag': '🇨🇦'},
    {'code': 'VND', 'name': '越南盾', 'symbol': '₫', 'flag': '🇻🇳'},
  ];

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    if (_amountController.text.isNotEmpty) {
      _convertCurrency();
    } else {
      setState(() {
        _convertedAmount = 0.0;
        _exchangeRate = 0.0;
      });
    }
  }

  // 获取汇率
  Future<void> _convertCurrency() async {
    if (_amountController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final amount = double.parse(_amountController.text);
      final response = await http.get(
        Uri.parse('https://api.exchangerate-api.com/v4/latest/$_fromCurrency'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;

        if (rates.containsKey(_toCurrency)) {
          final rate = rates[_toCurrency] as double;
          final converted = amount * rate;

          setState(() {
            _exchangeRate = rate;
            _convertedAmount = converted;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = '不支持的货币代码: $_toCurrency';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = '获取汇率失败，请稍后重试';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '网络错误: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // 交换货币
  void _swapCurrencies() {
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
    });
    _convertCurrency();
  }

  // 获取货币信息
  Map<String, dynamic> _getCurrencyInfo(String code) {
    return _currencies.firstWhere((currency) => currency['code'] == code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('汇率换算'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // 输入金额
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('输入金额', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '请输入要换算的金额',
                        prefixText: '${_getCurrencyInfo(_fromCurrency)['symbol']} ',
                        prefixStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // 货币选择
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    // 从货币
                    _buildCurrencySelector(
                      '从',
                      _fromCurrency,
                      (currency) {
                        setState(() {
                          _fromCurrency = currency;
                        });
                        _convertCurrency();
                      },
                    ),

                    const SizedBox(height: 8),

                    // 交换按钮
                    Center(
                      child: IconButton(
                        onPressed: _swapCurrencies,
                        icon: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.swap_vert, color: Colors.blue, size: 18),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // 到货币
                    _buildCurrencySelector(
                      '到',
                      _toCurrency,
                      (currency) {
                        setState(() {
                          _toCurrency = currency;
                        });
                        _convertCurrency();
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // 换算结果
            if (_amountController.text.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      const Text('换算结果', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (_isLoading)
                        const CircularProgressIndicator()
                      else if (_errorMessage != null)
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        )
                      else ...[
                        // 换算金额
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${_getCurrencyInfo(_toCurrency)['symbol']}${_convertedAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_getCurrencyInfo(_toCurrency)['name']} ($_toCurrency)',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        // 汇率信息
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('1 $_fromCurrency ='),
                              Text(
                                '${_exchangeRate.toStringAsFixed(4)} $_toCurrency',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],

            const Spacer(),

            // 说明信息
            Card(
              color: Colors.blue.withValues(alpha: 0.05),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '汇率数据来源于 exchangerate-api.com，仅供参考',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencySelector(String label, String selectedCurrency, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedCurrency,
              isExpanded: true,
              items: _currencies.map((currency) {
                return DropdownMenuItem<String>(
                  value: currency['code'],
                  child: Row(
                    children: [
                      Text(currency['flag'], style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(currency['name']),
                      const SizedBox(width: 4),
                      Text('(${currency['code']})', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  onChanged(value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
