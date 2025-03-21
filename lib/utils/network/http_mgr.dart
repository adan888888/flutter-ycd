import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';

import '../../model/base_model.dart';
import '../../model/user_model.dart';
import '../local_util.dart';
import 'get_store.dart';
import 'network.dart';

///获取请求头
Future<Map<String, String>?> getAppHeader() async {
  Map<String, String> map = {};
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
  };
  return map;
}

///登录失效处理

enum HttpMethod {
  get,
  put,
  delete,
  post,
}

void loginout() {}

BXGet<T>(String api,
    {Map<String, dynamic>? params,
    required Function(bool isSuccess, int code, String message, List<T> results) success,
    Function(String, BaseModel)? failed,
    onModel,
    bool isShowLoading = true,
    bool canCache = true,
    bool showError = true}) {
  Network.getInstance()
      .get<T>(api, success: success, failed: failed, isShowLoading: isShowLoading, showError: showError, params: params, onModel: onModel, canCache: canCache);
}

BXPost<T>(String api,
    {Map<String, dynamic>? params,
    required Function(bool isSuccess, int code, String message, List<T> results) success,
    Function(String, BaseModel)? failed,
    onModel,
    bool isShowLoading = true,
    bool canCache = true,
    bool showError = true}) {
  Network.getInstance()
      .post<T>(api, success: success, failed: failed, isShowLoading: isShowLoading, showError: showError, params: params, onModel: onModel, canCache: canCache);
}

BXDelete<T>(String api,
    {Map<String, dynamic>? params,
    required Function(bool isSuccess, int code, String message, List<T> results) success,
    Function(String, BaseModel)? failed,
    onModel,
    bool isShowLoading = true,
    bool canCache = true,
    bool showError = true}) {
  Network.getInstance().delete<T>(api,
      success: success,
      failed: failed,
      isShowLoading: isShowLoading,
      showError: showError,
      params: params,
      onModel: onModel,
      canCache: canCache);
}

BXPut<T>(String api,
    {Map<String, dynamic>? params,
    required Function(bool isSuccess, int code, String message, List<T> results) success,
    Function(String, BaseModel)? failed,
    onModel,
    bool isShowLoading = true,
    bool canCache = true,
    bool showError = true}) {
  Network.getInstance().put<T>(api,
      success: success,
      failed: failed,
      isShowLoading: isShowLoading,
      showError: showError,
      params: params,
      onModel: onModel,
      canCache: canCache);
}
