import 'dart:convert';

import 'package:get/get.dart';
import 'package:ycd/utils/network/api.dart';
import 'package:ycd/utils/network/dio_manager.dart';
import 'package:ycd/utils/storage_util.dart';

/// 首页工具项：key 与后端 app/controllers/misc.py 的 HOME_TOOLS 一致
class HomeToolConfig {
  const HomeToolConfig({required this.key});

  final String key;

  factory HomeToolConfig.fromJson(Map<String, dynamic> json) =>
      HomeToolConfig(key: json['key']?.toString() ?? '');

  Map<String, dynamic> toJson() => {'key': key};
}

/// 点击工具时后端返回的准入结果；reason：login=需登录，pro=需专业版，unavailable=未开放
class HomeToolAccess {
  const HomeToolAccess({
    required this.allowed,
    this.reason = '',
    this.message = '',
  });

  final bool allowed;
  final String reason;
  final String message;
}

/// 首页「全部工具」列表与准入都由后端控制：列表先用本地缓存，再拉取后端最新配置
class HomeToolsController extends GetxController {
  static const String _cacheKeyPrefix = 'home_tools_v4_';

  /// 未拿到后端配置时的兜底列表，能否进入仍以点击时的接口结果为准
  static const List<HomeToolConfig> _defaultTools = [
    HomeToolConfig(key: 'buy_records'),
    HomeToolConfig(key: 'investment_calculator'),
    HomeToolConfig(key: 'rsi_analysis'),
    HomeToolConfig(key: 'rsi_strategy_backtest'),
    HomeToolConfig(key: 'currency_converter'),
    HomeToolConfig(key: 'aes_encrypt'),
    HomeToolConfig(key: 'digital_password_book'),
    HomeToolConfig(key: 'baccarat_simulation'),
  ];

  static HomeToolsController get to => Get.isRegistered<HomeToolsController>()
      ? Get.find<HomeToolsController>()
      : Get.put(HomeToolsController(), permanent: true);

  final RxList<HomeToolConfig> tools = <HomeToolConfig>[].obs;
  String? _loadedFor;

  /// 列表按用户区分（后端按角色过滤），登录/切换账号后重新拉取
  void syncUser(String userKey) {
    if (_loadedFor == userKey) return;
    _loadedFor = userKey;
    tools.assignAll(_readCache(userKey) ?? _defaultTools);
    fetch(userKey);
  }

  Future<void> fetch(String userKey) async {
    try {
      final response = await DioManager.getInstance().get(Api.homeTools);
      final body = response.data;
      if (body is! Map || body['code'].toString() != '0') return;
      final list = (body['data'] as Map?)?['tools'];
      if (list is! List) return;
      final parsed = list
          .whereType<Map>()
          .map((item) =>
              HomeToolConfig.fromJson(Map<String, dynamic>.from(item)))
          .where((tool) => tool.key.isNotEmpty)
          .toList();
      if (_loadedFor != userKey) return;
      tools.assignAll(parsed);
      await StorageUtil.saveString(
        '$_cacheKeyPrefix$userKey',
        jsonEncode(parsed.map((tool) => tool.toJson()).toList()),
      );
    } catch (_) {
      // 网络失败保留缓存或默认配置
    }
  }

  /// 网络异常返回 null，由调用方提示重试
  Future<HomeToolAccess?> checkAccess(String key) async {
    try {
      final response =
          await DioManager.getInstance().get(Api.homeToolAccess(key));
      final body = response.data;
      if (body is! Map) return null;
      if (body['code'].toString() != '0') {
        return HomeToolAccess(
          allowed: false,
          message: body['msg']?.toString() ?? '',
        );
      }
      final data = body['data'];
      if (data is! Map) return null;
      return HomeToolAccess(
        allowed: data['allowed'] == true,
        reason: data['reason']?.toString() ?? '',
        message: data['message']?.toString() ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  List<HomeToolConfig>? _readCache(String userKey) {
    final raw = StorageUtil.getString('$_cacheKeyPrefix$userKey');
    if (raw == null || raw.isEmpty) return null;
    try {
      final list = jsonDecode(raw);
      if (list is! List) return null;
      return list
          .whereType<Map>()
          .map((item) =>
              HomeToolConfig.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return null;
    }
  }
}
