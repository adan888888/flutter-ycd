import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ycd/my_widget/more_functions_dialog.dart';

const _functionTypes = <String>[
  '1.排列数据',
  '2.消除数据',
  '3.修改本金',
  '4.修改位置',
  '5.删除所有数据',
  '6.重置流水',
  '7.分享给朋友',
  '8.返回上步',
  '9.修改期望值',
  '10.修改赔率',
  '11.退出程序',
  '12.显示序号',
  '13.红输绿赢',
  '14.关闭自动主题',
  '15.隐藏消数列',
  '16.隐藏快照列',
];

Widget _buildHarness({
  required bool isDarkMode,
  required ValueChanged<int> onSelected,
}) {
  return MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            key: const ValueKey('open-more-functions'),
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (_) => MoreFunctionsDialog(
                  isDarkMode: isDarkMode,
                  functionTypes: _functionTypes,
                  onSelected: onSelected,
                ),
              );
            },
            child: const Text('打开'),
          ),
        ),
      ),
    ),
  );
}

Future<void> _openDialog(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('open-more-functions')));
  await tester.pumpAndSettle();
}

Future<void> _scrollToFunction(WidgetTester tester, int index) async {
  final item = find.byKey(ValueKey('more-function-$index'));
  final scrollable = find.descendant(
    of: find.byKey(const ValueKey('more-functions-list')),
    matching: find.byType(Scrollable),
  );
  await tester.scrollUntilVisible(item, 220, scrollable: scrollable);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('keeps all function indexes unchanged', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (var index = 0; index < _functionTypes.length; index++) {
      if (index == 2 || index == 3 || index == 5 || index == 8 || index == 9) continue;
      int? selectedIndex;
      var callCount = 0;
      await tester.pumpWidget(
        _buildHarness(
          isDarkMode: false,
          onSelected: (value) {
            selectedIndex = value;
            callCount++;
          },
        ),
      );

      await _openDialog(tester);
      await _scrollToFunction(tester, index);
      await tester.tap(find.byKey(ValueKey('more-function-$index')));
      await tester.pumpAndSettle();

      expect(selectedIndex, index);
      expect(callCount, 1);
      expect(find.byKey(const ValueKey('more-functions-dialog')), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('close button dismisses without running a function',
      (tester) async {
    var callCount = 0;
    await tester.pumpWidget(
      _buildHarness(
        isDarkMode: false,
        onSelected: (_) => callCount++,
      ),
    );

    await _openDialog(tester);
    await tester.tap(find.byKey(const ValueKey('more-functions-close')));
    await tester.pumpAndSettle();

    expect(callCount, 0);
    expect(find.byKey(const ValueKey('more-functions-dialog')), findsNothing);
  });

  testWidgets('shows restart first and logout last', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _buildHarness(
        isDarkMode: false,
        onSelected: (_) {},
      ),
    );
    await _openDialog(tester);

    final restartItem = find.byKey(const ValueKey('more-function-7'));
    final sortItem = find.byKey(const ValueKey('more-function-0'));
    expect(tester.getTopLeft(restartItem).dy,
        lessThan(tester.getTopLeft(sortItem).dy));

    await _scrollToFunction(tester, 11);
    final seqItem = find.byKey(const ValueKey('more-function-11'));
    final xiaoshuItem = find.byKey(const ValueKey('more-function-14'));
    final snapshotItem = find.byKey(const ValueKey('more-function-15'));
    expect(tester.getTopLeft(seqItem).dy, lessThan(tester.getTopLeft(xiaoshuItem).dy));
    expect(tester.getTopLeft(xiaoshuItem).dy, lessThan(tester.getTopLeft(snapshotItem).dy));

    await _scrollToFunction(tester, 10);
    final colorRuleItem = find.byKey(const ValueKey('more-function-12'));
    final logoutItem = find.byKey(const ValueKey('more-function-10'));
    expect(tester.getTopLeft(colorRuleItem).dy,
        lessThan(tester.getTopLeft(logoutItem).dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('search filters by title and description', (tester) async {
    int? selectedIndex;
    await tester.pumpWidget(
      _buildHarness(
        isDarkMode: false,
        onSelected: (value) => selectedIndex = value,
      ),
    );
    await _openDialog(tester);

    final search = find.byKey(const ValueKey('more-functions-search'));
    await tester.enterText(search, '快照');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('more-function-15')), findsOneWidget);
    expect(find.byKey(const ValueKey('more-function-14')), findsNothing);
    expect(find.byKey(const ValueKey('more-function-7')), findsNothing);

    await tester.enterText(search, '本金');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('more-function-2')), findsNothing);
    expect(find.byKey(const ValueKey('more-functions-empty')), findsOneWidget);

    await tester.enterText(search, '位置');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('more-function-3')), findsNothing);
    expect(find.byKey(const ValueKey('more-functions-empty')), findsOneWidget);

    await tester.enterText(search, '赔率');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('more-function-9')), findsNothing);
    expect(find.byKey(const ValueKey('more-functions-empty')), findsOneWidget);

    await tester.enterText(search, '期望');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('more-function-8')), findsNothing);
    expect(find.byKey(const ValueKey('more-functions-empty')), findsOneWidget);

    await tester.enterText(search, '流水');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('more-function-5')), findsNothing);
    expect(find.byKey(const ValueKey('more-functions-empty')), findsOneWidget);

    await tester.enterText(search, '分享');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('more-function-6')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('more-function-6')));
    await tester.pumpAndSettle();
    expect(selectedIndex, 6);

    await _openDialog(tester);
    await tester.enterText(search, '不存在的功能');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('more-functions-empty')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('more-functions-search-clear')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('more-function-7')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pinyin fuzzy search matches initials and full spelling',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _buildHarness(
        isDarkMode: false,
        onSelected: (_) {},
      ),
    );
    await _openDialog(tester);
    final search = find.byKey(const ValueKey('more-functions-search'));

    await tester.enterText(search, 'x');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('more-functions-empty')), findsNothing);
    expect(find.byKey(const ValueKey('more-function-1')), findsOneWidget);
    await _scrollToFunction(tester, 11);
    expect(find.byKey(const ValueKey('more-function-11')), findsOneWidget);

    await tester.enterText(search, 'xs');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('more-function-11')), findsOneWidget);

    await tester.enterText(search, 'xianshi');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('more-function-11')), findsOneWidget);
    expect(find.byKey(const ValueKey('more-function-1')), findsNothing);

    await tester.enterText(search, 'fhsb');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('more-function-7')), findsOneWidget);

    await tester.enterText(search, 'benjin');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('more-function-2')), findsNothing);
    expect(find.byKey(const ValueKey('more-functions-empty')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses separate light and dark surfaces', (tester) async {
    Future<Color?> pumpSurface(bool isDarkMode) async {
      await tester.pumpWidget(
        _buildHarness(
          isDarkMode: isDarkMode,
          onSelected: (_) {},
        ),
      );
      await _openDialog(tester);
      final material = tester.widget<Material>(
        find.byKey(const ValueKey('more-functions-surface')),
      );
      final color = material.color;
      await tester.tap(find.byKey(const ValueKey('more-functions-close')));
      await tester.pumpAndSettle();
      return color;
    }

    expect(await pumpSurface(false), Colors.white);
    expect(await pumpSurface(true), const Color(0xFF16212F));
  });
}
