import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class BaccaratSimulationPage extends StatefulWidget {
  const BaccaratSimulationPage({super.key});

  @override
  State<BaccaratSimulationPage> createState() => _BaccaratSimulationPageState();
}

class _BaccaratSimulationPageState extends State<BaccaratSimulationPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  final Random _random = Random();
  List<Map<String, dynamic>> _gameHistory = [];
  List<String> _roadMap = []; // 路子图数据
  List<List<String>> _bigRoad = []; // 大路数据 (6x6网格)
  int _currentRow = 0; // 当前行
  int _currentCol = 0; // 当前列
  String _lastWinner = ''; // 上一局获胜者
  bool _isAnimating = false;
  String _currentResult = '';
  String _playerCards = '';
  String _bankerCards = '';
  int _playerTotal = 0;
  int _bankerTotal = 0;
  String _winner = '';
  bool _showResultArea = true; // 控制结果显示区域的显示/隐藏

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2), // 动画持续2秒
      vsync: this, // 使用当前Widget作为TickerProvider
    );

    // 缩放动画：从0缩放到1，使用弹性曲线
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    // 初始化大路
    _initializeBigRoad();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // 初始化大路
  void _initializeBigRoad() {
    _bigRoad = List.generate(6, (index) => List.generate(30, (index) => ''));
    _currentRow = 0;
    _currentCol = 0;
    _lastWinner = '';
  }

  // 更新大路
  void _updateBigRoad(String winner) {
    // 和局不记录在大路中
    if (winner == '和局') {
      return;
    }

    // 如果是第一局，直接记录在第1行第1列
    if (_lastWinner == '') {
      _bigRoad[_currentRow][_currentCol] = winner;
      _currentCol++;
    }
    // 如果与上一局不同，向右移动
    else if (_lastWinner != winner) {
      // 检查是否需要换行
      if (_currentCol >= 30) {
        _currentRow++;
        _currentCol = 0;

        // 如果超过6行，清空重新开始
        if (_currentRow >= 6) {
          _initializeBigRoad();
        }
      }

      _bigRoad[_currentRow][_currentCol] = winner;
      _currentCol++;
    }
    // 如果与上一局相同，向下移动
    else {
      // 找到当前列的第一个空位置
      int targetRow = 0;
      for (int i = 0; i < 6; i++) {
        if (_bigRoad[i][_currentCol - 1].isEmpty) {
          targetRow = i;
          break;
        }
      }

      _bigRoad[targetRow][_currentCol - 1] = winner;

      // 如果填满了6行，清空重新开始
      if (targetRow == 5) {
        _initializeBigRoad();
      }
    }

    _lastWinner = winner;
  }

  // 生成随机卡片
  Map<String, dynamic> _generateCard() {
    final suits = ['♠', '♥', '♦', '♣']; // 花色：黑桃、红桃、方块、梅花
    final ranks = [
      'A',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '10',
      'J',
      'Q',
      'K'
    ]; // 牌面：A到K

    final suit = suits[_random.nextInt(suits.length)]; // 随机选择花色
    final rank = ranks[_random.nextInt(ranks.length)]; // 随机选择牌面

    // 计算百家乐点数
    int value;
    if (rank == 'A') {
      value = 1;
    } else if (['J', 'Q', 'K'].contains(rank)) {
      value = 0;
    } else {
      value = int.parse(rank);
    }

    return {
      'suit': suit, // 花色
      'rank': rank, // 牌面
      'value': value, // 百家乐点数
      'display': '$rank$suit', // 显示格式
    };
  }

  // 计算手牌总点数（百家乐规则）
  int _calculateBaccaratTotal(List<Map<String, dynamic>> cards) {
    int total = 0;
    for (var card in cards) {
      total += card['value'] as int; // 累加每张牌的点数
    }
    return total % 10; // 百家乐只取个位数，超过10则取个位数
  }

  // 百家乐发牌规则
  List<Map<String, dynamic>> _dealBaccaratCards() {
    List<Map<String, dynamic>> playerCards = [];
    List<Map<String, dynamic>> bankerCards = [];

    // 初始发牌：每人两张
    playerCards.add(_generateCard());
    bankerCards.add(_generateCard());
    playerCards.add(_generateCard());
    bankerCards.add(_generateCard());

    int playerTotal = _calculateBaccaratTotal(playerCards);
    int bankerTotal = _calculateBaccaratTotal(bankerCards);

    // 第三张牌规则
    bool playerGetsThird = playerTotal <= 5;
    bool bankerGetsThird = false;

    if (playerGetsThird) {
      playerCards.add(_generateCard());
      playerTotal = _calculateBaccaratTotal(playerCards);

      // 庄家第三张牌规则
      if (bankerTotal <= 2) {
        bankerGetsThird = true;
      } else if (bankerTotal == 3 && playerCards[2]['value'] != 8) {
        bankerGetsThird = true;
      } else if (bankerTotal == 4 &&
          [2, 3, 4, 5, 6, 7].contains(playerCards[2]['value'])) {
        bankerGetsThird = true;
      } else if (bankerTotal == 5 &&
          [4, 5, 6, 7].contains(playerCards[2]['value'])) {
        bankerGetsThird = true;
      } else if (bankerTotal == 6 && [6, 7].contains(playerCards[2]['value'])) {
        bankerGetsThird = true;
      }

      if (bankerGetsThird) {
        bankerCards.add(_generateCard());
        bankerTotal = _calculateBaccaratTotal(bankerCards);
      }
    } else if (bankerTotal <= 5) {
      bankerCards.add(_generateCard());
      bankerTotal = _calculateBaccaratTotal(bankerCards);
    }

    return [
      {'type': 'player', 'cards': playerCards, 'total': playerTotal},
      {'type': 'banker', 'cards': bankerCards, 'total': bankerTotal},
    ];
  }

  // 开始模拟
  Future<void> _startSimulation() async {
    if (_isAnimating) return;

    setState(() {
      _isAnimating = true;
      _currentResult = '发牌中...';
      _showResultArea = true; // 开始新开奖时显示结果显示区域
    });

    _animationController.forward();

    // 模拟发牌过程
    await Future.delayed(const Duration(milliseconds: 500));

    final results = _dealBaccaratCards();
    final playerResult = results[0];
    final bankerResult = results[1];

    setState(() {
      _playerCards =
          playerResult['cards'].map((card) => card['display']).join(' ');
      _bankerCards =
          bankerResult['cards'].map((card) => card['display']).join(' ');
      _playerTotal = playerResult['total'];
      _bankerTotal = bankerResult['total'];

      if (_playerTotal > _bankerTotal) {
        _winner = '闲家';
        _currentResult = '闲家胜 ($_playerTotal vs $_bankerTotal)';
      } else if (_bankerTotal > _playerTotal) {
        _winner = '庄家';
        _currentResult = '庄家胜 ($_bankerTotal vs $_playerTotal)';
      } else {
        _winner = '和局';
        _currentResult = '和局 ($_playerTotal vs $_bankerTotal)';
      }
    });

    // 添加到历史记录
    _gameHistory.insert(0, {
      'playerCards': _playerCards,
      'bankerCards': _bankerCards,
      'playerTotal': _playerTotal,
      'bankerTotal': _bankerTotal,
      'winner': _winner,
      'timestamp': DateTime.now(),
    });

    // 添加到路子图
    _roadMap.insert(0, _winner);

    // 更新大路
    _updateBigRoad(_winner);

    // 限制历史记录数量
    if (_gameHistory.length > 20) {
      _gameHistory = _gameHistory.take(20).toList();
    }

    // 限制路子图数量（显示最近50局）
    if (_roadMap.length > 50) {
      _roadMap = _roadMap.take(50).toList();
    }

    await Future.delayed(const Duration(milliseconds: 1000));

    setState(() {
      _isAnimating = false;
      _showResultArea = false; // 开奖完成后隐藏结果显示区域
    });

    _animationController.reset();
  }

  // 清空历史记录
  void _clearHistory() {
    setState(() {
      _gameHistory.clear();
      _roadMap.clear(); // 清空路子图
      _initializeBigRoad(); // 重新初始化大路
      _currentResult = '';
      _playerCards = '';
      _bankerCards = '';
      _playerTotal = 0;
      _bankerTotal = 0;
      _winner = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('百家乐开奖模拟'),
        backgroundColor: Colors.amber.shade600,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearHistory,
            tooltip: '清空历史',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade50,
              Colors.amber.shade50,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 路子图区域
              _buildRoadMap(),

              const SizedBox(height: 16),

              // 当前结果区域
              Card(
                elevation: 8,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber.shade100, Colors.amber.shade50],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '当前开奖结果',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade800,
                        ),
                      ),
                      if (_showResultArea)
                        AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _scaleAnimation.value,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32, // 缩小内边距
                                  vertical: 12, // 缩小内边距
                                ),
                                decoration: BoxDecoration(
                                  color: _winner == '闲家'
                                      ? Colors.blue.shade100
                                      : _winner == '庄家'
                                          ? Colors.red.shade100
                                          : Colors.grey.shade100,
                                  borderRadius:
                                      BorderRadius.circular(12), // 缩小圆角
                                  border: Border.all(
                                    color: _winner == '闲家'
                                        ? Colors.blue
                                        : _winner == '庄家'
                                            ? Colors.red
                                            : Colors.grey,
                                    width: 3, // 缩小边框
                                  ),
                                ),
                                child: Text(
                                  _currentResult.isEmpty
                                      ? '点击开始模拟'
                                      : _currentResult,
                                  style: TextStyle(
                                    fontSize: 24, // 缩小字体
                                    fontWeight: FontWeight.bold,
                                    color: _winner == '闲家'
                                        ? Colors.blue.shade800
                                        : _winner == '庄家'
                                            ? Colors.red.shade800
                                            : Colors.grey.shade800,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          },
                        ),
                      if (_playerCards.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                  '闲家',
                                  style: TextStyle(
                                    fontSize: 28, // 从14增大到28
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _playerCards,
                                  style:
                                      const TextStyle(fontSize: 24), // 从12增大到24
                                ),
                                Text(
                                  '点数: $_playerTotal',
                                  style: TextStyle(
                                    fontSize: 24, // 从12增大到24
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  '庄家',
                                  style: TextStyle(
                                    fontSize: 28, // 从14增大到28
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _bankerCards,
                                  style:
                                      const TextStyle(fontSize: 24), // 从12增大到24
                                ),
                                Text(
                                  '点数: $_bankerTotal',
                                  style: TextStyle(
                                    fontSize: 24, // 从12增大到24
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 开始按钮
              ElevatedButton.icon(
                onPressed: _isAnimating ? null : _startSimulation,
                icon: _isAnimating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.casino),
                label: Text(_isAnimating ? '模拟中...' : '开始模拟'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 历史记录
              if (_gameHistory.isNotEmpty) ...[
                Text(
                  '历史记录 (最近${_gameHistory.length}局)',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...(_gameHistory.map((game) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: game['winner'] == '闲家'
                                              ? Colors.blue.shade100
                                              : game['winner'] == '庄家'
                                                  ? Colors.red.shade100
                                                  : Colors.grey.shade100,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          game['winner'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: game['winner'] == '闲家'
                                                ? Colors.blue.shade800
                                                : game['winner'] == '庄家'
                                                    ? Colors.red.shade800
                                                    : Colors.grey.shade800,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${game['playerTotal']} vs ${game['bankerTotal']}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '闲: ${game['playerCards']}',
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                  Text(
                                    '庄: ${game['bankerCards']}',
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${game['timestamp'].hour.toString().padLeft(2, '0')}:${game['timestamp'].minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ))),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // 构建大路
  Widget _buildRoadMap() {
    bool hasData = _bigRoad.any((row) => row.any((cell) => cell.isNotEmpty));

    if (!hasData) {
      return Card(
        elevation: 4,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                '大路',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '暂无数据',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '大路',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                Row(
                  children: [
                    _buildLegendItem('闲家', Colors.blue),
                    const SizedBox(width: 12),
                    _buildLegendItem('庄家', Colors.red),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 大路网格
            _buildBigRoadGrid(),
          ],
        ),
      ),
    );
  }

  // 构建图例项
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // 构建大路网格
  Widget _buildBigRoadGrid() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          children: _bigRoad
              .map(
                (row) => Row(
                  children: row
                      .map(
                        (cell) => Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Colors.grey.shade300, width: 0.5),
                          ),
                          child: Center(
                            child:
                                cell.isEmpty ? null : _buildBigRoadItem(cell),
                          ),
                        ),
                      )
                      .toList(),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  // 构建大路项目
  Widget _buildBigRoadItem(String result) {
    Color color;
    String text;

    switch (result) {
      case '闲家':
        color = Colors.blue;
        text = 'P';
        break;
      case '庄家':
        color = Colors.red;
        text = 'B';
        break;
      default:
        color = Colors.grey;
        text = '';
    }

    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
