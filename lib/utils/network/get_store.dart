import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

import '../../model/config_Model.dart';
import '../../model/user_model.dart';
import '../storage_util.dart';

class GetStore {
  // --- 单例模式 ---
  static GetStore? _instance;
  String shareLink = "";

  GetStore._internal();

  static GetStore getInstance() {
    _instance ??= GetStore._internal();
    return _instance!;
  }

  // --- 用户数据缓存与管理 ---
  static UserModel? cacheUserModel;

  // --- 用户数据缓存与管理 ---
  static ConfigModel? cacheConfigModel;

  /// 获取用户信息数据（异步）
  UserModel readUserModel() {
    UserModel userModel = UserModel();
    String? data = StorageUtil.getString("bx_user");
    if (data != null && data.isNotEmpty) {
      userModel = UserModel.fromJson(jsonDecode(data));
    }
    return userModel;
  }

  /// 检查登录状态
  void checkLoginStatus() {
    UserModel userModel = readUserModel();
    _isLogin = userModel.userId.isNotEmpty;
  }

  /// 获取用户信息（缓存优先）
  UserModel get userModel {
    if (cacheUserModel != null) {
      return cacheUserModel!;
    }
    cacheUserModel = readUserModel();
    return cacheUserModel!;
  }

  /// 保存用户信息到本地
  void saveUser(UserModel userModel) {
    cacheUserModel = userModel;
    StorageUtil.saveString("bx_user", jsonEncode(userModel.toJson()));
  }

  /// 清除用户信息
  void cleanUser() {
    StorageUtil.remove("bx_user");
    cacheUserModel = null;
  }

  ///获取配置
  ConfigModel get configModel {
    if (cacheConfigModel != null) {
      return cacheConfigModel!;
    }
    cacheConfigModel = readConfigModel();
    return cacheConfigModel!;
  }

  /// 获取配置（异步）
  ConfigModel readConfigModel() {
    ConfigModel configModel = ConfigModel();
    String? data = StorageUtil.getString("bx_config");
    if (data != null && data.isNotEmpty) {
      configModel = ConfigModel.fromJson(jsonDecode(data));
    }
    return configModel;
  }

  /// 保存用户信息到本地
  void saveConfig(ConfigModel configModel) {
    cacheConfigModel = configModel;
    StorageUtil.saveString("bx_config", jsonEncode(configModel.toJson()));
  }

  // --- 登录状态管理 ---
  bool _isLogin = false; // 当前登录状态
  bool isLogout = false; // 是否已经退出登录，防止重复跳转登录页面

  bool get isLogin => _isLogin;

  void logout() {
    cleanUser();
    _isLogin = false;
  }

  void dispose() {
    jumpDepositPageController.close();
  }

  final StreamController<bool> jumpDepositPageController = StreamController<bool>.broadcast();

  // --- 设备信息管理 ---
  final String storeKey = "bx_bw";

  Future<String> getDeviceId() async {
    DeviceInfoPlugin info = DeviceInfoPlugin();
    String? deviceId;
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await info.androidInfo;
      deviceId = androidInfo.id;
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await info.iosInfo;
      deviceId = iosInfo.identifierForVendor;
    }
    return deviceId ?? "";
  }
}
