class Table2Model {
  int? id;
  int? seq; // 每个用户自己的序号（后端计算的行号）
  String? columnXiazhujine; //下注金额
  String? colmunShuyingzhi; //输赢值
  String? colmunShuyingzhiD; //输赢值(消数列的)
  String? colmunShengfulu;
  String? colmunZx;
  String? restartStatSnapshot; // 重启统计快照（2/6/14/18，其中 18 保留 1 位小数）
  String? colmunRemark; //输赢标记
  String? columnCurrentJin;

  Table2Model({
    required this.id,
    this.seq,
    this.columnXiazhujine,
    this.colmunShuyingzhi,
    this.colmunShuyingzhiD,
    this.colmunShengfulu,
    this.colmunZx,
    this.colmunRemark,
    this.columnCurrentJin,
    this.restartStatSnapshot,
  });

  Table2Model.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    seq = json['seq'];
    columnXiazhujine = json['column_xiazhujine'];
    colmunShuyingzhi = json['colmun_shuyingzhi'];
    colmunShuyingzhiD = json['colmun_shuyingzhi_d'];
    colmunShengfulu = json['colmun_shengfulu'];
    colmunZx = json['colmun_zx'];
    colmunRemark = json['colmun_remark'];
    columnCurrentJin = json['column_current_jin'];
    restartStatSnapshot = json['restartStatSnapshot'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['seq'] = seq;
    data['column_xiazhujine'] = columnXiazhujine;
    data['colmun_shuyingzhi'] = colmunShuyingzhi;
    data['colmun_shuyingzhi_d'] = colmunShuyingzhiD;
    data['colmun_shengfulu'] = colmunShengfulu;
    data['colmun_zx'] = colmunZx;
    data['colmun_remark'] = colmunRemark;
    data['column_current_jin'] = columnCurrentJin;
    data['restartStatSnapshot'] = restartStatSnapshot;
    return data;
  }
}
