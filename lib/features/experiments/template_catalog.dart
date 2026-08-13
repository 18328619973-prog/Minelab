import 'package:flutter/material.dart';

import 'models.dart';

List<ExperimentTemplate> builtInTemplates() => [
      cck8Template(),
      _template('cell-culture', '细胞培养', const Color(0xFFB9D9CF), '观察、换液与培养记录',
          ['细胞状态观察', '更换培养基', '培养记录']),
      _template('cell-passage', '细胞传代', const Color(0xFFC2D9EE), '消化、计数、接种与记录',
          ['培养状态确认', '细胞消化', '细胞计数', '重新接种', '记录传代信息']),
      _template('pcr-qpcr', 'PCR / qPCR', const Color(0xFFD1C6E8),
          '反应体系、扩增和结果记录', ['样本与引物确认', '配制反应体系', '上机扩增', '结果记录']),
      _template('western-blot', 'Western Blot', const Color(0xFFBFD3EA),
          '样本、上样、电泳、转膜和成像', [
        '蛋白样本定量',
        '配制上样体系',
        'SDS-PAGE 电泳',
        '转膜',
        '封闭',
        '一抗孵育',
        '二抗孵育',
        '显影 / 成像',
        '记录结果'
      ]),
      _template('rna-extraction', 'RNA 提取 / 反转录', const Color(0xFFE8D2B7),
          '提取、质量检查和反转录记录', ['样本准备', 'RNA 提取', '浓度与纯度检查', '反转录', '结果记录']),
      _template(
          'immunofluorescence',
          '免疫荧光',
          const Color(0xFFE8C5D2),
          '样本处理、染色、成像与记录',
          ['样本准备', '固定与通透', '封闭', '一抗孵育', '二抗孵育', '成像', '结果记录']),
      _animalTemplate('animal-project', '动物实验项目', '从分组、观察、处理到取材的可编辑项目框架', [
        '伦理与方案确认',
        '动物建档与分组',
        '基线观察',
        '实验处理',
        '连续观察记录',
        '样本采集 / 取材',
        '实验终点记录'
      ]),
      _animalTemplate('animal-dosing', '动物给药计划', '按获批方案安排给药与观察记录',
          ['方案与动物核对', '给药前观察', '给药记录', '给药后观察', '异常与结果记录']),
      _animalTemplate('animal-observation', '体重与一般状态观察', '连续体重、状态及人道终点观察',
          ['动物身份核对', '体重记录', '一般状态观察', '终点指标核对', '完成记录']),
      _animalTemplate('animal-sampling', '动物样本采集 / 取材', '按获批方案安排采样、标记与保存',
          ['方案与标签核对', '采样准备', '样本采集', '样本标记与保存', '记录完成']),
      const ExperimentTemplate(
          id: 'blank',
          name: '空白实验',
          color: Color(0xFFD8D8D2),
          domain: ExperimentDomain.custom,
          summary: '从一个可编辑步骤开始',
          steps: [
            TemplateStep(
                id: 'step-1',
                title: '新步骤',
                description: '点击时间进行编辑',
                stepType: StepType.operation,
                timeMode: TimeMode.absolute,
                plannedTime: TimeOfDay(hour: 9, minute: 0))
          ]),
    ];

ExperimentTemplate _template(String id, String name, Color color,
        String summary, List<String> titles) =>
    ExperimentTemplate(
      id: id,
      name: name,
      color: color,
      summary: summary,
      steps: _steps(['物品准备', ...titles], checklist: _checklistFor(id)),
    );

ExperimentTemplate _animalTemplate(
        String id, String name, String summary, List<String> titles) =>
    ExperimentTemplate(
      id: id,
      name: name,
      color: const Color(0xFFC7DDE2),
      domain: ExperimentDomain.animal,
      summary: summary,
      steps: _steps(['物品与资料准备', ...titles], checklist: _checklistFor(id)),
    );

List<TemplateStep> _steps(List<String> titles,
        {List<String> checklist = const []}) =>
    List.generate(titles.length, (index) {
      final id = 'step-${index + 1}';
      if (index == 0) {
        return TemplateStep(
            id: id,
            title: titles[index],
            description: '系统建议项，可按实验室 SOP 修改',
            stepType: StepType.operation,
            timeMode: TimeMode.absolute,
            plannedTime: const TimeOfDay(hour: 9, minute: 0),
            checklist: checklist);
      }
      return TemplateStep(
          id: id,
          title: titles[index],
          description: '系统建议项，可按实验室 SOP 修改',
          stepType:
              index == titles.length - 1 ? StepType.result : StepType.operation,
          timeMode: TimeMode.relative,
          offsetMinutes: 60,
          dependsOnId: 'step-$index');
    });

List<String> _checklistFor(String id) => switch (id) {
      'cell-culture' => ['细胞培养物', '培养基', 'PBS', '培养皿或培养板', '移液器与无菌枪头', '废液容器'],
      'cell-passage' => [
          '待传代细胞',
          '完全培养基',
          'PBS',
          '消化液',
          '离心管',
          '细胞计数用品',
          '培养容器'
        ],
      'pcr-qpcr' => [
          '核酸样本',
          '引物',
          '反应预混液',
          '无核酸酶水',
          'PCR 管或板',
          '封板膜',
          '移液器与滤芯枪头'
        ],
      'western-blot' => [
          '蛋白样本',
          '定量试剂',
          '上样缓冲液',
          '凝胶及电泳缓冲液',
          '转膜耗材',
          '封闭液',
          '一抗与二抗',
          '显影或成像试剂'
        ],
      'rna-extraction' => [
          '待提取样本',
          'RNA 提取试剂',
          '无 RNase 耗材',
          '无核酸酶水',
          '反转录试剂',
          '冰盒与样本标签'
        ],
      'immunofluorescence' => [
          '待染色样本',
          '固定液',
          '通透液',
          '封闭液',
          '一抗与二抗',
          '核染试剂',
          '封片剂',
          '避光容器'
        ],
      'animal-project' => [
          '获批方案与记录表',
          '动物身份及分组信息',
          '观察记录用品',
          '样本标签',
          '个人防护用品',
          '应急与人道终点信息'
        ],
      'animal-dosing' => [
          '获批给药方案',
          '动物身份与分组表',
          '待用物品标签',
          '给药记录表',
          '观察记录表',
          '个人防护用品'
        ],
      'animal-observation' => ['动物身份表', '体重记录表', '状态评分表', '人道终点核对表', '称量与清洁用品'],
      'animal-sampling' => [
          '获批采样方案',
          '动物身份表',
          '样本容器与标签',
          '保存介质',
          '转运或冷链用品',
          '采样记录表'
        ],
      _ => const [],
    };
