class Api {
  // static String baseUrl = "https://zsapi.cach.xyz/api/";
  static String baseUrl = "http://192.168.100.140:3000/api";
  // static String baseUrl = "http://192.168.32.154:3000/api";

  static String config = "/tenant/get";

  ///登录
  static String login = "/login";

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
}
