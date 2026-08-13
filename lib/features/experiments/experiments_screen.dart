import 'package:flutter/material.dart';
import '../../data/local_store.dart';

class ExperimentsScreen extends StatelessWidget {
  const ExperimentsScreen({super.key, required this.store});
  final LocalStore store;
  @override
  Widget build(BuildContext context) => SafeArea(
          child: ListView(padding: const EdgeInsets.all(20), children: [
        Text('实验',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        if (store.experiments.isEmpty)
          const Text('暂无实验')
        else
          ...store.experiments.map((e) => Card(
              child: ListTile(
                  leading: CircleAvatar(backgroundColor: e.color),
                  title: Text(e.name),
                  subtitle: Text(
                      '${e.steps.where((s) => s.status.name == 'completed').length} / ${e.steps.length} steps'),
                  trailing: const Icon(Icons.chevron_right))))
      ]));
}
