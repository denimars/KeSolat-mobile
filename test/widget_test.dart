import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kesholat/main.dart';

void main() {
  testWidgets('App should start without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const KeSholatApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
