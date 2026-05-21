// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:service_marketplace/main.dart';

void main() {
  testWidgets('Map based app renders', (WidgetTester tester) async {
    await tester.pumpWidget(const ServiceHubApp());
    await tester.pumpAndSettle();

    expect(find.text('我需要服務'), findsOneWidget);
    await tester.tap(find.text('我需要服務'));
    await tester.pumpAndSettle();

    expect(find.text('熱門分類'), findsOneWidget);
    expect(find.text('髮型屋'), findsWidgets);
    await tester.tap(find.text('髮型屋').first);
    await tester.pumpAndSettle();

    expect(find.text('附近可用服務'), findsOneWidget);
    expect(find.text('髮型屋'), findsWidgets);
  });
}
