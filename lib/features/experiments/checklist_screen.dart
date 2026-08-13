import 'package:flutter/material.dart';

import '../../data/local_store.dart';
import 'models.dart';

class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({super.key, required this.step, required this.store});

  final ExperimentStep step;
  final LocalStore store;

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  Future<void> _save() async {
    setState(() {});
    await widget.store.save();
  }

  @override
  Widget build(BuildContext context) {
    final done = widget.step.checklist.where((item) => item.isDone).length;
    return Scaffold(
      appBar: AppBar(title: const Text('物品准备清单')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.step.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text('$done / ${widget.step.checklist.length} 已准备'),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                        value: widget.step.checklist.isEmpty
                            ? 0
                            : done / widget.step.checklist.length),
                  ]),
            ),
          ),
          const SizedBox(height: 12),
          if (widget.step.checklist.isEmpty)
            const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('暂无准备项，可点击下方按钮添加')))
          else
            ...widget.step.checklist.map((item) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Checkbox(
                        value: item.isDone,
                        onChanged: (value) {
                          item.isDone = value ?? false;
                          _save();
                        }),
                    title: Text(item.title,
                        style: TextStyle(
                            decoration: item.isDone
                                ? TextDecoration.lineThrough
                                : null)),
                    subtitle: item.details.isEmpty ? null : Text(item.details),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') _edit(item);
                        if (value == 'delete') {
                          widget.step.checklist.remove(item);
                          _save();
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('编辑')),
                        PopupMenuItem(value: 'delete', child: Text('删除'))
                      ],
                    ),
                    onTap: () => _edit(item),
                  ),
                )),
          const SizedBox(height: 8),
          OutlinedButton.icon(
              onPressed: () => _edit(null),
              icon: const Icon(Icons.add),
              label: const Text('添加准备项')),
          const SizedBox(height: 16),
          const Text('模板清单是可编辑的起点，请根据本次实验、实验室 SOP 与实际物品进行核对。',
              style: TextStyle(color: Color(0xFF7D8581), fontSize: 12)),
        ],
      ),
    );
  }

  Future<void> _edit(ChecklistItem? item) async {
    final title = TextEditingController(text: item?.title ?? '');
    final details = TextEditingController(text: item?.details ?? '');
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item == null ? '添加准备项' : '编辑准备项'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: title,
              autofocus: true,
              decoration: const InputDecoration(labelText: '名称')),
          const SizedBox(height: 10),
          TextField(
              controller: details,
              decoration: const InputDecoration(labelText: '数量、规格或备注'),
              maxLines: 2),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('保存'))
        ],
      ),
    );
    if (accepted != true || title.text.trim().isEmpty) return;
    if (item == null) {
      widget.step.checklist.add(ChecklistItem(
          id: 'item-${DateTime.now().microsecondsSinceEpoch}',
          title: title.text.trim(),
          details: details.text.trim()));
    } else {
      item.title = title.text.trim();
      item.details = details.text.trim();
    }
    await _save();
  }
}
