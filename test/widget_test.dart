import 'dart:convert';
import 'dart:math';

//测试十三层缆
void main() {
  const int simulations = 10000; // 运行 1 万次游戏
  const double bankerWinRate = 0.5068; // 庄的胜率
  const double playerWinRate = 0.4932; // 闲的胜率
  const double bankerCommission = 0.95; // 押庄赢了后扣除 5% 佣金

  // 下注缆系统，第一列为主注，第二列和第三列用于补救
  List<List<int>> fibSystem = [
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
  Random random = Random();

  for (int i = 0; i < simulations; i++) {
    int currentRow = 0; // 记录当前下注行
    int currentCol = 0; // 记录当前下注列

    while (currentRow < fibSystem.length) {
      int bet = fibSystem[currentRow][currentCol]; // 获取当前下注额
      maxBet = max(maxBet, bet); // 记录最大下注额
      if (totalBets > simulations - 1) {
        break;
      }
      totalBets++; // 统计总下注次数

      // 随机选择押庄还是押闲（50% 概率）
      bool betOnBanker = random.nextBool(); //假设true为庄
      if (next(1, 90485) > 44625 - 10000) {
        betOnBanker = true;
      } else {
        betOnBanker = false;
      }
      betOnBanker = true;
      bool bankerWinsRound = random.nextDouble() /* 0.0（包含）到 1.0（不包含）之间的随机双精度浮点数*/ < bankerWinRate; // 模拟开出的庄还是闲小于bankerWinRate是庄

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

  double winRate = totalBetsWon / totalBets; // 计算下注胜率
  double successRate = successfulResets / simulations; // 计算缆法成功回本率
  double brokenRate = brokenFib / simulations; // 计算断缆率

  print('总局数: $simulations');
  print('庄赢次数: $bankerWins');
  print('闲赢次数: $playerWins');
  print('庄闲偏差（庄赢 - 闲赢）: ${bankerWins - playerWins}');
  print('缆法成功回本次数: $successfulResets');
  print('缆法成功回本率: ${(successRate * 100).toStringAsFixed(2)}%');
  print('断缆次数: $brokenFib');
  print('断缆率: ${(brokenRate * 100).toStringAsFixed(2)}%');
  print('总共赢了多少注: $totalBetsWon');
  print('总下注次数: $totalBets');
  print('下注胜率: ${(winRate * 100).toStringAsFixed(2)}%');
  print('最大下注额: $maxBet');
  print('流水返利: ${runningWater * 0.0078}');
  print('最终盈利: ${totalProfit.toStringAsFixed(2)}');

  print(removeChineseCharacters("可负20x8".split("x")[0]));

  String ssss = '''
     {"name":"john","age":"2000"}
  ''';
  var user = User("john", 1000)
    ..age = 100
    ..name = "John";
  print(jsonEncode(user.toJson()));
  print("--------------------------------------------------");
  print(funxxx());

  print("--------------------------------------------------");
  var o={"tableId":10000, "age":100, "name":"张三"};
  print(jsonEncode(o..remove("tableId")));
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

  toJson() => {
        'name': name,
        'age': age,
      };
}

bool funxxx() {
  var temp = {"x": 0, "y": 0, "tppe": "小"};
  var temp1 = {"x": 0, "y": 1, "tppe": "操"};
  var temp3 = {"x": 0, "y": 2, "tppe": "妹"};

  var list = [temp, temp1, temp3];

  for (var value1 in list) {
    if (value1['x'] == 0 && value1['y'] == 0) {
      print(value1['tppe']);
      return true;
    }
    print(value1);
  }
  return false;
}
