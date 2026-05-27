import 'package:flutter/foundation.dart';

class Api {
  /// **真机 / 另一台电脑访问本机后端**：`localhost` 指向设备自己，必然连不上。
  /// 请把电脑与手机连同一 WiFi，查电脑局域网 IP（如 macOS：`ifconfig | grep inet`），然后：
  ///
  /// ```bash
  /// flutter run --dart-define=API_BASE_URL=http://192.168.1.5:3000/api
  /// ```
  /// **macOS 打包**：`scripts/build_macos_app.sh both|all|1|2|3 [API_BASE_URL]`（第二参数为可选地址；`all` 会打 计数器1/2/3）。
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
    return "http://localhost:3000/api";
  }

  static String config = "/tenant/get";

  ///登录
  static String login = "/auth/login";

  //初始化程序 创建表
  static String createtables = "/jsq/createtable";

  //获取表一数据
  static String getTable1 = "/jsq/table1";

  //插入表一数据
  static String inserttable1 = "/jsq/inserttable1";

  //插入表二数据
  static String inserttable2 = "/jsq/inserttable2";

  // 更新重启统计快照
  static String updateLastRowRestartStatSnapshot = "/jsq/updaterestartstatsnapshot";

  //删除最后一行
  static String deletelast = "/jsq/deletelast";

  //重新启动
  static String restart = "/jsq/restart";

  //排序消数列
  static String sortxiaoshu = "/jsq/sortxiaoshu";

  //消数
  static String xiaoshu = "/jsq/xiaoshu";

  //删除本页
  static String deleteall = "/jsq/deleteall";

  //重置流水
  static String resetliushui = "/jsq/resetliushui";

  //修改个性期望值
  static String updateQiWangValue = "/jsq/updateqiwangvalue";

  //修改赔率
  static String updateOdds = "/jsq/updateodds";

  //修改本金
  static String updateBenjin = "/jsq/updatebenjin";

  //加载更多历史数据
  static String loadMore = "/jsq/loadmore";

  //加载更多历史数据
  static String getStatisticalAreasData = "/jsq/getStatisticalAreasData";

  //折线图数据
  static String getLinechartData = "/jsq/linechartData";

  //清除数据（消数列数据全部清除）
  static String cleanDataD = "/jsq/cleanDataD";

  //随机庄闲接口
  static String randomBankerPlayer = "/jsq/randomBankerPlayer";

  static String buyRecords = "/buyRecords";

  // 密码本相关API
  static String passwordBook = "/password-book";
  static String passwordBookList = "/password-book";
  static String passwordBookItem = "/password-book";
  static String passwordBookBatchDelete = "/password-book/batch-delete";

  // 备份相关API
  static String backupManual = "/backup/manual";
}
