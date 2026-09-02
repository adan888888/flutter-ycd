import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ycd/views/ji_shu_qi/ji_shu_qi_view.dart';

void main() {
  testWidgets('empty betting image appears only after initial loading finishes',
      (tester) async {
    Future<void> pumpEmptyState({required bool isInitialDataLoading}) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JiShuQiBettingListEmptyState(
              isInitialDataLoading: isInitialDataLoading,
            ),
          ),
        ),
      );
    }

    await pumpEmptyState(isInitialDataLoading: true);
    expect(find.byType(Image), findsNothing);

    await pumpEmptyState(isInitialDataLoading: false);
    expect(find.byType(Image), findsOneWidget);
  });
}
