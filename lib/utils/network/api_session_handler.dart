import 'package:get/get.dart';

import '../../model/base_model.dart';
import '../../routes/app_routes.dart';
import '../bx_loading.dart';
import 'api_code.dart';
import 'get_store.dart';

/// 全局业务码副作用：Toast + 清 session + 路由跳转。
abstract final class ApiSessionHandler {
  static void handleGlobal(int code, String msg, {required bool showError}) {
    switch (ApiCodePolicy.categoryOf(code)) {
      case ApiCategory.unauthorized:
        _onUnauthorized(msg, showError);
      case ApiCategory.forbidden:
        _onForbidden(msg);
      case ApiCategory.ycdExpired:
        _onYcdExpired(msg, showError);
      default:
        break;
    }
  }

  static void _onUnauthorized(String msg, bool showError) {
    GetStore.getInstance().cleanUser();
    if (showError && msg.isNotEmpty) BXLoading.showToast(msg);
    Future.delayed(const Duration(seconds: 1), () {
      if (Get.currentRoute != AppRoutes.login) {
        Get.offAndToNamed(AppRoutes.login);
      }
    });
  }

  static void _onForbidden(String msg) {
    if (msg.isNotEmpty) BXLoading.showError(toast: msg);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (Get.currentRoute != AppRoutes.home) {
        Get.offAllNamed(AppRoutes.home);
      }
    });
  }

  static void _onYcdExpired(String msg, bool showError) {
    GetStore.getInstance().cleanUser();
    if (showError && msg.isNotEmpty) BXLoading.showToast(msg);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (Get.currentRoute != AppRoutes.login) {
        Get.offAllNamed(AppRoutes.login);
      }
    });
  }

  static void handleBusinessFail(
    BaseModel model, {
    required bool showError,
    Function(String, BaseModel)? failed,
  }) {
    if (model.code == ApiCode.fail) {
      if (showError && model.msg.isNotEmpty) BXLoading.showToast(model.msg);
      return;
    }
    if (failed != null) failed(model.msg, model);
    if (model.code != ApiCode.silent && showError && model.msg.isNotEmpty) {
      BXLoading.showToast(model.msg);
    }
  }
}
