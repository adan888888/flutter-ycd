class BaseModel {
  int code = 0;
  String msg = "";
  dynamic data;

  BaseModel.fromJson(Map<String, dynamic> map) {
    code = map["code"]?.toInt();
    msg = map["msg"] ?? "";
    final raw = map["data"];
    if (raw == null) {
      data = <dynamic>[];
    } else if (raw is Map) {
      data = raw.isEmpty ? <dynamic>[] : <dynamic>[raw];
    } else if (raw is List) {
      data = raw;
    } else {
      data = raw;
    }
  }
}
