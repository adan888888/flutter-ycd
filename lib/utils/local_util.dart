import 'dart:ui';
import 'package:get/get.dart';
import 'package:ycd/utils/storage_util.dart';

/// 应用级语言状态，独立于 GetX 路由生命周期；网络拦截器会在任意页面读取它。
class LocalUtil {
  LocalUtil._();

  static final LocalUtil _instance = LocalUtil._();

  // 响应式语言状态
  final _local = Rx<Locale>(const Locale('pt'));

  Locale get value => _local.value;

  void setLocal(Locale local) {
    _local.value = local;
    StorageUtil.saveString('languageCode', local.languageCode); // 保存语言设置
  }

  static String getLoaclString() {
    final String lanCode = _instance.value.languageCode;
    if (lanCode == "zh") {
      return "zh_CN";
    } else if (lanCode == "pt") {
      return "pt_BR";
    } else {
      return "en_US";
    }
  }

  static void loadDefaultLan() {
    final String? savedLanguageCode = StorageUtil.getString('languageCode');
    final Locale initialLocale = savedLanguageCode != null
        ? Locale(savedLanguageCode)
        : Locale(const Locale('fr', 'CH').languageCode);
    _instance.setLocal(initialLocale);
  }
}
