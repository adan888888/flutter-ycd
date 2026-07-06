import 'package:ycd/utils/types_of.dart';

double? _parseAmount(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  final s = value.toString().trim().replaceFirst('+', '');
  if (s.isEmpty) return null;
  return double.tryParse(s);
}

num? _amountToJson(double? value) {
  if (value == null) return null;
  return value;
}

int? _parseIndex(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString().trim());
}

class Table1Model {
  int? id;
  double? benjin;
  double? initialBet;
  double? yongjin; // 赔率
  double? mean;
  int? restartIndex;
  int? liushuiIndex;
  String? tempIndex; // 存储局部平衡的位置

  Table1Model({
    this.id,
    this.benjin,
    this.initialBet,
    this.yongjin,
    this.mean,
    this.restartIndex,
    this.liushuiIndex,
    this.tempIndex,
  });

  Table1Model.fromJson(Map<String, dynamic> json) {
    id = bxGetInt(json['id']);
    benjin = _parseAmount(json['benjin']);
    initialBet = _parseAmount(json['initial_bet']);
    yongjin = _parseAmount(json['yongjin']);
    mean = _parseAmount(json['mean']);
    restartIndex = _parseIndex(json['restart_index']);
    liushuiIndex = _parseIndex(json['liushui_index']);
    tempIndex = bxGetString(json['temp_index']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['ID'] = id;
    data['benjin'] = _amountToJson(benjin);
    data['initial_bet'] = _amountToJson(initialBet);
    data['yongjin'] = _amountToJson(yongjin);
    data['mean'] = _amountToJson(mean);
    data['restart_index'] = restartIndex;
    data['liushui_index'] = liushuiIndex;
    data['temp_index'] = tempIndex;
    return data;
  }
}
