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
  String currentCurrency = 'btc';
}
