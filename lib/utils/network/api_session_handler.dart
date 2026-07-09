import 'package:get/get.dart';

import '../../model/base_model.dart';
import '../../routes/app_routes.dart';
import '../bx_loading.dart';
import 'api_code.dart';
import 'get_store.dart';

/// 全局业务码副作用：Toast + 清 session + 路由跳转。
abstract final class ApiSessionHandler {
  /// 统一跳转登录：先关 Loading，避免 token 过期后遮罩残留。
  static void goLogin({bool clearStack = true}) {
    BXLoading.reset();
    if (Get.currentRoute == AppRoutes.login) return;
    if (clearStack) {
      Get.offAllNamed(AppRoutes.login);
    } else {
      Get.offAndToNamed(AppRoutes.login);
    }
  }

  static void handleGlobal(int code, String msg, {required bool showError, bool isAuthApi = false}) {
    switch (code) {
      case ApiCode.jsqExpired:
        _onJsqExpired(msg, showError, isAuthApi: isAuthApi);
      case ApiCode.unauthorized:
        _onUnauthorized(msg, showError);
      case ApiCode.forbidden:
        _onForbidden(msg);
      default:
        break;
    }
  }

  static void _onUnauthorized(String msg, bool showError) {
    GetStore.getInstance().cleanUser();
    BXLoading.reset();
    if (showError && msg.isNotEmpty) BXLoading.showToast(msg);
    Future.delayed(const Duration(seconds: 1), () => goLogin(clearStack: false));
  }

  static void _onForbidden(String msg) {
    BXLoading.reset();
    if (msg.isNotEmpty) BXLoading.showError(toast: msg);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (Get.currentRoute != AppRoutes.home) {
        Get.offAllNamed(AppRoutes.home);
      }
    });
  }

  static void _onJsqExpired(String msg, bool showError, {bool isAuthApi = false}) {
    if (!isAuthApi) {
      GetStore.getInstance().cleanUser();
    }
    BXLoading.reset();
    if (showError && msg.isNotEmpty) BXLoading.showToast(msg);
    if (isAuthApi) return;
    Future.delayed(const Duration(milliseconds: 500), () => goLogin(clearStack: true));
  }

  static void handleBusinessFail(
    BaseModel model, {
    required bool showError,
    Function(String, BaseModel)? failed,
    bool autoToast = true,
  }) {
    if (failed != null) failed(model.msg, model);
    if (autoToast &&
        model.code != ApiCode.silent &&
        showError &&
        model.msg.isNotEmpty) {
      BXLoading.showToast(model.msg);
    }
  }
}
