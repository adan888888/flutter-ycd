import 'package:shared_preferences/shared_preferences.dart';

class StorageUtil {
  static SharedPreferences? _prefs;

  /// 初始化 SharedPreferences
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// 存储字符串
  static Future<bool> saveString(String key, String value) async {
    if (_prefs == null) return false;
    return await _prefs!.setString(key, value);
  }

  /// 存储整型
  static Future<bool> saveInt(String key, int value) async {
    if (_prefs == null) return false;
    return await _prefs!.setInt(key, value);
  }

  /// 存储布尔值
  static Future<bool> saveBool(String key, bool value) async {
    if (_prefs == null) return false;
    return await _prefs!.setBool(key, value);
  }

  /// 存储双精度浮点型
  static Future<bool> saveDouble(String key, double value) async {
    if (_prefs == null) return false;
    return await _prefs!.setDouble(key, value);
  }

  /// 存储字符串列表
  static Future<bool> saveStringList(String key, List<String> value) async {
    if (_prefs == null) return false;
    return await _prefs!.setStringList(key, value);
  }

  /// 获取字符串
  static String? getString(String key) {
    return _prefs?.getString(key);
  }

  /// 获取整型
  static int? getInt(String key) {
    return _prefs?.getInt(key);
  }

  /// 获取布尔值
  static bool? getBool(String key) {
    return _prefs?.getBool(key);
  }

  /// 获取双精度浮点型
  static double? getDouble(String key) {
    return _prefs?.getDouble(key);
  }

  /// 获取字符串列表
  static List<String>? getStringList(String key) {
    return _prefs?.getStringList(key);
  }

  /// 检查是否存在某个键
  static bool containsKey(String key) {
    return _prefs?.containsKey(key) ?? false;
  }

  /// 删除某个键
  static Future<bool> remove(String key) async {
    if (_prefs == null) return false;
    return await _prefs!.remove(key);
  }

  /// 清空所有数据
  static Future<bool> clear() async {
    if (_prefs == null) return false;
    return await _prefs!.clear();
  }
}