import 'package:flutter/material.dart';
import 'package:get/get.dart';

class InvestmentCalculatorController extends GetxController {
  // 表单控制器
  final TextEditingController initialAmountController = TextEditingController();
  final TextEditingController monthlyController = TextEditingController();
  final TextEditingController yearsController = TextEditingController();
  final TextEditingController interestRateController = TextEditingController();

  // 状态变量
  final RxDouble totalAmount = 0.0.obs;
  final RxDouble totalPrincipal = 0.0.obs;
  final RxDouble totalInterest = 0.0.obs;
  final RxString calculationMethod = 'compound'.obs; // compound or simple

  @override
  void onClose() {
    initialAmountController.dispose();
    monthlyController.dispose();
    yearsController.dispose();
    interestRateController.dispose();
    super.onClose();
  }

  // 计算投资收益
  void calculateInvestment() {
    try {
      final initialAmount = double.parse(initialAmountController.text.isEmpty ? '0' : initialAmountController.text);
      final monthlyInvestment = double.parse(monthlyController.text.isEmpty ? '0' : monthlyController.text);
      final years = double.parse(yearsController.text.isEmpty ? '0' : yearsController.text);
      final annualRate = double.parse(interestRateController.text.isEmpty ? '0' : interestRateController.text) / 100;

      if (calculationMethod.value == 'compound') {
        _calculateCompoundInterest(initialAmount, monthlyInvestment, years, annualRate);
      } else {
        _calculateSimpleInterest(initialAmount, monthlyInvestment, years, annualRate);
      }
    } catch (e) {
      // 重置结果
      totalAmount.value = 0.0;
      totalPrincipal.value = 0.0;
      totalInterest.value = 0.0;
    }
  }

  // 复利计算
  void _calculateCompoundInterest(double initial, double monthly, double years, double rate) {
    final monthlyRate = rate / 12;
    final months = years * 12;

    // 初始投资的复利
    final initialFutureValue = initial * _pow(1 + monthlyRate, months);

    // 每月投资的复利 (年金现值公式)
    double monthlyFutureValue = 0;
    if (monthlyRate > 0) {
      monthlyFutureValue = monthly * ((_pow(1 + monthlyRate, months) - 1) / monthlyRate);
    } else {
      monthlyFutureValue = monthly * months;
    }

    totalAmount.value = initialFutureValue + monthlyFutureValue;
    totalPrincipal.value = initial + (monthly * months);
    totalInterest.value = totalAmount.value - totalPrincipal.value;
  }

  // 简单利息计算
  void _calculateSimpleInterest(double initial, double monthly, double years, double rate) {
    final totalPrincipalAmount = initial + (monthly * years * 12);
    final simpleInterest = totalPrincipalAmount * rate * years;

    totalPrincipal.value = totalPrincipalAmount;
    totalInterest.value = simpleInterest;
    totalAmount.value = totalPrincipal.value + totalInterest.value;
  }

  // 幂运算辅助函数
  double _pow(double base, double exponent) {
    if (exponent == 0) return 1;
    if (exponent == 1) return base;

    double result = 1;
    for (int i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }

  // 清空输入
  void clearAll() {
    initialAmountController.clear();
    monthlyController.clear();
    yearsController.clear();
    interestRateController.clear();
    totalAmount.value = 0.0;
    totalPrincipal.value = 0.0;
    totalInterest.value = 0.0;
  }

  // 格式化货币显示
  String formatCurrency(double amount) {
    return amount.toStringAsFixed(2);
  }

  // 计算翻倍数
  double getMultiplier() {
    if (totalPrincipal.value == 0) return 0.0;
    return totalAmount.value / totalPrincipal.value;
  }

  // 数字转中文（修复版，去掉小数点）
  String numberToChinese(double number) {
    if (number == 0) return "零";

    final intPart = number.toInt();
    return _intToChinese(intPart);
  }

  // 整数转中文（修复版）
  String _intToChinese(int number) {
    if (number == 0) return "零";

    final digits = ["零", "一", "二", "三", "四", "五", "六", "七", "八", "九"];
    final units = ["", "十", "百", "千"];
    final bigUnits = ["", "万", "亿"];

    if (number < 10) return digits[number];

    String result = "";
    int num = number;
    int unitIndex = 0;

    while (num > 0) {
      String segment = "";
      int tempNum = num % 10000; // 处理万位以下的数字

      if (tempNum > 0) {
        int subUnitIndex = 0;
        while (tempNum > 0) {
          int digit = tempNum % 10;
          if (digit != 0) {
            segment = digits[digit] + units[subUnitIndex] + segment;
          } else if (segment.isNotEmpty && !segment.startsWith("零")) {
            segment = "零$segment";
          }
          tempNum ~/= 10;
          subUnitIndex++;
        }

        // 处理特殊情况
        if (segment.startsWith("零") && segment.length > 1) {
          segment = segment.substring(1);
        }
        if (segment.endsWith("零") && segment.length > 1) {
          segment = segment.substring(0, segment.length - 1);
        }

        result = segment + bigUnits[unitIndex] + result;
      }

      num ~/= 10000;
      unitIndex++;
    }

    // 最终清理
    result = result.replaceAll("零零", "零");
    result = result.replaceAll("零万", "万");
    result = result.replaceAll("零亿", "亿");
    if (result.endsWith("零")) {
      result = result.substring(0, result.length - 1);
    }
    if (result.startsWith("一十")) {
      result = result.substring(1);
    }

    return result;
  }

  // 格式化金额显示（带中文）
  String formatCurrencyWithChinese(double amount) {
    final formatted = formatCurrency(amount);
    final chinese = numberToChinese(amount);
    return '$formatted($chinese)';
  }
}
