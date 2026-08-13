import 'package:flutter/material.dart';

enum StepType { operation, observation, incubation, timer, calculation, instrument, result }
enum TimeMode { absolute, relative }
enum StepStatus { pending, ready, running, completed, skipped }
enum ExperimentStatus { planned, running, paused, completed, archived }

class TemplateStep {
  const TemplateStep({required this.id, required this.title, required this.description, required this.stepType, required this.timeMode, this.plannedTime, this.offsetMinutes, this.dependsOnId, this.linkedTool});
  final String id;
  final String title;
  final String description;
  final StepType stepType;
  final TimeMode timeMode;
  final TimeOfDay? plannedTime;
  final int? offsetMinutes;
  final String? dependsOnId;
  final String? linkedTool;
}

class ExperimentTemplate {
  const ExperimentTemplate({required this.id, required this.name, required this.color, required this.steps});
  final String id;
  final String name;
  final Color color;
  final List<TemplateStep> steps;
}

class ExperimentStep {
  ExperimentStep({required this.id, required this.experimentId, required this.title, required this.description, required this.stepType, required this.plannedAt, required this.timeMode, this.offsetMinutes, this.dependsOnId, this.linkedTool, this.status = StepStatus.pending, this.actualStartTime, this.actualEndTime, this.notes = '', this.result = ''});
  final String id;
  final String experimentId;
  String title;
  String description;
  final StepType stepType;
  DateTime plannedAt;
  final TimeMode timeMode;
  final int? offsetMinutes;
  final String? dependsOnId;
  final String? linkedTool;
  StepStatus status;
  DateTime? actualStartTime;
  DateTime? actualEndTime;
  String notes;
  String result;
}

class ExperimentInstance {
  ExperimentInstance({required this.id, required this.templateId, required this.name, required this.color, required this.startedAt, required this.steps, this.status = ExperimentStatus.planned, this.project = '', this.cellLine = ''});
  final String id;
  final String templateId;
  String name;
  final Color color;
  final DateTime startedAt;
  final List<ExperimentStep> steps;
  ExperimentStatus status;
  String project;
  String cellLine;
}

ExperimentTemplate cck8Template() => const ExperimentTemplate(
      id: 'cck8', name: 'CCK-8', color: Color(0xFFE8B7C8),
      steps: [
        TemplateStep(id: 'observe', title: '细胞状态观察', description: '记录细胞状态与融合度', stepType: StepType.observation, timeMode: TimeMode.absolute, plannedTime: TimeOfDay(hour: 8, minute: 30)),
        TemplateStep(id: 'treat', title: '加药', description: '完成药物处理或换液', stepType: StepType.operation, timeMode: TimeMode.absolute, plannedTime: TimeOfDay(hour: 9, minute: 0)),
        TemplateStep(id: 'reagent', title: '加 CCK-8', description: '加入 CCK-8 试剂', stepType: StepType.operation, timeMode: TimeMode.relative, offsetMinutes: 240, dependsOnId: 'treat'),
        TemplateStep(id: 'read', title: '酶标仪读数', description: '记录 OD450 读数', stepType: StepType.instrument, timeMode: TimeMode.relative, offsetMinutes: 120, dependsOnId: 'reagent'),
        TemplateStep(id: 'result', title: '结果记录', description: '录入 OD450 表格和备注', stepType: StepType.result, timeMode: TimeMode.relative, offsetMinutes: 30, dependsOnId: 'read'),
      ],
    );
