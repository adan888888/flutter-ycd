import 'package:flutter/foundation.dart';

class Api {
  /// **真机 / 另一台电脑访问本机后端**：`localhost` 指向设备自己，必然连不上。
  /// Docker 部署时 H5 经 Nginx 反代 `/api`；Flutter 真机用 ngrok 公网地址：
  ///
  /// ```bash
  /// flutter run --dart-define=API_BASE_URL=https://verbose-exhume-cringe.ngrok-free.dev/api
  /// flutter run --dart-define=API_BASE_URL=http://192.168.1.5:8080/api
  /// ```
  /// **macOS 打包**：`scripts/build_macos_app.sh both|all|1|2|3 [API_BASE_URL]`（第二参数为可选地址；`all` 会打 数策1/2/3）。
  static String get baseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (fromEnv.isNotEmpty) {
      var s = fromEnv.trim();
      if (s.endsWith('/')) s = s.substring(0, s.length - 1);
      return s;
    }
    if (kIsWeb) {
      return "http://localhost:3001/api";
    }
    if (defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return "http://localhost:3000/api";
    }
    return "https://verbose-exhume-cringe.ngrok-free.dev/api";
  }

  static String config = "/tenant/get";

  ///登录
  static String login = "/auth/login";

  ///登出（服务端拉黑 token）
  static String logout = "/auth/logout";

  //初始化程序 创建表
  static String createTables = "/jsq/create-table";

  //获取操作记录
  static String getOperationRecords = "/jsq/operation-records";

  //插入操作记录
  static String createOperationRecord = "/jsq/operation-records";

  //插入投注记录
  static String createBetRecord = "/jsq/bet-records";

  // 更新重启统计快照
  static String updateLastRowRestartStatSnapshot = "/jsq/update-restart-stat-snapshot";

  //删除最后一行
  static String deleteLast = "/jsq/delete-last";

  //重新启动
  static String restart = "/jsq/restart";

  //排序消数列
  static String sortXiaoShu = "/jsq/sort-xiao-shu";

  //消数
  static String xiaoShu = "/jsq/xiao-shu";

  //删除本页
  static String deleteAll = "/jsq/delete-all";

  //重置流水
  static String resetLiuShui = "/jsq/reset-liu-shui";

  //修改个性期望值
  static String updateQiWangValue = "/jsq/update-qiwang-value";

  //修改赔率
  static String updateOdds = "/jsq/update-odds";

  //修改本金
  static String updateBenjin = "/jsq/update-benjin";

  //加载更多历史数据
  static String loadMore = "/jsq/load-more";

  //加载更多历史数据
  static String getStatisticalAreasData = "/jsq/statistical-areas-data";

  //折线图数据
  static String getLinechartData = "/jsq/line-chart-data";

  //清除数据（消数列数据全部清除）
  static String cleanDataD = "/jsq/clean-data";

  //随机庄闲接口
  static String randomBankerPlayer = "/jsq/random-banker-player";

  static String buyRecords = "/buyRecords";

  // 密码本相关API
  static String passwordBook = "/password-book";
  static String passwordBookList = "/password-book";
  static String passwordBookItem = "/password-book";
  static String passwordBookBatchDelete = "/password-book/batch-delete";

  // 备份相关API
  static String backupManual = "/backup/manual";
}
