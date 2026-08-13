import 'package:flutter/material.dart';

import '../../data/local_store.dart';
import '../experiments/experiment_factory.dart';
import '../experiments/models.dart';
import '../experiments/template_catalog.dart';

enum CalendarMode { day, week, month }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.store});

  final LocalStore store;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  CalendarMode mode = CalendarMode.day;
  DateTime selectedDate = _dateOnly(DateTime.now());

  List<({ExperimentInstance experiment, ExperimentStep step})> get entries {
    final result = <({ExperimentInstance experiment, ExperimentStep step})>[];
    for (final experiment in widget.store.experiments) {
      for (final step in experiment.steps) {
        result.add((experiment: experiment, step: step));
      }
    }
    result.sort((a, b) => a.step.plannedAt.compareTo(b.step.plannedAt));
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 32),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MineLab',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(_fullDate(selectedDate),
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(color: const Color(0xFF70777A))),
                  ],
                ),
              ),
              FilledButton.icon(
                  onPressed: _pickTemplate,
                  icon: const Icon(Icons.add),
                  label: const Text('添加实验')),
            ],
          ),
          const SizedBox(height: 20),
          SegmentedButton<CalendarMode>(
            segments: const [
              ButtonSegment(
                  value: CalendarMode.day,
                  label: Text('日'),
                  icon: Icon(Icons.view_day_outlined)),
              ButtonSegment(
                  value: CalendarMode.week,
                  label: Text('周'),
                  icon: Icon(Icons.view_week_outlined)),
              ButtonSegment(
                  value: CalendarMode.month,
                  label: Text('月'),
                  icon: Icon(Icons.calendar_month_outlined)),
            ],
            selected: {mode},
            showSelectedIcon: false,
            onSelectionChanged: (value) => setState(() => mode = value.first),
          ),
          const SizedBox(height: 16),
          if (mode == CalendarMode.day) ...[
            _WeekStrip(
                selectedDate: selectedDate,
                entries: entries,
                onSelect: (date) => setState(() => selectedDate = date)),
            const SizedBox(height: 16),
            _DaySchedule(
                date: selectedDate,
                entries: entries,
                onCreate: _pickTemplate,
                onChanged: _saveAndRefresh),
          ] else if (mode == CalendarMode.week)
            _WeekOverview(
                selectedDate: selectedDate,
                entries: entries,
                onSelect: _openDay)
          else
            _MonthOverview(
                selectedDate: selectedDate,
                entries: entries,
                onSelect: _openDay,
                onMonthChanged: (date) => setState(() => selectedDate = date)),
        ],
      ),
    );
  }

  void _openDay(DateTime date) => setState(() {
        selectedDate = _dateOnly(date);
        mode = CalendarMode.day;
      });

  Future<void> _pickTemplate() async {
    final template = await showModalBottomSheet<ExperimentTemplate>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _TemplatePicker(),
    );
    if (template == null) return;
    await widget.store
        .add(createFromTemplate(template, startDate: selectedDate));
    if (!mounted) return;
    setState(() => mode = CalendarMode.day);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('已添加：${template.name}')));
  }

  void _saveAndRefresh() {
    setState(() {});
    widget.store.save();
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip(
      {required this.selectedDate,
      required this.entries,
      required this.onSelect});
  final DateTime selectedDate;
  final List<({ExperimentInstance experiment, ExperimentStep step})> entries;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final start =
        selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
    return Row(
      children: List.generate(7, (index) {
        final date = _dateOnly(start.add(Duration(days: index)));
        final selected = _sameDay(date, selectedDate);
        final count = entries
            .where((entry) => _sameDay(entry.step.plannedAt, date))
            .length;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == 6 ? 0 : 5),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => onSelect(date),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF365F58) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: selected
                          ? const Color(0xFF365F58)
                          : const Color(0xFFE5E9E7)),
                ),
                child: Column(
                  children: [
                    Text(_weekdays[index],
                        style: TextStyle(
                            color: selected
                                ? Colors.white70
                                : const Color(0xFF747C7A),
                            fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('${date.day}',
                        style: TextStyle(
                            color: selected
                                ? Colors.white
                                : const Color(0xFF22302D),
                            fontWeight: FontWeight.w800,
                            fontSize: 20)),
                    const SizedBox(height: 6),
                    Container(
                        width: count == 0 ? 4 : 18,
                        height: 4,
                        decoration: BoxDecoration(
                            color: count == 0
                                ? Colors.transparent
                                : (selected
                                    ? const Color(0xFFE8C8B5)
                                    : const Color(0xFF91B9AE)),
                            borderRadius: BorderRadius.circular(4))),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _DaySchedule extends StatelessWidget {
  const _DaySchedule(
      {required this.date,
      required this.entries,
      required this.onCreate,
      required this.onChanged});
  final DateTime date;
  final List<({ExperimentInstance experiment, ExperimentStep step})> entries;
  final VoidCallback onCreate;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final dayEntries =
        entries.where((entry) => _sameDay(entry.step.plannedAt, date)).toList();
    final done = dayEntries
        .where((entry) => entry.step.status == StepStatus.completed)
        .length;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                    child: Text('日程安排',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800))),
                Text('$done / ${dayEntries.length} 已完成',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 12),
            if (dayEntries.isEmpty)
              _EmptySchedule(onCreate: onCreate)
            else
              ...List.generate(13, (index) {
                final hour = index + 8;
                final hourEntries = dayEntries
                    .where((entry) => entry.step.plannedAt.hour == hour)
                    .toList();
                final isNow = _sameDay(date, DateTime.now()) &&
                    DateTime.now().hour == hour;
                return _HourRow(
                    hour: hour,
                    entries: hourEntries,
                    isNow: isNow,
                    onChanged: onChanged);
              }),
          ],
        ),
      ),
    );
  }
}

