class Api {
  // static String baseUrl = "https://zsapi.cach.xyz/api/";
  static String baseUrl = "http://localhost:3000/api";

  // static String baseUrl = "http://192.168.32.154:3000/api";

  static String config = "/tenant/get";

  ///登录
  static String login = "/auth/login";

  //初始化程序 创建表
  static String createtables = "/ycd/createtable";

  //获取表一数据
  static String getTable1 = "/ycd/table1";

  //获取表一数据
  static String getTable2 = "/ycd/table2";

  //插入表一数据
  static String inserttable1 = "/ycd/inserttable1";

  //插入表一数据
  static String inserttable2 = "/ycd/inserttable2";

  //删除最后一行
  static String deletelast = "/ycd/deletelast";

  //重新启动
  static String restart = "/ycd/restart";

  //排序消数列
  static String sortxiaoshu = "/ycd/sortxiaoshu";

  //消数
  static String xiaoshu = "/ycd/xiaoshu";

  //删除本页
  static String deleteall = "/ycd/deleteall";

  //重置流水
  static String resetliushui = "/ycd/resetliushui";

  //修改个性期望值
  static String updateQiWangValue = "/ycd/updateqiwangvalue";

  //修改赔率
  static String updateOdds = "/ycd/updateodds";

  //修改本金
  static String updateBenjin = "/ycd/updatebenjin";

  //加载更多历史数据
  static String loadMore = "/ycd/loadmore";

  //加载更多历史数据
  static String getStatisticalAreasData = "/ycd/getStatisticalAreasData";

  //折线图数据
  static String getLinechartData = "/ycd/linechartData";
}
