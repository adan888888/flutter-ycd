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

class Table2Model {
  int? id;
  int? seq; // 每个用户自己的序号（后端计算的行号）
  double? xiazhujine; // 下注金额
  double? shuyingzhi; // 输赢值
  double? shuyingzhiXiaoshu; // 消数列
  String? shengfulu;
  String? zx;
  String? restartStatSnapshot; // 重启统计快照（2/6/14/18，其中 18 保留 1 位小数）
  String? remark; // 输赢标记
  double? currentJin;

  Table2Model({
    required this.id,
    this.seq,
    this.xiazhujine,
    this.shuyingzhi,
    this.shuyingzhiXiaoshu,
    this.shengfulu,
    this.zx,
    this.remark,
    this.currentJin,
    this.restartStatSnapshot,
  });

  Table2Model.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    seq = json['seq'];
    xiazhujine = _parseAmount(json['xiazhujine']);
    shuyingzhi = _parseAmount(json['shuyingzhi']);
    shuyingzhiXiaoshu = _parseAmount(json['shuyingzhi_xiaoshu']);
    shengfulu = json['shengfulu'];
    zx = json['zx'];
    remark = json['remark'];
    currentJin = _parseAmount(json['current_jin']);
    restartStatSnapshot = json['restartStatSnapshot'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['seq'] = seq;
    data['xiazhujine'] = _amountToJson(xiazhujine);
    data['shuyingzhi'] = _amountToJson(shuyingzhi);
    data['shuyingzhi_xiaoshu'] = _amountToJson(shuyingzhiXiaoshu);
    data['shengfulu'] = shengfulu;
    data['zx'] = zx;
    data['remark'] = remark;
    data['current_jin'] = _amountToJson(currentJin);
    data['restartStatSnapshot'] = restartStatSnapshot;
    return data;
  }
}
