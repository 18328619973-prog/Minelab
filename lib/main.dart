import 'package:flutter/material.dart';
import 'app/app.dart';
import 'data/local_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = LocalStore();
  await store.load();
  runApp(MineLabApp(store: store));
}
