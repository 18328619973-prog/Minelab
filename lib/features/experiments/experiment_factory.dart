import 'models.dart';

ExperimentInstance createFromTemplate(ExperimentTemplate template,
    {DateTime? startDate}) {
  final start = startDate ?? DateTime.now();
  final anchor = DateTime(start.year, start.month, start.day);
  final id = '${template.id}-${DateTime.now().millisecondsSinceEpoch}';
  final steps = <ExperimentStep>[];
  for (final source in template.steps) {
    final planned = source.timeMode == TimeMode.absolute
        ? DateTime(anchor.year, anchor.month, anchor.day,
            source.plannedTime!.hour, source.plannedTime!.minute)
        : steps
            .firstWhere((step) => step.id == source.dependsOnId)
            .plannedAt
            .add(Duration(minutes: source.offsetMinutes ?? 0));
    steps.add(ExperimentStep(
        id: source.id,
        experimentId: id,
        title: source.title,
        description: source.description,
        stepType: source.stepType,
        plannedAt: planned,
        timeMode: source.timeMode,
        offsetMinutes: source.offsetMinutes,
        dependsOnId: source.dependsOnId,
        linkedTool: source.linkedTool,
        checklist: source.checklist
            .asMap()
            .entries
            .map((entry) => ChecklistItem(
                id: '${source.id}-item-${entry.key}', title: entry.value))
            .toList()));
  }
  return ExperimentInstance(
      id: id,
      templateId: template.id,
      name: template.name,
      color: template.color,
      startedAt: start,
      steps: steps,
      domain: template.domain);
}

void completeStep(ExperimentInstance experiment, ExperimentStep step,
    {DateTime? completedAt, bool shiftDependents = true}) {
  final actual = completedAt ?? DateTime.now();
  final delay = actual.difference(step.plannedAt);
  step.actualEndTime = actual;
  step.status = StepStatus.completed;
  experiment.status = ExperimentStatus.running;
  if (!shiftDependents || delay == Duration.zero) return;
  _shiftDependents(experiment, step.id, delay);
}

void _shiftDependents(
    ExperimentInstance experiment, String stepId, Duration delay) {
  for (final dependent in experiment.steps
      .where((candidate) => candidate.dependsOnId == stepId)) {
    dependent.plannedAt = dependent.plannedAt.add(delay);
    _shiftDependents(experiment, dependent.id, delay);
  }
}
