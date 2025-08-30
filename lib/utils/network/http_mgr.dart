import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';
import '../../model/base_model.dart';
import '../../model/user_model.dart';
import '../local_util.dart';
import 'get_store.dart';
import 'http_service.dart';

///获取请求头
Future<Map<String, String>?> getAppHeader() async {
  Map<String, String> map = {};
  GetStore.getInstance().checkLoginStatus();
  bool isLogin = GetStore.getInstance().isLogin;
  String token = '';
  String xUserId = '';
  if (isLogin) {
    UserModel userModel = await GetStore.getInstance().userModel;
    token = userModel.token ?? "";
    xUserId = userModel.userId.toString();
  }
  String deviceid = await GetStore.getInstance().getDeviceId();
  PackageInfo info = await PackageInfo.fromPlatform();
  String os = '';
  String xDeviceType = '';
  String lan = LocalUtil.getLoaclString();
  if (Platform.isIOS) {
    os = "IOS";
    xDeviceType = "3";
  } else {
    os = "ANDROID";
    xDeviceType = "2";
  }

  map = {
    "Content-type": "application/json;charset=UTF-8",
    "X-Device-Type": xDeviceType,
    // "X-Tenant-Id": Environment().currentConfig.tenantId,
    "X-Device-Id": deviceid,
    "X-Lang": lan,
    // A代表SAAS平台总控端 B代表SAAS平台商户管理端 C代表SAAS平台商户客户端
    "X-Platform-Id": "C",
    //App终端标识 IOS|ANDROID|HARMONYOS|WINDOWS 与X-Web-Terminal-Id二选一
    "X-App-Terminal-Id": os,
    "Authorization": "Bearer $token",
    "UserId": xUserId,
  };
  return map;
}

///登录失效处理
void loginout() {}

// 使用新的Dio服务
BXGet<T>(String api,
    {Map<String, dynamic>? params,
    required Function(bool isSuccess, int code, String message, List<T> results) success,
    Function(String, BaseModel)? failed,
    onModel,
    bool isShowLoading = true,
    bool canCache = true,
    bool showError = true}) {
  HttpService.getInstance().get<T>(
    api,
    params: params,
    success: success,
    failed: failed,
    onModel: onModel,
    isShowLoading: isShowLoading,
    showError: showError,
  );
}

BXPost<T>(String api,
    {Map<String, dynamic>? params,
    required Function(bool isSuccess, int code, String message, List<T> results) success,
    Function(String, BaseModel)? failed,
    onModel,
    bool isShowLoading = true,
    bool canCache = true,
    bool showError = true}) {
  HttpService.getInstance().post<T>(
    api,
    params: params,
    success: success,
    failed: failed,
    onModel: onModel,
    isShowLoading: isShowLoading,
    showError: showError,
  );
}

BXDelete<T>(String api,
    {Map<String, dynamic>? params,
    required Function(bool isSuccess, int code, String message, List<T> results) success,
    Function(String, BaseModel)? failed,
    onModel,
    bool isShowLoading = true,
    bool canCache = true,
    bool showError = true}) {
  HttpService.getInstance().delete<T>(
    api,
    params: params,
    success: success,
    failed: failed,
    onModel: onModel,
    isShowLoading: isShowLoading,
    showError: showError,
  );
}

BXPut<T>(String api,
    {Map<String, dynamic>? params,
    required Function(bool isSuccess, int code, String message, List<T> results) success,
    Function(String, BaseModel)? failed,
    onModel,
    bool isShowLoading = true,
    bool canCache = true,
    bool showError = true}) {
  HttpService.getInstance().put<T>(
    api,
    params: params,
    success: success,
    failed: failed,
    onModel: onModel,
    isShowLoading: isShowLoading,
    showError: showError,
  );
}
