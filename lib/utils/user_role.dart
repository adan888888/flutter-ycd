/// 用户角色常量，与后端 models/role.go 保持一致
abstract final class UserRole {
  static const superAdmin = 'super_admin';
  static const pro = 'pro';
  static const user = 'user';

  static String normalize(String? role) {
    switch (role) {
      case superAdmin:
        return superAdmin;
      case pro:
        return pro;
      default:
        return user;
    }
  }

  static bool isSuperAdmin(String? role) => normalize(role) == superAdmin;

  static bool isPro(String? role) => normalize(role) == pro;

  /// 专业版及以上（含超级管理员）
  static bool isProOrAbove(String? role) {
    final r = normalize(role);
    return r == superAdmin || r == pro;
  }

  static String label(String? role) {
    switch (normalize(role)) {
      case superAdmin:
        return '超级管理员';
      case pro:
        return '专业用户';
      default:
        return '普通用户';
    }
  }
}
