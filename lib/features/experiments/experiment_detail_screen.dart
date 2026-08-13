import 'package:flutter/material.dart';

import '../../data/local_store.dart';
import 'checklist_screen.dart';
import 'experiment_factory.dart';
import 'models.dart';

class ExperimentDetailScreen extends StatefulWidget {
  const ExperimentDetailScreen(
      {super.key, required this.experiment, required this.store});

  final ExperimentInstance experiment;
  final LocalStore store;

  @override
  State<ExperimentDetailScreen> createState() => _ExperimentDetailScreenState();
}

class _ExperimentDetailScreenState extends State<ExperimentDetailScreen> {
  Future<void> _save() async {
    setState(() {});
    await widget.store.save();
  }

  @override
  Widget build(BuildContext context) {
    final experiment = widget.experiment;
    final completed = experiment.steps
        .where((step) => step.status == StepStatus.completed)
        .length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('实验详情'),
        actions: [
          IconButton(
              tooltip: '编辑实验名称',
              onPressed: _editExperiment,
              icon: const Icon(Icons.edit_outlined))
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                          width: 10,
                          height: 44,
                          decoration: BoxDecoration(
                              color: experiment.color,
                              borderRadius: BorderRadius.circular(8))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(experiment.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w800)))
                    ]),
                    const SizedBox(height: 12),
                    Text('开始日期：${_date(experiment.startedAt)}'),
                    const SizedBox(height: 4),
                    Text(
                        '${_domain(experiment.domain)} · $completed / ${experiment.steps.length} 步骤已完成'),
                    if (experiment.project.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(experiment.project)
                    ],
                  ]),
            ),
          ),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(
                child: Text('实验步骤',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800))),
            Text('${experiment.steps.length} 步骤')
          ]),
          const SizedBox(height: 10),
          ...experiment.steps.asMap().entries.map((entry) => _StepCard(
                number: entry.key + 1,
                step: entry.value,
                experiment: experiment,
                store: widget.store,
                onEdit: () => _editStep(entry.value),
                onChanged: _save,
              )),
          const SizedBox(height: 8),
          OutlinedButton.icon(
              onPressed: _addStep,
              icon: const Icon(Icons.add),
              label: const Text('添加步骤')),
        ],
      ),
    );
  }

  Future<void> _editExperiment() async {
    final name = TextEditingController(text: widget.experiment.name);
    final notes = TextEditingController(text: widget.experiment.project);
    final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('编辑实验'),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: '实验名称')),
                const SizedBox(height: 10),
                TextField(
                    controller: notes,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: '实验设计 / 备注'))
              ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('取消')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('保存'))
              ],
            ));
    if (accepted != true || name.text.trim().isEmpty) return;
    widget.experiment.name = name.text.trim();
    widget.experiment.project = notes.text.trim();
    await _save();
  }

  Future<void> _addStep() async {
    final last = widget.experiment.steps.isEmpty
        ? widget.experiment.startedAt
        : widget.experiment.steps.last.plannedAt;
    final step = ExperimentStep(
        id: 'step-${DateTime.now().microsecondsSinceEpoch}',
        experimentId: widget.experiment.id,
        title: '新步骤',
        description: '',
        stepType: StepType.operation,
        plannedAt: last.add(const Duration(hours: 1)),
        timeMode: TimeMode.absolute);
    final accepted = await _showStepEditor(step, isNew: true);
    if (!accepted) return;
    widget.experiment.steps.add(step);
    widget.experiment.steps.sort((a, b) => a.plannedAt.compareTo(b.plannedAt));
    await _save();
  }

  Future<void> _editStep(ExperimentStep step) async {
    final accepted = await _showStepEditor(step);
    if (accepted) {
      widget.experiment.steps
          .sort((a, b) => a.plannedAt.compareTo(b.plannedAt));
      await _save();
    }
  }

  Future<bool> _showStepEditor(ExperimentStep step,
      {bool isNew = false}) async {
    final title = TextEditingController(text: step.title);
    final description = TextEditingController(text: step.description);
    final notes = TextEditingController(text: step.notes);
    var type = step.stepType;
    var date = step.plannedAt;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isNew ? '添加步骤' : '编辑步骤'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: '步骤名称')),
              const SizedBox(height: 10),
              TextField(
                  controller: description,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: '说明')),
              const SizedBox(height: 10),
              DropdownButtonFormField<StepType>(
                initialValue: type,
                decoration: const InputDecoration(labelText: '步骤类型'),
                items: StepType.values
                    .map((value) => DropdownMenuItem(
                        value: value, child: Text(_stepType(value))))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setDialogState(() => type = value);
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule),
                title: Text('${_date(date)} ${_time(date)}'),
                subtitle: const Text('计划日期与时间'),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100));
                  if (pickedDate == null || !context.mounted) return;
                  final pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(date));
                  if (pickedTime == null) return;
                  setDialogState(() => date = DateTime(
                      pickedDate.year,
                      pickedDate.month,
                      pickedDate.day,
                      pickedTime.hour,
                      pickedTime.minute));
                },
              ),
              TextField(
                  controller: notes,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: '步骤备注')),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消')),
            FilledButton(
                onPressed: () {
                  if (title.text.trim().isEmpty) return;
                  step.title = title.text.trim();
                  step.description = description.text.trim();
                  step.notes = notes.text.trim();
                  step.stepType = type;
                  step.plannedAt = date;
                  Navigator.pop(context, true);
                },
                child: const Text('保存')),
          ],
        ),
      ),
    );
    return accepted ?? false;
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard(
      {required this.number,
      required this.step,
      required this.experiment,
      required this.store,
      required this.onEdit,
      required this.onChanged});
  final int number;
  final ExperimentStep step;
  final ExperimentInstance experiment;
  final LocalStore store;
  final VoidCallback onEdit;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final complete = step.status == StepStatus.completed;
    final checklistDone = step.checklist.where((item) => item.isDone).length;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: experiment.color.withValues(alpha: .55),
                    borderRadius: BorderRadius.circular(12)),
                child: Text('$number',
                    style: const TextStyle(fontWeight: FontWeight.w800))),
            const SizedBox(width: 12),
            Expanded(
                child: Text(step.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        decoration:
                            complete ? TextDecoration.lineThrough : null))),
            IconButton(
                tooltip: '编辑步骤',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined)),
            IconButton(
                tooltip: complete ? '已完成' : '完成步骤',
                onPressed: complete
                    ? null
                    : () {
                        completeStep(experiment, step);
                        onChanged();
                      },
                icon: Icon(complete
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked),
                color: complete ? const Color(0xFF467D65) : null),
          ]),
          Padding(
              padding: const EdgeInsets.only(left: 54),
              child: Text(
                  '${_date(step.plannedAt)} ${_time(step.plannedAt)} · ${_stepType(step.stepType)}',
                  style: const TextStyle(color: Color(0xFF737C78)))),
          if (step.description.isNotEmpty)
            Padding(
                padding: const EdgeInsets.only(left: 54, top: 7),
                child: Text(step.description)),
          if (step.notes.isNotEmpty)
            Padding(
                padding: const EdgeInsets.only(left: 54, top: 7),
                child: Text('备注：${step.notes}',
                    style: const TextStyle(color: Color(0xFF66716C)))),
          if (step.checklist.isNotEmpty) ...[
            const SizedBox(height: 10),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            ChecklistScreen(step: step, store: store)));
                onChanged();
              },
              child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: const Color(0xFFF7F5F2),
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    const Icon(Icons.checklist, color: Color(0xFFBF7C76)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          const Text('物品准备清单',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          Text('$checklistDone / ${step.checklist.length} 已准备',
                              style: Theme.of(context).textTheme.bodySmall)
                        ])),
                    const Icon(Icons.chevron_right)
                  ])),
            ),
          ] else if (number == 1) ...[
            const SizedBox(height: 8),
            TextButton.icon(
                onPressed: () async {
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              ChecklistScreen(step: step, store: store)));
                  onChanged();
                },
                icon: const Icon(Icons.add),
                label: const Text('添加物品准备清单')),
          ],
        ]),
      ),
    );
  }
}

String _date(DateTime value) =>
    '${value.year}/${value.month.toString().padLeft(2, '0')}/${value.day.toString().padLeft(2, '0')}';
String _time(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
String _domain(ExperimentDomain value) => switch (value) {
      ExperimentDomain.biological => '生物实验',
      ExperimentDomain.animal => '动物实验',
      ExperimentDomain.custom => '自定义实验'
    };
String _stepType(StepType value) => switch (value) {
      StepType.operation => '操作',
      StepType.observation => '观察',
      StepType.incubation => '培养 / 孵育',
      StepType.timer => '计时',
      StepType.calculation => '计算',
      StepType.instrument => '仪器',
      StepType.result => '结果'
    };
