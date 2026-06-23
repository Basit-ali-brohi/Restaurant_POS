// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_pos/main.dart';

void main() {
  testWidgets('NeoDiningApp renders dashboard navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: NeoDiningApp()));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Tables'), findsOneWidget);
    expect(find.text('Menu'), findsOneWidget);
    expect(find.text('KDS'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
