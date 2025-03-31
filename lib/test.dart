import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'my_widget/baccarat_road_map.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ScrollController _scrollController = ScrollController();
  final ScrollController scrollController1 = ScrollController(); //路子图的controller

  // 模拟大路图数据：B表示庄，P表示闲
  final List<String> results = [
    "B", "B", "B", "B", "B", "B", "B", "B", "B", "B", "B", // 庄连续超过6个  8个
    "P", "P", "P", "P", "P", "P", "P", "P", "P", "P", "P", "P", "P", // 闲连续  6个
    "B", "P", "B", "P", "B", "P", // 庄闲交替
    // "B", "B", "P", "P", "B", "B", "B", "B", "B", "B", "B", "B", "B", "B", "B", "B", "B", // 庄连续超过6个  8个
    // "P", "P", "P", "P", "P", "P", "P", "P", "P", "P", "P", "P", "P", // 闲连续  6个
    // "B", "P", "B", "P", "B", "P", // 庄闲交替
    // "B", "B", "P", "P", "B", "B", // 规则混合
    // "B", "B", "B", "B", "B", "B", "B", "B", "B", "B", "B", // 庄连续超过6个  8个
    // "P", "P", "P", "P", "P", "P", "P", "P", "P", "P", "P", "P", "P", // 闲连续  6个
    // "B", "P", "B", "P", "B", "P", // 庄闲交替
    // "B", "B", "P", "P", "B", "B", "B", "B", "B", "B", "B", "B", "B", "B", "B", "B", "B", // 庄连续超过6个  8个
    // "P", "P", "P", "P", "P", "P", "P", "P", "P", "P", "P", "P", "P", // 闲连续  6个
    // "B", "P", "B", "P", "B", "P", // 庄闲交替
    // "B", "B", "P", "P", "B", "B", // 规则混合
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        print('已经滚动到了底部');
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Scroll to Bottom Example'),
        ),
        body: Column(
          children: [
            SizedBox(
              height: 78,
              width: double.infinity,
              child: BaccaratRoadMap(
                results: results,
                scrollController: scrollController1,
              ),
            ),
            Row(
              children: [
                ColoredBox(
                    color: Colors.yellow,
                    child: TextButton(
                        onPressed: () => setState(() {
                              results.add("P");
                            }),
                        child: Text("增加P"))),
                const Spacer(),
                ColoredBox(
                    color: Colors.yellow,
                    child: TextButton(
                        onPressed: () => setState(() {
                              results.add("B");
                            }),
                        child: Text("增加B")))
              ],
            )
          ],
        ),
      ),
    );
  }
}
