import '../utils/types _of.dart';


class UserModel {
  String userId = "";
  String token = "";
  String refreshToken = "";
  String account = "";
  String email = "";
  String phone = "";
  int status = 0;
  String nickname = "";
  String avatar = "";
  String statusDesc = "";
  int levelId = 0;
  UserModel();

  UserModel.fromJson(Map<String, dynamic> map) {
    userId = map["userId"] ?? "";
    token = map["token"] ?? "";
    refreshToken = map["refresh_token"] ?? "";
    account = map["account"] ?? "";
    email = map["email"] ?? "";
    phone = map["phone"] ?? "";
    status = BXGetInt(map["status"]);
    nickname = map["nickname"] ?? "";
    avatar = map["avatar"] ?? "";
    statusDesc = map["status_desc"] ?? "";
    levelId = BXGetInt(map["levelId"]);
  }

  Map<String, dynamic> toJson() => {
    "userId": userId,
    "token": token,
    "refresh_token": refreshToken,
    "account": account,
    "email": email,
    "phone": phone,
    "status": status,
    "nickname": nickname,
    "avatar": avatar,
    "status_desc": statusDesc,
  };
}

class SystemAvatarModel {
  int id = 0;
  String avatar = "";
  String avatarUrl = "";

  SystemAvatarModel();

  SystemAvatarModel.fromJson(Map<String, dynamic> map) {
    id = BXGetInt(map["id"]);
    avatar = BXGetString(map["avatar"]);
    avatarUrl = BXGetString(map["avatarUrl"]);
  }
}
