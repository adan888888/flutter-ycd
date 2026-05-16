import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../model/config_model.dart';
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

  /// SharedPreferences / Hive 键前缀，形如 `com.example.app_`，须在首屏读本地数据前完成初始化。
  static String _storageKeyPrefix = '';

  static Future<void> initStorageNamespace() async {
    try {
      final info = await PackageInfo.fromPlatform();
      _storageKeyPrefix = '${info.packageName}_';
    } catch (_) {
      _storageKeyPrefix = '';
    }
  }

  /// 将业务短键转为带包名前缀的实际存储键（避免多包名/多渠道共用同一键）。
  static String prefKey(String shortKey) => '$_storageKeyPrefix$shortKey';

  static String? _readPrefWithLegacyMigrate(String shortKey) {
    final namespaced = prefKey(shortKey);
    final primary = StorageUtil.getString(namespaced);
    if (primary != null && primary.isNotEmpty) return primary;
    final legacy = StorageUtil.getString(shortKey);
    if (legacy != null && legacy.isNotEmpty) {
      unawaited(StorageUtil.saveString(namespaced, legacy));
      unawaited(StorageUtil.remove(shortKey));
      return legacy;
    }
    return null;
  }

  // --- 用户数据缓存与管理 ---
  static UserModel? cacheUserModel;

  // --- 用户数据缓存与管理 ---
  static ConfigModel? cacheConfigModel;

  /// 获取用户信息数据（异步）
  UserModel readUserModel() {
    UserModel userModel = UserModel();
    String? data = _readPrefWithLegacyMigrate('bx_user');
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
    final key = prefKey('bx_user');
    StorageUtil.saveString(key, jsonEncode(userModel.toJson()));
    if (key != 'bx_user') unawaited(StorageUtil.remove('bx_user'));
  }

  /// 清除用户信息
  void cleanUser() {
    unawaited(StorageUtil.remove(prefKey('bx_user')));
    unawaited(StorageUtil.remove('bx_user'));
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
    String? data = _readPrefWithLegacyMigrate('bx_config');
    if (data != null && data.isNotEmpty) {
      configModel = ConfigModel.fromJson(jsonDecode(data));
    }
    return configModel;
  }

  /// 保存用户信息到本地
  void saveConfig(ConfigModel configModel) {
    cacheConfigModel = configModel;
    final key = prefKey('bx_config');
    StorageUtil.saveString(key, jsonEncode(configModel.toJson()));
    if (key != 'bx_config') unawaited(StorageUtil.remove('bx_config'));
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
  String get storeKey => prefKey('bx_bw');

  Future<String> getDeviceId() async {
    DeviceInfoPlugin info = DeviceInfoPlugin();
    String? deviceId;
    
    if (kIsWeb) {
      // Web 平台使用浏览器信息作为设备ID
      WebBrowserInfo webInfo = await info.webBrowserInfo;
      deviceId = webInfo.userAgent ?? "web_browser";
    } else if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await info.androidInfo;
      deviceId = androidInfo.id;
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await info.iosInfo;
      deviceId = iosInfo.identifierForVendor;
    }
    
    return deviceId ?? "unknown_device";
  }
}
