/// 与后端 apicode 包保持一致：业务码 code 与 HTTP 状态一一对应。
abstract final class ApiCode {
  static const int ok = 0;
  static const int fail = 1;
  static const int unauthorized = 401;
  static const int forbidden = 403;
  static const int notFound = 404;
  static const int ycdExpired = 2202;
  static const int serverError = 500;

  /// 静默 Toast 的业务码（页面自行展示）
  static const int silent = 8;
}

enum ApiCategory {
  success,
  businessFail,
  unauthorized,
  forbidden,
  ycdExpired,
  serverError,
}

abstract final class ApiCodePolicy {
  static ApiCategory categoryOf(int code) {
    switch (code) {
      case ApiCode.ok:
        return ApiCategory.success;
      case ApiCode.unauthorized:
        return ApiCategory.unauthorized;
      case ApiCode.forbidden:
        return ApiCategory.forbidden;
      case ApiCode.ycdExpired:
        return ApiCategory.ycdExpired;
      case ApiCode.serverError:
        return ApiCategory.serverError;
      default:
        return ApiCategory.businessFail;
    }
  }

  static bool isSuccess(int code) => code == ApiCode.ok;

  static bool isGlobal(int code) {
    switch (code) {
      case ApiCode.unauthorized:
      case ApiCode.forbidden:
      case ApiCode.ycdExpired:
        return true;
      default:
        return false;
    }
  }
}
