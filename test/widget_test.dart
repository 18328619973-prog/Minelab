import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minelab/app/app.dart';
import 'package:minelab/data/local_store.dart';

void main() {
  testWidgets('MineLab opens on the daily dashboard', (tester) async {
    await tester.pumpWidget(MineLabApp(store: LocalStore()));
    expect(find.text('MineLab'), findsOneWidget);
    expect(find.text('日程安排'), findsOneWidget);
    expect(find.text('这一天还没有实验安排'), findsOneWidget);
    expect(find.text('CCK-8 / 细胞活性'), findsNothing);
  });

  testWidgets('experiment picker separates biological and animal templates',
      (tester) async {
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

  testWidgets('created experiment opens steps and preparation checklist',
      (tester) async {
    final store = LocalStore();
    await tester.pumpWidget(MineLabApp(store: store));
    await tester.tap(find.text('添加实验').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('CCK-8 / 细胞活性'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('物品准备').first);
    await tester.pumpAndSettle();
    expect(find.text('实验步骤'), findsOneWidget);
    expect(find.text('物品准备清单'), findsOneWidget);
    await tester.tap(find.text('物品准备清单'));
    await tester.pumpAndSettle();
    expect(find.text('细胞与培养板'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('添加准备项'), 260);
    expect(find.text('添加准备项'), findsOneWidget);
    await tester.tap(find.text('添加准备项'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, '名称'), '本次自定义物品');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('本次自定义物品'), findsOneWidget);
  });
}
