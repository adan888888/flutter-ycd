class Table2Model {
  int? id;
  String? columnXiazhujine; //下注金额
  String? colmunShuyingzhi; //输赢值
  String? colmunShuyingzhiD; //输赢值(消数列的)
  String? colmunShengfulu;
  String? colmunZx;
  String? colmunRemark; //输赢标记
  String? columnCurrentJin;

  Table2Model({
    required this.id,
    this.columnXiazhujine,
    this.colmunShuyingzhi,
    this.colmunShuyingzhiD,
    this.colmunShengfulu,
    this.colmunZx,
    this.colmunRemark,
    this.columnCurrentJin,
  });

  Table2Model.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    columnXiazhujine = json['column_xiazhujine'];
    colmunShuyingzhi = json['colmun_shuyingzhi'];
    colmunShuyingzhiD = json['colmun_shuyingzhi_d'];
    colmunShengfulu = json['colmun_shengfulu'];
    colmunZx = json['colmun_zx'];
    colmunRemark = json['colmun_remark'];
    columnCurrentJin = json['column_current_jin'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['column_xiazhujine'] = this.columnXiazhujine;
    data['colmun_shuyingzhi'] = this.colmunShuyingzhi;
    data['colmun_shuyingzhi_d'] = this.colmunShuyingzhiD;
    data['colmun_shengfulu'] = this.colmunShengfulu;
    data['colmun_zx'] = this.colmunZx;
    data['colmun_remark'] = this.colmunRemark;
    data['column_current_jin'] = this.columnCurrentJin;
    return data;
  }
}
