import 'package:ycd/utils/local_util.dart';
import 'package:ycd/utils/network/get_store.dart';
import 'package:ycd/utils/storage_util.dart';

/// 启动页显示期间完成业务初始化。
///
/// Future 会被缓存，避免启动页因重建或重复进入而并发初始化本地存储。
abstract final class AppBootstrap {
  static Future<void>? _initialization;

  static Future<void> initialize() {
    final existing = _initialization;
    if (existing != null) return existing;

    late final Future<void> initialization;
    initialization =
        _initialize().onError((Object error, StackTrace stackTrace) {
      // 初始化失败不能永久缓存；启动页上的“重试”需要重新执行完整初始化。
      if (identical(_initialization, initialization)) {
        _initialization = null;
      }
      Error.throwWithStackTrace(error, stackTrace);
    });
    _initialization = initialization;
    return initialization;
  }

  static Future<void> _initialize() async {
    // StorageUtil 必须先完成：后续登录态和语言读取都是同步 getter。
    // PackageInfo 会缓存第一次结果，紧接着初始化业务命名空间不会重复做昂贵工作。
    await StorageUtil.init();
    await GetStore.initStorageNamespace();

    GetStore.getInstance().checkLoginStatus();
    LocalUtil.loadDefaultLan();
  }
}
