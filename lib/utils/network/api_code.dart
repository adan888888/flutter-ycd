/// 与后端 apicode 包保持一致；HTTP 固定 200，只看 body 里的 code。
abstract final class ApiCode {
  static const int ok = 0;
  static const int paramInvalid = 1000;
  static const int loginInvalid = 1001;
  static const int verifyCodeExpired = 1002;
  static const int jsqExpired = 1003;
  static const int notFound = 1004;
  static const int unauthorized = 1005;
  static const int forbidden = 1006;
  static const int serverError = 1007;

  /// 静默 Toast 的业务码（页面自行展示）
  static const int silent = 8;
}

abstract final class ApiCodePolicy {
  static bool isSuccess(int code) => code == ApiCode.ok;

  static bool isGlobal(int code) {
    switch (code) {
      case ApiCode.unauthorized:
      case ApiCode.forbidden:
      case ApiCode.jsqExpired:
        return true;
      default:
        return false;
    }
  }

  /// 是否由 HttpService 自动 Toast（auth 接口、全局码、静默码除外）
  static bool shouldAutoToast(int code, {required bool isAuthApi}) {
    if (code == ApiCode.silent) return false;
    if (isGlobal(code)) return false;
    if (isAuthApi) return false;
    return true;
  }
}
