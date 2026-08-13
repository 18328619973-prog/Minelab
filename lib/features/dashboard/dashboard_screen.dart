import 'package:flutter/material.dart';

import '../../data/local_store.dart';
import '../experiments/experiment_factory.dart';
import '../experiments/experiment_detail_screen.dart';
import '../experiments/models.dart';
import '../experiments/template_catalog.dart';

enum CalendarMode { day, week, month }

typedef _CalendarItem = ({
  ExperimentInstance experiment,
  ExperimentStep first,
  ExperimentStep last,
  int order
});

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
                store: widget.store,
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
    final draft = createFromTemplate(template, startDate: selectedDate);
    if (!mounted) return;
    final created = await Navigator.push<ExperimentInstance>(
        context,
        MaterialPageRoute(
            builder: (_) => ExperimentDetailScreen(
                experiment: draft, store: widget.store, isCreating: true)));
    if (created == null) return;
    await widget.store.add(created);
    if (!mounted) return;
    setState(() => mode = CalendarMode.day);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('已添加：${created.name}')));
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
        final count = _calendarItemsForDate(entries, date).length;
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
      required this.store,
      required this.onCreate,
      required this.onChanged});
  final DateTime date;
  final List<({ExperimentInstance experiment, ExperimentStep step})> entries;
  final LocalStore store;
  final VoidCallback onCreate;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final dayItems = _calendarItemsForDate(entries, date);
    final done = dayItems
        .where((item) => item.experiment.steps
            .every((step) => step.status == StepStatus.completed))
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
                Text('$done / ${dayItems.length} 实验已完成',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 12),
            if (dayItems.isEmpty)
              _EmptySchedule(onCreate: onCreate)
            else
              ...List.generate(13, (index) {
                final hour = index + 8;
                final hourEntries = dayItems
                    .where((item) => item.first.plannedAt.hour == hour)
                    .toList();
                final isNow = _sameDay(date, DateTime.now()) &&
                    DateTime.now().hour == hour;
                return _HourRow(
                    hour: hour,
                    entries: hourEntries,
                    store: store,
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
      required this.store,
      required this.isNow,
      required this.onChanged});
  final int hour;
  final List<_CalendarItem> entries;
  final LocalStore store;
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
                    ...entries.map((item) => _ScheduleCard(
                        item: item, store: store, onChanged: onChanged)),
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
      {required this.item, required this.store, required this.onChanged});
  final _CalendarItem item;
  final LocalStore store;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final experiment = item.experiment;
    final daySteps = experiment.steps
        .where((step) => _sameDay(step.plannedAt, item.first.plannedAt));
    final completed =
        daySteps.every((step) => step.status == StepStatus.completed);
    final completedCount = experiment.steps
        .where((step) => step.status == StepStatus.completed)
        .length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: experiment.color.withValues(alpha: completed ? .35 : .65),
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.only(left: 12, right: 4),
          onTap: () async {
            await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ExperimentDetailScreen(
                        experiment: experiment, store: store)));
            onChanged();
          },
          title: Text('${item.order}. ${_shortName(experiment.name)}',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  decoration: completed ? TextDecoration.lineThrough : null)),
          subtitle: Text(
              '${_time(item.first.plannedAt)}–${_time(item.last.plannedAt)} · $completedCount/${experiment.steps.length} 步骤',
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
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
          final items = _calendarItemsForDate(entries, date);
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
                                    .map((item) => Chip(
                                        backgroundColor: item.experiment.color
                                            .withValues(alpha: .55),
                                        label: Text(
                                            '${item.order}. ${_shortName(item.experiment.name)}')))
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
            final items = _calendarItemsForDate(entries, date);
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
                    ...items.take(3).map((item) => Container(
                        margin: const EdgeInsets.only(bottom: 3),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 3, vertical: 2),
                        decoration: BoxDecoration(
                            color: item.experiment.color.withValues(alpha: .72),
                            borderRadius: BorderRadius.circular(5)),
                        child: Text(
                            '${item.order}.${_shortName(item.experiment.name)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 8, fontWeight: FontWeight.w700)))),
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

List<_CalendarItem> _calendarItemsForDate(
    List<({ExperimentInstance experiment, ExperimentStep step})> entries,
    DateTime date) {
  final grouped =
      <String, List<({ExperimentInstance experiment, ExperimentStep step})>>{};
  for (final entry in entries) {
    if (!_sameDay(entry.step.plannedAt, date)) continue;
    grouped.putIfAbsent(entry.experiment.id, () => []).add(entry);
  }
  final groups = grouped.values.toList()
    ..sort((a, b) => a.first.step.plannedAt.compareTo(b.first.step.plannedAt));
  return groups.asMap().entries.map((entry) {
    final steps = entry.value.map((value) => value.step).toList()
      ..sort((a, b) => a.plannedAt.compareTo(b.plannedAt));
    return (
      experiment: entry.value.first.experiment,
      first: steps.first,
      last: steps.last,
      order: entry.key + 1,
    );
  }).toList();
}

String _shortName(String name) {
  final slash = name.indexOf(' / ');
  return slash == -1 ? name : name.substring(0, slash);
}
