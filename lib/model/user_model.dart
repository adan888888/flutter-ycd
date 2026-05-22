import '../utils/types_of.dart';

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
  bool ycdAllowed = false;
  bool isPermanent = false;
  String expiresAt = "";
  String expiresAtDisplay = "";
  UserModel();

  /// 是否可使用 ycd：优先按到期时间判断（与后端一致），登录后会写入 expires_at
  bool get canUseYcd {
    if (isPermanent || nickname == 'Admin') return true;
    if (_isExpiresActive(expiresAtDisplay)) return true;
    if (_isExpiresActive(expiresAt)) return true;
    return ycdAllowed;
  }

  static bool _isExpiresActive(String raw) {
    final s = raw.trim();
    if (s.isEmpty || s == '未设置' || s == '永久') return false;
    final dt = DateTime.tryParse(s.replaceFirst(' ', 'T')) ?? DateTime.tryParse(s);
    if (dt == null) return false;
    return !DateTime.now().isAfter(dt);
  }

  UserModel.fromJson(Map<String, dynamic> map) {
    userId = map["userId"]?.toString() ?? "";
    token = map["token"] ?? "";
    refreshToken = map["refresh_token"] ?? "";
    account = map["account"] ?? "";
    email = map["email"] ?? "";
    phone = map["phone"] ?? "";
    status = bxGetInt(map["status"]);
    nickname = map["nickname"] ?? "";
    avatar = map["avatar"] ?? "";
    statusDesc = map["status_desc"] ?? "";
    levelId = bxGetInt(map["levelId"]);
    ycdAllowed = map["ycd_allowed"] == true;
    isPermanent = map["is_permanent"] == true;
    expiresAt = map["expires_at"]?.toString() ?? "";
    expiresAtDisplay = map["expires_at_display"]?.toString() ?? expiresAt;
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
        "ycd_allowed": ycdAllowed,
        "is_permanent": isPermanent,
        "expires_at": expiresAt,
        "expires_at_display": expiresAtDisplay,
      };
}

class SystemAvatarModel {
  int id = 0;
  String avatar = "";
  String avatarUrl = "";

  SystemAvatarModel();

  SystemAvatarModel.fromJson(Map<String, dynamic> map) {
    id = bxGetInt(map["id"]);
    avatar = bxGetString(map["avatar"]);
    avatarUrl = bxGetString(map["avatarUrl"]);
  }
}
