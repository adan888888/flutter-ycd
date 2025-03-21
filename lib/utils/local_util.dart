import 'dart:ui';

import 'package:get/get.dart';
import 'package:ycd/utils/storage_util.dart';

class LocalUtil {
  // 响应式语言状态
  final _local = Rx<Locale>(const Locale('pt'));

  Locale get value => _local.value;

  void setLocal(Locale local) {
    _local.value = local;
    StorageUtil.saveString('languageCode', local.languageCode); // 保存语言设置
  }

  static String getLoaclString() {
    String lanCode = Get.find<LocalUtil>().value.languageCode;
    Get.put<LocalUtil>(LocalUtil());
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
    final Locale initialLocale = savedLanguageCode != null ? Locale(savedLanguageCode) : Locale(const Locale('fr', 'CH').languageCode);
    Get.put(LocalUtil()).setLocal(initialLocale); // 全局注册 LocalUtil 实例
  }
}
