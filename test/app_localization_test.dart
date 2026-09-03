import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ycd/main.dart';

void main() {
  testWidgets('provides Chinese labels for the iOS text editing menu',
      (tester) async {
    late BuildContext localizedContext;

    await tester.pumpWidget(
      MaterialApp(
        locale: appLocale,
        supportedLocales: appSupportedLocales,
        localizationsDelegates: appLocalizationsDelegates,
        home: Builder(
          builder: (context) {
            localizedContext = context;
            return const CupertinoTextField();
          },
        ),
      ),
    );

    final localizations = CupertinoLocalizations.of(localizedContext);
    expect(localizations.pasteButtonLabel, '粘贴');
    expect(localizations.selectAllButtonLabel, '全选');
  });
}
