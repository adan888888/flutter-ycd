import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences 本地存储工具类，自动添加包名前缀
class StorageUtil {
  static SharedPreferences? _prefs;
  static String _storageKeyPrefix = '';

  /// 初始化 SharedPreferences
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    try {
      final info = await PackageInfo.fromPlatform();
      _storageKeyPrefix = '${info.packageName}_';
    } catch (_) {
      _storageKeyPrefix = '';
    }
  }

  /// 将业务短键转为带包名前缀的实际存储键
  static String _getKey(String shortKey) => '$_storageKeyPrefix$shortKey';

  /// 存储字符串
  static Future<bool> saveString(String key, String value) async {
    if (_prefs == null) return false;
    return await _prefs!.setString(_getKey(key), value);
  }

  /// 存储整型
  static Future<bool> saveInt(String key, int value) async {
    if (_prefs == null) return false;
    return await _prefs!.setInt(_getKey(key), value);
  }

  /// 存储布尔值
  static Future<bool> saveBool(String key, bool value) async {
    if (_prefs == null) return false;
    return await _prefs!.setBool(_getKey(key), value);
  }

  /// 存储双精度浮点型
  static Future<bool> saveDouble(String key, double value) async {
    if (_prefs == null) return false;
    return await _prefs!.setDouble(_getKey(key), value);
  }

  /// 存储字符串列表
  static Future<bool> saveStringList(String key, List<String> value) async {
    if (_prefs == null) return false;
    return await _prefs!.setStringList(_getKey(key), value);
  }

  /// 获取字符串
  static String? getString(String key) {
    return _prefs?.getString(_getKey(key));
  }

  /// 获取整型
  static int? getInt(String key) {
    return _prefs?.getInt(_getKey(key));
  }

  /// 获取布尔值
  static bool? getBool(String key) {
    return _prefs?.getBool(_getKey(key));
  }

  /// 获取双精度浮点型
  static double? getDouble(String key) {
    return _prefs?.getDouble(_getKey(key));
  }

  /// 获取字符串列表
  static List<String>? getStringList(String key) {
    return _prefs?.getStringList(_getKey(key));
  }

  /// 检查是否存在某个键
  static bool containsKey(String key) {
    return _prefs?.containsKey(_getKey(key)) ?? false;
  }

  /// 删除某个键
  static Future<bool> remove(String key) async {
    if (_prefs == null) return false;
    return await _prefs!.remove(_getKey(key));
  }

  /// 清空所有数据
  static Future<bool> clear() async {
    if (_prefs == null) return false;
    return await _prefs!.clear();
  }
}
