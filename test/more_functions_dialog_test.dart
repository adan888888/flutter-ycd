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
  '7.备份数据',
  '8.重启系统',
  '9.修改期望值',
  '10.修改赔率',
  '11.退出程序',
  '12.显示序号',
  '13.红输绿赢',
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
  testWidgets('keeps all thirteen function indexes unchanged', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (var index = 0; index < _functionTypes.length; index++) {
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

    await _scrollToFunction(tester, 10);
    final colorRuleItem = find.byKey(const ValueKey('more-function-12'));
    final logoutItem = find.byKey(const ValueKey('more-function-10'));
    expect(tester.getTopLeft(colorRuleItem).dy,
        lessThan(tester.getTopLeft(logoutItem).dy));
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
