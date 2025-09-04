import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/services.dart';
import 'dart:math';

// 复利投资计算器页面
class InvestmentCalculatorPage extends StatefulWidget {
  const InvestmentCalculatorPage({super.key});

  @override
  State<InvestmentCalculatorPage> createState() => _InvestmentCalculatorPageState();
}

class _InvestmentCalculatorPageState extends State<InvestmentCalculatorPage> {
  final TextEditingController _weeklyInvestmentController = TextEditingController(text: '1000');
  final TextEditingController _monthlyInvestmentController = TextEditingController();
  final TextEditingController _annualReturnController = TextEditingController(text: '30');
  final TextEditingController _yearsController = TextEditingController(text: '10');

  Map<String, dynamic>? _calculationResult;

  void _calculateInvestment() {
    final weeklyInvestment = double.tryParse(_weeklyInvestmentController.text) ?? 0;
    final monthlyInvestment = double.tryParse(_monthlyInvestmentController.text) ?? 0;
    final annualReturn = double.tryParse(_annualReturnController.text) ?? 0;
    final years = double.tryParse(_yearsController.text) ?? 0;

    if (weeklyInvestment <= 0 && monthlyInvestment <= 0) {
      Fluttertoast.showToast(msg: "请输入投资金额", toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.CENTER);
      return;
    }

    if (annualReturn <= 0 || years <= 0) {
      Fluttertoast.showToast(msg: "请输入有效的收益率和年限", toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.CENTER);
      return;
    }

    // 判断投资方式
    bool isWeekly = weeklyInvestment > 0;
    bool isMonthly = monthlyInvestment > 0;

    if (isWeekly && isMonthly) {
      Fluttertoast.showToast(msg: "请只选择一种投资方式", toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.CENTER);
      return;
    }

    double investmentAmount = isWeekly ? weeklyInvestment : monthlyInvestment;
    int totalPeriods = isWeekly ? (years * 52).round() : (years * 12).round();
    double periodReturn = isWeekly ? (pow(1 + annualReturn / 100, 1 / 52) - 1) : (pow(1 + annualReturn / 100, 1 / 12) - 1);

    // 计算未来价值
    double futureValue = investmentAmount * (pow(1 + periodReturn, totalPeriods) - 1) / periodReturn;

    // 计算总投资额
    double totalInvested = investmentAmount * totalPeriods;

    // 计算总收益
    double totalProfit = futureValue - totalInvested;

    // 计算收益倍数
    double profitMultiple = futureValue / totalInvested;

    setState(() {
      _calculationResult = {
        'totalInvested': totalInvested,
        'totalProfit': totalProfit,
        'futureValue': futureValue,
        'profitMultiple': profitMultiple,
        'totalPeriods': totalPeriods,
        'periodReturn': periodReturn,
        'investmentType': isWeekly ? '周' : '月',
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('复利投资计算器'), backgroundColor: Theme.of(context).colorScheme.inversePrimary),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 输入表单
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('投资参数', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _weeklyInvestmentController,
                        decoration: const InputDecoration(labelText: '每周投资金额 (美元)', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _monthlyInvestmentController,
                        decoration: const InputDecoration(labelText: '每月投资金额 (美元)', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _annualReturnController,
                        decoration: const InputDecoration(labelText: '年收益率 (%)', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _yearsController,
                        decoration: const InputDecoration(labelText: '投资年限 (年)', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _calculateInvestment, child: const Text('计算投资结果'))),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 投资计算结果
              if (_calculationResult != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('计算结果', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        _buildResultRow('总投资额', '\$${_formatToWan(_calculationResult!['totalInvested'])}'),
                        _buildResultRow('总收益', '\$${_formatToWan(_calculationResult!['totalProfit'])}'),
                        _buildResultRow('本金+收益', '\$${_formatToWan(_calculationResult!['futureValue'])}'),
                        _buildResultRow('收益倍数', '${_calculationResult!['profitMultiple'].toStringAsFixed(2)}倍'),
                        _buildResultRow('总${_calculationResult!['investmentType']}数', '${_calculationResult!['totalPeriods']}${_calculationResult!['investmentType']}'),
                        _buildResultRow('${_calculationResult!['investmentType']}收益率', '${(_calculationResult!['periodReturn'] * 100).toStringAsFixed(4)}%'),
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

  // 格式化数字为万为单位
  String _formatToWan(double number) {
    if (number >= 10000) {
      return '${(number / 10000).toStringAsFixed(2)}万';
    } else {
      return number.toStringAsFixed(2);
    }
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          GestureDetector(
            onTap: () {
              // 处理万单位的转换
              String cleanValue;
              if (value.contains('万')) {
                // 提取数字部分
                String numberPart = value.replaceAll(RegExp(r'[^\d.]'), '');
                double number = double.tryParse(numberPart) ?? 0;
                // 转换为实际数字（万 × 10000）
                cleanValue = (number * 10000).toString();
                // 如果是整数，去掉小数点
                if (cleanValue.endsWith('.0')) {
                  cleanValue = cleanValue.replaceAll('.0', '');
                }
              } else {
                // 其他情况直接提取数字
                cleanValue = value.replaceAll(RegExp(r'[^\d.]'), '');
              }
              Clipboard.setData(ClipboardData(text: cleanValue));
              Fluttertoast.showToast(msg: "已复制: $cleanValue", toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.CENTER);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
                const SizedBox(width: 4),
                const Icon(Icons.copy, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _weeklyInvestmentController.dispose();
    _monthlyInvestmentController.dispose();
    _annualReturnController.dispose();
    _yearsController.dispose();
    super.dispose();
  }
}
