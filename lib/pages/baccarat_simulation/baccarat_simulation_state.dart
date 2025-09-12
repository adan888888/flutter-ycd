/// 百家乐模拟状态管理
class BaccaratSimulationState {
  // ***********== 常量定义 ***********==
  /// 大路图行数
  static const int bigRoadRows = 6;

  /// 大路图列数
  static const int bigRoadCols = 120;

  /// 每个格子的宽度（像素）
  static const double cellWidth = 20.0;

  // ***********== 游戏状态 ***********==
  /// 是否正在播放动画
  bool isAnimating = false;

  /// 当前开奖结果文本（如：闲家胜 (8 vs 6)）
  String currentResult = '';

  /// 闲家手牌显示文本（如：♠A ♥K）
  String playerCards = '';

  /// 庄家手牌显示文本（如：♦2 ♣5）
  String bankerCards = '';

  /// 闲家总点数（0-9）
  int playerTotal = 0;

  /// 庄家总点数（0-9）
  int bankerTotal = 0;

  /// 本局获胜者（闲家/庄家/和局）
  String winner = '';

  /// 是否显示开奖结果区域
  bool showResultArea = true;

  // ***********== 历史记录和路子图 ***********==
  /// 游戏历史记录列表（最多保存20局）
  List<Map<String, dynamic>> gameHistory = [];

  /// 简单的路子图记录（用于其他路子图显示）
  List<String> roadMap = [];

  /// 大路图数据（6行${bigRoadCols}列的二维数组）
  List<List<String>> bigRoad = [];

  // ***********== 大路图状态 ***********==
  /// 当前大路图行位置（0-5）
  int currentRow = 0;

  /// 当前大路图列位置（0-119）
  int currentCol = 0;

  /// 上一局的获胜者（用于判断大路图绘制规则）
  String lastWinner = '';

  /// 当前列是否已填满6行
  bool currentColumnFull = false;

  /// 长龙开始的列（用于长龙结束后确定下一个不同结果的起始位置）
  int dragonStartCol = -1;

  /// 长龙平行绘制的行位置（当长龙开始向右平行绘制时记录）
  int dragonParallelRow = -1;
  int recordRowFirst = 0; //记录横向的次数
  int recordRightCol = 0; //记录横向时候的

  /// 构造函数
  /// 初始化大路图数据
  BaccaratSimulationState() {
    initializeBigRoad();
  }

  /// 初始化大路图
  /// 创建6行120列的空大路图，重置所有位置状态
  void initializeBigRoad() {
    bigRoad = List.generate(bigRoadRows, (index) => List.generate(bigRoadCols, (index) => ''));
    currentRow = 0;
    currentCol = 0;
    lastWinner = '';
    currentColumnFull = false;
    dragonStartCol = -1; // 重置长龙开始列
    dragonParallelRow = -1; // 重置长龙平行绘制行
  }

  /// 检查大路图是否有数据
  /// 返回true表示大路图中有任何非空数据
  bool get hasBigRoadData {
    bool hasData = bigRoad.any((row) => row.any((cell) => cell.isNotEmpty));
    return hasData;
  }
}
