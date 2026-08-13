import 'package:flutter_test/flutter_test.dart';
import 'package:minelab/features/experiments/experiment_factory.dart';
import 'package:minelab/features/experiments/models.dart';
import 'package:minelab/features/experiments/template_catalog.dart';

void main() {
  test('CCK-8 template creates five steps and relative offsets', () {
    final e =
        createFromTemplate(cck8Template(), startDate: DateTime(2026, 8, 12));
    expect(e.steps, hasLength(5));
    expect(e.steps[2].plannedAt, DateTime(2026, 8, 12, 13));
    expect(e.steps[4].dependsOnId, 'read');
  });

  test('late completion shifts the entire dependent chain', () {
    final e =
        createFromTemplate(cck8Template(), startDate: DateTime(2026, 8, 12));
    completeStep(e, e.steps[1], completedAt: DateTime(2026, 8, 12, 10));
    expect(e.steps[2].plannedAt, DateTime(2026, 8, 12, 14));
    expect(e.steps[3].plannedAt, DateTime(2026, 8, 12, 16));
    expect(e.steps[4].plannedAt, DateTime(2026, 8, 12, 16, 30));
    expect(e.steps[2].status, StepStatus.pending);
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
