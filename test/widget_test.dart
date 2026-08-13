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
  testWidgets('MineLab opens on the daily dashboard',
      (WidgetTester tester) async {
    await tester.pumpWidget(MineLabApp(store: LocalStore()));
    expect(find.text('MineLab'), findsOneWidget);
    expect(find.text('日程安排'), findsOneWidget);
    expect(find.text('这一天还没有实验安排'), findsOneWidget);
    expect(find.text('CCK-8 / 细胞活性'), findsNothing);
  });

  testWidgets('experiment picker separates biological and animal templates',
      (WidgetTester tester) async {
    await tester.pumpWidget(MineLabApp(store: LocalStore()));
    await tester.tap(find.text('添加实验').first);
    await tester.pumpAndSettle();
    expect(find.text('生物实验'), findsOneWidget);
    expect(find.text('动物实验'), findsOneWidget);
    expect(find.text('我的模板'), findsOneWidget);
    expect(find.text('CCK-8 / 细胞活性'), findsOneWidget);
    await tester.tap(find.text('动物实验'));
    await tester.pumpAndSettle();
    expect(find.text('动物实验项目'), findsOneWidget);
    expect(find.textContaining('伦理审批'), findsOneWidget);
  });
}