class _EmptySchedule extends StatelessWidget {
  const _EmptySchedule({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Container(
        height: 460,
        decoration: BoxDecoration(
            color: const Color(0xFFF7F9F8),
            borderRadius: BorderRadius.circular(20)),
        child: Stack(
          children: [
            ...List.generate(
                7,
                (index) => Positioned(
                    left: 58,
                    right: 14,
                    top: 28.0 + index * 64,
                    child: const Divider(height: 1))),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 42, color: Color(0xFF789A91)),
                  const SizedBox(height: 12),
                  const Text('这一天还没有实验安排'),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                      onPressed: onCreate,
                      icon: const Icon(Icons.add),
                      label: const Text('添加实验')),
                ],
              ),
            ),
          ],
        ),
      );
}

class _HourRow extends StatelessWidget {
  const _HourRow(
      {required this.hour,
      required this.entries,
      required this.isNow,
      required this.onChanged});
  final int hour;
  final List<({ExperimentInstance experiment, ExperimentStep step})> entries;
  final bool isNow;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 48,
                child: Text('${hour.toString().padLeft(2, '0')}:00',
                    style: Theme.of(context).textTheme.bodySmall)),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 58),
                decoration: BoxDecoration(
                    border: Border(
                        top: BorderSide(
                            color: isNow
                                ? const Color(0xFFE48B7D)
                                : const Color(0xFFE8ECEA),
                            width: isNow ? 2 : 1))),
                padding: const EdgeInsets.fromLTRB(8, 6, 0, 6),
                child: Column(
                  children: [
                    if (isNow)
                      Align(
                          alignment: Alignment.centerLeft,
                          child: Text('现在 ${_time(DateTime.now())}',
                              style: const TextStyle(
                                  color: Color(0xFFC95E50),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700))),
                    ...entries.map((entry) => _ScheduleCard(
                        experiment: entry.experiment,
                        step: entry.step,
                        onChanged: onChanged)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard(
      {required this.experiment, required this.step, required this.onChanged});
  final ExperimentInstance experiment;
  final ExperimentStep step;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final completed = step.status == StepStatus.completed;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
          color: experiment.color.withValues(alpha: completed ? .35 : .65),
          borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.only(left: 12, right: 4),
        onTap: () => _editTime(context),
        title: Text(step.title,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                decoration: completed ? TextDecoration.lineThrough : null)),
        subtitle: Text('${_time(step.plannedAt)} · ${experiment.name}',
            maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: IconButton(
          tooltip: completed ? '已完成' : '完成步骤',
          onPressed: completed
              ? null
              : () {
                  completeStep(experiment, step);
                  onChanged();
                },
          icon: Icon(
              completed ? Icons.check_circle : Icons.radio_button_unchecked),
          color: completed ? const Color(0xFF467D65) : const Color(0xFF53645F),
        ),
      ),
    );
  }

  Future<void> _editTime(BuildContext context) async {
    final value = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(step.plannedAt));
    if (value == null) return;
    step.plannedAt = DateTime(step.plannedAt.year, step.plannedAt.month,
        step.plannedAt.day, value.hour, value.minute);
    onChanged();
  }
}

