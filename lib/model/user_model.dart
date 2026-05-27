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
  String role = "";
  UserModel();

  /// 是否超级管理员
  bool get isSuperAdmin {
    if (role == 'super_admin') return true;
    return isPermanent;
  }

  /// 是否可使用 ycd：优先按到期时间判断（与后端一致），登录后会写入 expires_at
  bool get canUseYcd {
    if (isPermanent || role == 'super_admin') return true;
    if (_isExpiresActive(expiresAt)) return true;
    return ycdAllowed;
  }

  static bool _isExpiresActive(String raw) {
    final s = raw.trim();
    if (s.isEmpty || s == '永久') return false;
    final dt = DateTime.tryParse(s.replaceFirst(' ', 'T')) ?? DateTime.tryParse(s);
    if (dt == null) return false;
    return !DateTime.now().isAfter(dt);
  }

  /// 到期日 yyyy-MM-dd，无有效时间返回空
  String get expiresAtYmd {
    final s = expiresAt.trim();
    if (s.isEmpty || s == '永久') return '';
    final dt = DateTime.tryParse(s.replaceFirst(' ', 'T')) ?? DateTime.tryParse(s);
    if (dt != null) {
      final m = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      return '${dt.year}-$m-$d';
    }
    final match = RegExp(r'(\d{4}-\d{2}-\d{2})').firstMatch(s);
    return match?.group(1) ?? '';
  }

  /// ycd 不可用时的提示文案
  String get ycdExpiredMessage {
    final ymd = expiresAtYmd;
    if (ymd.isEmpty) return '服务未开通，请联系管理员';
    return '服务已到期（$ymd）\n请联系管理员';
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
    role = map["role"]?.toString() ?? "";
    if (role.isEmpty && map["is_super_admin"] == true) {
      role = 'super_admin';
    }
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
        "role": role,
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
