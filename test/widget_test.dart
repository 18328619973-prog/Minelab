// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:minelab/app/app.dart';
import 'package:minelab/data/local_store.dart';

void main() {
  testWidgets('MineLab opens on the daily dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(MineLabApp(store: LocalStore()));
    expect(find.text('MineLab'), findsOneWidget);
    expect(find.text('今日时间轴'), findsOneWidget);
    expect(find.text('创建 CCK-8 演示实验'), findsOneWidget);
  });
}
