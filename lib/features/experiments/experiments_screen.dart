import 'package:flutter/material.dart';

import '../../data/local_store.dart';
import 'experiment_detail_screen.dart';
import 'models.dart';

class ExperimentsScreen extends StatefulWidget {
  const ExperimentsScreen({super.key, required this.store});
  final LocalStore store;

  @override
  State<ExperimentsScreen> createState() => _ExperimentsScreenState();
}

class _ExperimentsScreenState extends State<ExperimentsScreen> {
  @override
  Widget build(BuildContext context) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('实验',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('点击实验查看和编辑全部步骤'),
            const SizedBox(height: 16),
            if (widget.store.experiments.isEmpty)
              const Card(
                  child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('暂无实验，请从“今日”添加实验'))))
            else
              ...widget.store.experiments.map((experiment) {
                final completed = experiment.steps
                    .where((step) => step.status == StepStatus.completed)
                    .length;
                return Card(
                  margin: const EdgeInsets.only(bottom: 9),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    leading: CircleAvatar(
                        backgroundColor: experiment.color,
                        child: const Icon(Icons.science_outlined)),
                    title: Text(experiment.name,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                        '$completed / ${experiment.steps.length} 步骤 · ${_domain(experiment.domain)}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ExperimentDetailScreen(
                                  experiment: experiment,
                                  store: widget.store)));
                      if (mounted) setState(() {});
                    },
                  ),
                );
              }),
          ],
        ),
      );
}

String _domain(ExperimentDomain domain) => switch (domain) {
      ExperimentDomain.biological => '生物实验',
      ExperimentDomain.animal => '动物实验',
      ExperimentDomain.custom => '自定义实验',
    };
