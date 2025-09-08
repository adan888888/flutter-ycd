import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart'; // Added for debugPrint

//测试十三层缆
void main() {
  const int simulations = 10000; // 运行 1 万次游戏
  const double bankerWinRate = 0.5068; // 庄的胜率
  // const double playerWinRate = 0.4932; // 闲的胜率 - 未使用，已注释
  const double bankerCommission = 0.95; // 押庄赢了后扣除 5% 佣金

  // 下注缆系统，第一列为主注，第二列和第三列用于补救
  const List<List<int>> fibSystem = [
    [1],
    [2],
    [3, 2, 4],
    [5, 3, 6],
    [8, 5, 10],
    [13, 8, 16],
    [21, 13, 26],
    [34, 21, 42],
    [55, 34, 68],
    [89, 55, 110],
    [144, 89, 178],
    [233, 144, 288],
    [377, 233, 466],
  ];

  int bankerWins = 0; // 统计庄赢次数
  int playerWins = 0; // 统计闲赢次数
  int successfulResets = 0; // 统计缆法成功回本次数
  int maxBet = 0; // 记录最大下注额
  int brokenFib = 0; // 统计断缆次数
  int totalBetsWon = 0; // 统计总共赢了多少注
  double totalProfit = 0; // 统计总盈利
  int totalBets = 0; // 统计总下注次数
  int runningWater = 0;
  final Random random = Random();

  for (int i = 0; i < simulations; i++) {
    int currentRow = 0; // 记录当前下注行
    int currentCol = 0; // 记录当前下注列

    while (currentRow < fibSystem.length) {
      final int bet = fibSystem[currentRow][currentCol]; // 获取当前下注额
      maxBet = max(maxBet, bet); // 记录最大下注额
      if (totalBets > simulations - 1) {
        break;
      }
      totalBets++; // 统计总下注次数

      // 随机选择押庄还是押闲（50% 概率）
      // bool betOnBanker = random.nextBool(); //假设true为庄 - 注释掉用于测试
      bool betOnBanker;
      if (next(1, 90485) > 44625 - 10000) {
        betOnBanker = true;
      } else {
        betOnBanker = false;
      }
      final bool bankerWinsRound = random.nextDouble() /* 0.0（包含）到 1.0（不包含）之间的随机双精度浮点数*/ < bankerWinRate; // 模拟开出的庄还是闲小于bankerWinRate是庄

      if (betOnBanker) {
        //如果投注是庄
        if (bankerWinsRound) {
          //开奖是庄
          //押庄赢
          bankerWins++;
          totalBetsWon++;
          totalProfit += bet * bankerCommission; // 押庄赢了扣 5% 佣金
        } else {
          //开奖是闲
          playerWins++;
          totalProfit -= bet;
        }
      } else {
        //如果投注是闲

        if (!bankerWinsRound) {
          //开奖是闲
          //押闲赢
          playerWins++;
          totalBetsWon++;
          totalProfit += bet; // 押闲赢了全额盈利
        } else {
          bankerWins++;
          totalProfit -= bet;
        }
      }
      runningWater += bet; //总流水

      // 如果赢了(押对了)
      if (bankerWinsRound == betOnBanker) {
        // 如果赢了并且是第一列的第一行和第二行，直接重新开始
        if (currentCol == 0 && (currentRow == 0 || currentRow == 1)) {
          successfulResets++;
          currentRow = 0;
          currentCol = 0;
          break;
        } else {
          // 第一列的第3层开始赢了往右走
          if (currentCol == 0) {
            currentCol++;
          } else {
            //第二列和第三列的赢了才回本
            successfulResets++;
            currentRow = 0;
            currentCol = 0;
            break;
          }
        }
      } else {
        if (currentCol == 0) {
          currentRow++; // 第一列输了直接增加行
          if (currentRow == 13 || (currentRow == 12 && currentCol == 2)) {
            brokenFib++; // 如果未成功回本，则统计一次断缆
          }
        } else {
          if (currentCol < fibSystem[currentRow].length - 1) {
            currentCol++; // 进入第二列或第三列下注
          } else {
            currentRow++; // 进入下一行的第一列下注
            currentCol = 0;
          }
        }
      }
    }
  }

  final double winRate = totalBetsWon / totalBets; // 计算下注胜率
  final double successRate = successfulResets / simulations; // 计算缆法成功回本率
  final double brokenRate = brokenFib / simulations; // 计算断缆率

  // 替换所有 print 语句为 debugPrint
  debugPrint('总局数: $simulations');
  debugPrint('庄赢次数: $bankerWins');
  debugPrint('闲赢次数: $playerWins');
  debugPrint('庄闲偏差（庄赢 - 闲赢）: ${bankerWins - playerWins}');
  debugPrint('缆法成功回本次数: $successfulResets');
  debugPrint('缆法成功回本率: ${(successRate * 100).toStringAsFixed(2)}%');
  debugPrint('断缆次数: $brokenFib');
  debugPrint('断缆率: ${(brokenRate * 100).toStringAsFixed(2)}%');
  debugPrint('总共赢了多少注: $totalBetsWon');
  debugPrint('总下注次数: $totalBets');
  debugPrint('下注胜率: ${(winRate * 100).toStringAsFixed(2)}%');
  debugPrint('最大下注额: $maxBet');
  debugPrint('流水返利: ${runningWater * 0.0078}');
  debugPrint('最终盈利: ${totalProfit.toStringAsFixed(2)}');

  debugPrint(removeChineseCharacters("可负20x8".split("x")[0]));

  // 移除未使用的变量 ssss
  final user = User("john", 1000)
    ..age = 100
    ..name = "John";
  debugPrint(jsonEncode(user.toJson()));
  debugPrint("--------------------------------------------------");
  debugPrint(funxxx().toString());

  debugPrint("--------------------------------------------------");
  final Map<String, dynamic> o = {"tableId": 10000, "age": 100, "name": "张三"};
  o.remove("tableId");
  debugPrint(jsonEncode(o));
}

int next(int min, int max) => min + Random().nextInt(max - min + 1);

String removeChineseCharacters(String input) {
  return input.replaceAll(RegExp('[\u4e00-\u9fa5]'), '');
}

class User {
  String? name;
  int? age;

  User(this.name, this.age);

  User.fromJson(Map<String, dynamic> j) {
    name = j['name'] as String?;
    age = j['age'] as int?;
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'age': age,
      };
}

bool funxxx() {
  final Map<String, dynamic> temp = {"x": 0, "y": 0, "tppe": "小"};
  final Map<String, dynamic> temp1 = {"x": 0, "y": 1, "tppe": "操"};
  final Map<String, dynamic> temp3 = {"x": 0, "y": 2, "tppe": "妹"};

  final List<Map<String, dynamic>> list = [temp, temp1, temp3];

  for (final Map<String, dynamic> value1 in list) {
    if (value1['x'] == 0 && value1['y'] == 0) {
      debugPrint(value1['tppe'].toString());
      return true;
    }
    debugPrint(value1.toString());
  }
  return false;
}
