import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/experiments/models.dart';

class LocalStore {
  static const _key = 'minelab.experiments.v1';
  final experiments = <ExperimentInstance>[];
  SharedPreferences? _preferences;

  Future<void> load() async {
    _preferences = await SharedPreferences.getInstance();
    final raw = _preferences!.getString(_key);
    if (raw == null) return;
    try {
      experiments
        ..clear()
        ..addAll((jsonDecode(raw) as List).map((value) => _fromJson(value as Map<String, dynamic>)));
    } on FormatException {
      experiments.clear();
    }
  }

  Future<void> save() async {
    await _preferences?.setString(_key, jsonEncode(experiments.map(_toJson).toList()));
  }

  Future<void> add(ExperimentInstance experiment) async {
    experiments.insert(0, experiment);
    await save();
  }

  Map<String, dynamic> _toJson(ExperimentInstance experiment) => {
        'id': experiment.id,
        'templateId': experiment.templateId,
        'name': experiment.name,
        'color': experiment.color.toARGB32(),
        'startedAt': experiment.startedAt.toIso8601String(),
        'status': experiment.status.name,
        'project': experiment.project,
        'cellLine': experiment.cellLine,
        'steps': experiment.steps.map((step) => {
              'id': step.id,
              'experimentId': step.experimentId,
              'title': step.title,
              'description': step.description,
              'stepType': step.stepType.name,
              'plannedAt': step.plannedAt.toIso8601String(),
              'timeMode': step.timeMode.name,
              'offsetMinutes': step.offsetMinutes,
              'dependsOnId': step.dependsOnId,
              'linkedTool': step.linkedTool,
              'status': step.status.name,
              'actualStartTime': step.actualStartTime?.toIso8601String(),
              'actualEndTime': step.actualEndTime?.toIso8601String(),
              'notes': step.notes,
              'result': step.result,
            }).toList(),
      };

  ExperimentInstance _fromJson(Map<String, dynamic> json) => ExperimentInstance(
        id: json['id'] as String,
        templateId: json['templateId'] as String,
        name: json['name'] as String,
        color: Color(json['color'] as int),
        startedAt: DateTime.parse(json['startedAt'] as String),
        status: ExperimentStatus.values.byName(json['status'] as String),
        project: json['project'] as String? ?? '',
        cellLine: json['cellLine'] as String? ?? '',
        steps: (json['steps'] as List).map((raw) {
          final step = raw as Map<String, dynamic>;
          return ExperimentStep(
            id: step['id'] as String,
            experimentId: step['experimentId'] as String,
            title: step['title'] as String,
            description: step['description'] as String,
            stepType: StepType.values.byName(step['stepType'] as String),
            plannedAt: DateTime.parse(step['plannedAt'] as String),
            timeMode: TimeMode.values.byName(step['timeMode'] as String),
            offsetMinutes: step['offsetMinutes'] as int?,
            dependsOnId: step['dependsOnId'] as String?,
            linkedTool: step['linkedTool'] as String?,
            status: StepStatus.values.byName(step['status'] as String),
            actualStartTime: step['actualStartTime'] == null ? null : DateTime.parse(step['actualStartTime'] as String),
            actualEndTime: step['actualEndTime'] == null ? null : DateTime.parse(step['actualEndTime'] as String),
            notes: step['notes'] as String? ?? '',
            result: step['result'] as String? ?? '',
          );
        }).toList(),
      );
}
