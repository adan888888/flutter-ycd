import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ycd/views/login/login_viw_widget/login_controller.dart';
import 'package:ycd/views/login/login_viw_widget/login_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    Get.put(LoginController());
  });

  tearDown(Get.reset);

  testWidgets('moves only as needed and returns without a rebound',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
    tester.view.viewPadding = const FakeViewPadding(top: 47, bottom: 34);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(
      const ScreenUtilInit(
        designSize: Size(360, 690),
        minTextAdapt: true,
        child: GetMaterialApp(home: LoginWidget()),
      ),
    );
    await tester.pumpAndSettle();

    const layoutKey = ValueKey('login-content-layout');
    const contentKey = ValueKey('login-content');
    final closedContentTop = tester.getTopLeft(find.byKey(contentKey)).dy;
    expect(find.byKey(layoutKey), findsOneWidget);

    tester.view.padding = const FakeViewPadding(top: 47);
    tester.view.viewInsets = const FakeViewPadding(bottom: 100);
    await tester.pump();
    expect(
      tester.getTopLeft(find.byKey(contentKey)).dy,
      closeTo(closedContentTop, 0.01),
    );

    tester.view.viewInsets = const FakeViewPadding(bottom: 330);
    await tester.pump();

    final openContentRect = tester.getRect(find.byKey(contentKey));
    final passwordRect = tester.getRect(find.byType(TextFormField).last);
    const keyboardTop = 844.0 - 330.0;

    expect(openContentRect.top, lessThan(closedContentTop));
    expect(openContentRect.top, greaterThan(0));
    expect(passwordRect.bottom, lessThan(keyboardTop));
    expect(tester.takeException(), isNull);

    var previousTop = openContentRect.top;
    for (final inset in <double>[250, 150, 50, 0]) {
      tester.view.padding = FakeViewPadding(
        top: 47,
        bottom: inset < 34 ? 34 - inset : 0,
      );
      tester.view.viewInsets = FakeViewPadding(bottom: inset);
      await tester.pump();

      final currentTop = tester.getTopLeft(find.byKey(contentKey)).dy;
      expect(currentTop, greaterThanOrEqualTo(previousTop));
      expect(currentTop, lessThanOrEqualTo(closedContentTop));
      previousTop = currentTop;
    }

    expect(
      tester.getTopLeft(find.byKey(contentKey)).dy,
      closeTo(closedContentTop, 0.01),
    );
  });

  testWidgets('keeps every login action reachable on a small screen',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(
      const ScreenUtilInit(
        designSize: Size(360, 690),
        minTextAdapt: true,
        child: GetMaterialApp(home: LoginWidget()),
      ),
    );
    await tester.pumpAndSettle();

    final scrollView = find.byKey(const ValueKey('login-scroll-view'));
    final scrollable = find.descendant(
      of: scrollView,
      matching: find.byType(Scrollable),
    );
    final serviceEntry = find.text('联系客服');

    expect(scrollView, findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      serviceEntry,
      80,
      scrollable: scrollable.first,
    );
    await tester.pumpAndSettle();

    expect(tester.getRect(serviceEntry).bottom, lessThanOrEqualTo(340));
    expect(tester.takeException(), isNull);
  });
}
