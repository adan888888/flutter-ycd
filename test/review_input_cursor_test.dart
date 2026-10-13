import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ycd/my_widget/review_approved_dialog.dart';

void main() {
  testWidgets('places the cursor immediately left of the slash', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (_) => ReviewInputDialog(
                    title: '修改位置',
                    message: '',
                    badgeText: '当前 11/11',
                    hintText: '例如 11/11',
                    initialValue: '11/11',
                    cursorBefore: '/',
                    onSubmitted: (_) {},
                  ),
                );
              },
              child: const Text('打开'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, '11/11');
    expect(field.controller!.selection.isCollapsed, isTrue);
    expect(field.controller!.selection.extentOffset, '11/11'.indexOf('/'));
  });
}
