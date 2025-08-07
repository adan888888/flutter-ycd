import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const BaccaratSimulatorApp());
}

class BaccaratSimulatorApp extends StatelessWidget {
  const BaccaratSimulatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '百家乐投注模拟器',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SimulationScreen(),
    );
  }
}

class SimulationScreen extends StatefulWidget {
  const SimulationScreen({super.key});

  @override
  _SimulationScreenState createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  final int totalSimulations = 10;
  final int betsPerSimulation = 10000;
  final double bankerWinProbability = 0.512; // 庄赢概率
  final double playerWinProbability = 0.488; // 闲赢概率

  List<SimulationResult> results = [];
  bool isSimulating = false;
  int currentSimulation = 0;

  // 开始模拟
  void startSimulation() {
    setState(() {
      results.clear();
      isSimulating = true;
      currentSimulation = 0;
    });

    _runSimulations();
  }

  // 运行所有模拟
  Future<void> _runSimulations() async {
    for (int i = 0; i < totalSimulations; i++) {
      if (!isSimulating) break;

      // 执行单次模拟
      final result = await Future<SimulationResult>.delayed(
        const Duration(milliseconds: 100), // 延迟一下，避免UI卡顿
            () => _runSingleSimulation(),
      );

      setState(() {
        results.add(result);
        currentSimulation = i + 1;
      });
    }

    setState(() {
      isSimulating = false;
    });
  }

  // 执行单次模拟（一万次投注）
  SimulationResult _runSingleSimulation() {
    int totalBets = 0;
    int bankerBets = 0;
    int playerBets = 0;
    int bankerWins = 0;
    int playerWins = 0;
    int totalWins = 0;
    int totalLosses = 0;

    final random = Random();

    while (totalBets < betsPerSimulation) {
      // 50/50 随机下注
      bool betOnBanker = random.nextDouble() < 0.7;

      // 模拟开牌结果
      bool bankerWinsThisRound = random.nextDouble() < bankerWinProbability;

      // 记录投注
      if (betOnBanker) {
        bankerBets++;
      } else {
        playerBets++;
      }

      // 判断是否赢了这一局
      bool win = (betOnBanker && bankerWinsThisRound) ||
          (!betOnBanker && !bankerWinsThisRound);

      // 更新统计
      if (win) {
        totalWins++;
        if (betOnBanker) {
          bankerWins++;
        } else {
          playerWins++;
        }
      } else {
        totalLosses++;
      }

      totalBets++;
    }

    return SimulationResult(
      simulationNumber: results.length + 1,
      totalBets: totalBets,
      bankerBets: bankerBets,
      playerBets: playerBets,
      bankerWins: bankerWins,
      playerWins: playerWins,
      totalWins: totalWins,
      totalLosses: totalLosses,
      winLossDifference: totalWins - totalLosses,
    );
  }

  // 停止模拟
  void stopSimulation() {
    setState(() {
      isSimulating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('百家乐投注模拟器'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 模拟控制按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: isSimulating ? null : startSimulation,
                  child: const Text('开始模拟'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: isSimulating ? stopSimulation : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('停止模拟'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 模拟进度
            if (isSimulating)
              Column(
                children: [
                  Text('正在进行第 $currentSimulation/$totalSimulations 次模拟'),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: currentSimulation / totalSimulations,
                  ),
                ],
              ),

            const SizedBox(height: 16),

            // 结果展示
            const Text(
              '模拟结果',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // 结果表格
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('模拟次数')),
                    DataColumn(label: Text('总投注')),
                    DataColumn(label: Text('赢')),
                    DataColumn(label: Text('输')),
                    DataColumn(label: Text('赢-输')),
                  ],
                  rows: results.map((result) {
                    return DataRow(cells: [
                      DataCell(Text('${result.simulationNumber}')),
                      DataCell(Text('${result.totalBets}')),
                      DataCell(Text('${result.totalWins}')),
                      DataCell(Text('${result.totalLosses}')),
                      DataCell(Text(
                        '${result.winLossDifference}',
                        style: TextStyle(
                          color: result.winLossDifference >= 0
                              ? Colors.green
                              : Colors.red,
                        ),
                      )),
                    ]);
                  }).toList(),
                ),
              ),
            ),

            // 总计信息
            if (results.isNotEmpty && !isSimulating)
              Column(
                children: [
                  const Divider(height: 20),
                  Text(
                    '总计: 赢-输 = ${results.fold(0, (sum, item) => sum + item.winLossDifference)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '平均: 赢-输 = ${(results.fold(0, (sum, item) => sum + item.winLossDifference) / results.length).toStringAsFixed(1)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// 模拟结果数据类
class SimulationResult {
  final int simulationNumber;
  final int totalBets;
  final int bankerBets;
  final int playerBets;
  final int bankerWins;
  final int playerWins;
  final int totalWins;
  final int totalLosses;
  final int winLossDifference;

  SimulationResult({
    required this.simulationNumber,
    required this.totalBets,
    required this.bankerBets,
    required this.playerBets,
    required this.bankerWins,
    required this.playerWins,
    required this.totalWins,
    required this.totalLosses,
    required this.winLossDifference,
  });
}
