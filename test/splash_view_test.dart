import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ycd/views/splash/splash_view.dart';

void main() {
  testWidgets('shows the full launch image and honors the minimum display time',
      (tester) async {
    var bootstrapCalls = 0;
    var finished = false;

    await tester.pumpWidget(
      MaterialApp(
        home: SplashView(
          bootstrap: () async => bootstrapCalls++,
          firstFrameReady: () async {},
          onFinished: () => finished = true,
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, const AssetImage(SplashView.imageAsset));
    expect(image.fit, BoxFit.fill);
    expect(bootstrapCalls, 1);

    await tester.pump(const Duration(milliseconds: 599));
    expect(finished, isFalse);

    await tester.pump(const Duration(milliseconds: 1));
    expect(finished, isTrue);
  });

  testWidgets('does not leave the splash before bootstrap completes',
      (tester) async {
    final bootstrap = Completer<void>();
    var finished = false;

    await tester.pumpWidget(
      MaterialApp(
        home: SplashView(
          bootstrap: () => bootstrap.future,
          firstFrameReady: () async {},
          onFinished: () => finished = true,
          minimumDisplayDuration: const Duration(milliseconds: 100),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 200));
    expect(finished, isFalse);

    bootstrap.complete();
    await tester.pump();
    expect(finished, isTrue);
  });

  testWidgets('starts bootstrap once and ignores completion after disposal',
      (tester) async {
    final bootstrap = Completer<void>();
    var bootstrapCalls = 0;
    var finished = false;

    Widget buildSplash() {
      return MaterialApp(
        home: SplashView(
          bootstrap: () {
            bootstrapCalls++;
            return bootstrap.future;
          },
          firstFrameReady: () async {},
          onFinished: () => finished = true,
          minimumDisplayDuration: Duration.zero,
        ),
      );
    }

    await tester.pumpWidget(buildSplash());
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpWidget(buildSplash());
    expect(bootstrapCalls, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    bootstrap.complete();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(finished, isFalse);
  });

  testWidgets('starts the minimum display time after the first visible frame',
      (tester) async {
    final firstFrame = Completer<void>();
    var finished = false;

    await tester.pumpWidget(
      MaterialApp(
        home: SplashView(
          bootstrap: () async {},
          firstFrameReady: () => firstFrame.future,
          onFinished: () => finished = true,
          minimumDisplayDuration: const Duration(milliseconds: 600),
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 1));
    expect(finished, isFalse);

    firstFrame.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 599));
    expect(finished, isFalse);

    await tester.pump(const Duration(milliseconds: 1));
    expect(finished, isTrue);
  });

  testWidgets('stays on splash after bootstrap failure and can retry',
      (tester) async {
    var bootstrapCalls = 0;
    var finished = false;
    final originalOnError = FlutterError.onError;
    final reportedErrors = <FlutterErrorDetails>[];
    FlutterError.onError = reportedErrors.add;
    addTearDown(() => FlutterError.onError = originalOnError);

    await tester.pumpWidget(
      MaterialApp(
        home: SplashView(
          bootstrap: () async {
            bootstrapCalls++;
            if (bootstrapCalls == 1) throw StateError('bootstrap failed');
          },
          firstFrameReady: () async {},
          onFinished: () => finished = true,
          minimumDisplayDuration: Duration.zero,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();

    expect(finished, isFalse);
    expect(reportedErrors, hasLength(1));
    expect(find.text('初始化失败，请重试'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);

    await tester.tap(find.text('重试'));
    await tester.pump();
    await tester.pump();

    expect(bootstrapCalls, 2);
    expect(finished, isTrue);
  });
}
