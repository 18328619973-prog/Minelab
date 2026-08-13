import 'package:flutter_test/flutter_test.dart';
import 'package:minelab/features/experiments/experiment_factory.dart';
import 'package:minelab/features/experiments/models.dart';
import 'package:minelab/features/experiments/template_catalog.dart';

void main() {
  test('CCK-8 template creates preparation and workflow steps', () {
    final experiment =
        createFromTemplate(cck8Template(), startDate: DateTime(2026, 8, 12));
    expect(experiment.steps, hasLength(6));
    expect(experiment.steps.first.title, '物品准备');
    expect(experiment.steps.first.checklist, hasLength(7));
    expect(experiment.steps[3].plannedAt, DateTime(2026, 8, 12, 13));
    expect(experiment.steps[5].dependsOnId, 'read');
  });

  test('late completion shifts the entire dependent chain', () {
    final experiment =
        createFromTemplate(cck8Template(), startDate: DateTime(2026, 8, 12));
    completeStep(experiment, experiment.steps[2],
        completedAt: DateTime(2026, 8, 12, 10));
    expect(experiment.steps[3].plannedAt, DateTime(2026, 8, 12, 14));
    expect(experiment.steps[4].plannedAt, DateTime(2026, 8, 12, 16));
    expect(experiment.steps[5].plannedAt, DateTime(2026, 8, 12, 16, 30));
    expect(experiment.steps[3].status, StepStatus.pending);
  });

  test('instantiated checklist can change without changing template', () {
    final template = cck8Template();
    final experiment =
        createFromTemplate(template, startDate: DateTime(2026, 8, 12));
    experiment.steps.first.checklist.first.title = '本次实验自定义物品';
    experiment.steps.first.checklist
        .add(ChecklistItem(id: 'extra', title: '额外物品'));
    expect(template.steps.first.checklist.first, '细胞与培养板');
    expect(template.steps.first.checklist, hasLength(7));
    expect(experiment.steps.first.checklist, hasLength(8));
  });

  test('built-in catalog contains biological, animal and custom templates', () {
    final templates = builtInTemplates();
    expect(
        templates
            .where((template) => template.domain == ExperimentDomain.biological)
            .length,
        greaterThan(5));
    expect(
        templates
            .where((template) => template.domain == ExperimentDomain.animal)
            .length,
        greaterThanOrEqualTo(4));
    expect(
        templates
            .where((template) => template.domain == ExperimentDomain.custom)
            .length,
        1);
  });
}