class _WeekOverview extends StatelessWidget {
  const _WeekOverview(
      {required this.selectedDate,
      required this.entries,
      required this.onSelect});
  final DateTime selectedDate;
  final List<({ExperimentInstance experiment, ExperimentStep step})> entries;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final start =
        selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
            '${start.month}月${start.day}日 — ${start.add(const Duration(days: 6)).month}月${start.add(const Duration(days: 6)).day}日',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        ...List.generate(7, (index) {
          final date = _dateOnly(start.add(Duration(days: index)));
          final items = entries
              .where((entry) => _sameDay(entry.step.plannedAt, date))
              .toList();
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onSelect(date),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                        width: 58,
                        child: Column(children: [
                          Text(_weekdays[index]),
                          Text('${date.day}',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w800))
                        ])),
                    Expanded(
                        child: items.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text('无安排',
                                    style: TextStyle(color: Color(0xFF909793))))
                            : Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: items
                                    .take(5)
                                    .map((entry) => Chip(
                                        backgroundColor: entry.experiment.color
                                            .withValues(alpha: .55),
                                        label: Text(
                                            '${_time(entry.step.plannedAt)} ${entry.step.title}')))
                                    .toList())),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _MonthOverview extends StatelessWidget {
  const _MonthOverview(
      {required this.selectedDate,
      required this.entries,
      required this.onSelect,
      required this.onMonthChanged});
  final DateTime selectedDate;
  final List<({ExperimentInstance experiment, ExperimentStep step})> entries;
  final ValueChanged<DateTime> onSelect;
  final ValueChanged<DateTime> onMonthChanged;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(selectedDate.year, selectedDate.month);
    final gridStart = first.subtract(Duration(days: first.weekday - 1));
    return Column(
      children: [
        Row(children: [
          Expanded(
              child: Text('${selectedDate.year}年 ${selectedDate.month}月',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800))),
          IconButton(
              onPressed: () => onMonthChanged(
                  DateTime(selectedDate.year, selectedDate.month - 1, 1)),
              icon: const Icon(Icons.chevron_left)),
          IconButton(
              onPressed: () => onMonthChanged(
                  DateTime(selectedDate.year, selectedDate.month + 1, 1)),
              icon: const Icon(Icons.chevron_right))
        ]),
        Row(
            children: _weekdays
                .map((day) => Expanded(
                    child: Center(
                        child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(day)))))
                .toList()),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 42,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: .62,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4),
          itemBuilder: (context, index) {
            final date = _dateOnly(gridStart.add(Duration(days: index)));
            final items = entries
                .where((entry) => _sameDay(entry.step.plannedAt, date))
                .toList();
            final inMonth = date.month == selectedDate.month;
            return InkWell(
              onTap: () => onSelect(date),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                    color: _sameDay(date, DateTime.now())
                        ? const Color(0xFFF4E3E1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE8ECEA))),
                child: Column(
                  children: [
                    Text('${date.day}',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: inMonth
                                ? const Color(0xFF263732)
                                : const Color(0xFFB5BAB8))),
                    const SizedBox(height: 5),
                    ...items.take(3).map((entry) => Container(
                        margin: const EdgeInsets.only(bottom: 3),
                        height: 6,
                        decoration: BoxDecoration(
                            color: entry.experiment.color,
                            borderRadius: BorderRadius.circular(6)))),
                    if (items.length > 3)
                      Text('+${items.length - 3}',
                          style: const TextStyle(fontSize: 9)),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _TemplatePicker extends StatelessWidget {
  const _TemplatePicker();

  @override
  Widget build(BuildContext context) {
    final templates = builtInTemplates();
    return DefaultTabController(
      length: 3,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .82,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFFD9DEDC),
                    borderRadius: BorderRadius.circular(4))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 10),
              child: Row(children: [
                Expanded(
                    child: Text('添加实验',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800))),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close))
              ]),
            ),
            const TabBar(tabs: [
              Tab(text: '生物实验'),
              Tab(text: '动物实验'),
              Tab(text: '我的模板')
            ]),
            Expanded(
              child: TabBarView(
                children: [
                  _TemplateList(
                      templates: templates
                          .where((item) =>
                              item.domain == ExperimentDomain.biological)
                          .toList()),
                  _TemplateList(
                      templates: templates
                          .where(
                              (item) => item.domain == ExperimentDomain.animal)
                          .toList(),
                      animalNotice: true),
                  _TemplateList(
                      templates: templates
                          .where(
                              (item) => item.domain == ExperimentDomain.custom)
                          .toList()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateList extends StatelessWidget {
  const _TemplateList({required this.templates, this.animalNotice = false});
  final List<ExperimentTemplate> templates;
  final bool animalNotice;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(18),
        children: [
          if (animalNotice)
            Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: const Color(0xFFF4F1EA),
                    borderRadius: BorderRadius.circular(14)),
                child: const Text('动物模板仅提供排期和记录框架。请以伦理审批、实验室 SOP 与专业人员指导为准。',
                    style: TextStyle(fontSize: 12))),
          ...templates.map((template) => Card(
                margin: const EdgeInsets.only(bottom: 9),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  leading: CircleAvatar(
                      backgroundColor: template.color,
                      child: const Icon(Icons.science_outlined,
                          color: Color(0xFF31443F))),
                  title: Text(template.name,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                      '${template.summary}\n${template.steps.length} 个建议步骤',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => Navigator.pop(context, template),
                ),
              )),
        ],
      );
}

const _weekdays = ['一', '二', '三', '四', '五', '六', '日'];

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
String _time(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
String _fullDate(DateTime value) =>
    '${value.year}年${value.month}月${value.day}日 · 星期${_weekdays[value.weekday - 1]}';
