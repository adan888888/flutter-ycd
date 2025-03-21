

class BaseModel {
  int code = 0;
  String msg = "";
  dynamic data;
  BaseModel.fromJson(Map<String,dynamic> map){
    code = map["code"]?.toInt();
    msg = map["msg"] ?? "";
    data = (map["data"] is Map) ? [map["data"]] : (map["data"] is List ? map["data"] : map["data"]);
  }
}