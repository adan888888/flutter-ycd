import 'package:ycd/utils/types_of.dart';

class Table1Model {
  int? id;
  String? columnBenjin;
  String? columnYongJin; //赔率
  String? columnMean;
  String? columnRestartIndex;
  String? columnLiushuiIndex;

  Table1Model({this.id, this.columnBenjin, this.columnYongJin, this.columnMean, this.columnRestartIndex, this.columnLiushuiIndex});

  Table1Model.fromJson(Map<String, dynamic> json) {
    id = bxGetInt(json['id']);
    columnBenjin = bxGetString(json['column_benjin']);
    columnYongJin = bxGetString(json['column_yongJin']);
    columnMean = bxGetString(json['column_mean']);
    columnRestartIndex = bxGetString(json['column_restart_index']);
    columnLiushuiIndex = bxGetString(json['column_liushui_index']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['ID'] = id;
    data['column_benjin'] = columnBenjin;
    data['column_yongJin'] = columnYongJin;
    data['column_mean'] = columnMean;
    data['column_restart_index'] = columnRestartIndex;
    data['column_liushui_index'] = columnLiushuiIndex;
    return data;
  }
}
