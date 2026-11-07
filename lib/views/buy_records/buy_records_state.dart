/// 买入记录页面状态管理
class BuyRecordsState {
  /// 买入记录列表
  List<Map<String, dynamic>> buyRecords = [];

  /// 是否正在加载
  bool isLoading = false;

  /// 错误信息
  String? errorMessage;

  /// 当前价格
  double? currentPrice;

  /// 当前币种的 200 日 SMA（日线收盘价）
  double? ma200Daily;

  /// 当前选择的币种
  String currentCurrency = 'trx';

  /// 用户自定义的基准买入金额（currencyId -> USDT）
  Map<String, double> customBaseAmounts = {};

  /// 近 24 小时涨跌幅（currencyId -> 百分数）。null 表示这次没取到。
  Map<String, double?> changePercent24h = {};
}
