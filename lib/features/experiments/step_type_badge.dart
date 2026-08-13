import 'package:flutter/material.dart';

import 'models.dart';

class StepTypeBadge extends StatelessWidget {
  const StepTypeBadge({super.key, required this.type, this.showLabel = false});

  final StepType type;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final style = stepTypeStyle(type);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: showLabel ? 9 : 8, vertical: 7),
      decoration: BoxDecoration(
          color: style.background, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 18, color: style.foreground),
          if (showLabel) ...[
            const SizedBox(width: 5),
            Text(style.label,
                style: TextStyle(
                    color: style.foreground,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ],
        ],
      ),
    );
  }
}

({IconData icon, Color background, Color foreground, String label})
    stepTypeStyle(StepType type) => switch (type) {
          StepType.operation => (
              icon: Icons.touch_app_outlined,
              background: const Color(0xFFE7F0ED),
              foreground: const Color(0xFF426B61),
              label: '操作'
            ),
          StepType.observation => (
              icon: Icons.visibility_outlined,
              background: const Color(0xFFE9EDF7),
              foreground: const Color(0xFF53658C),
              label: '观察'
            ),
          StepType.incubation => (
              icon: Icons.science_outlined,
              background: const Color(0xFFF3E9F2),
              foreground: const Color(0xFF835E7D),
              label: '培养'
            ),
          StepType.timer => (
              icon: Icons.timer_outlined,
              background: const Color(0xFFFFECDD),
              foreground: const Color(0xFF9A6844),
              label: '计时'
            ),
          StepType.calculation => (
              icon: Icons.calculate_outlined,
              background: const Color(0xFFE5EEF6),
              foreground: const Color(0xFF476F91),
              label: '计算'
            ),
          StepType.instrument => (
              icon: Icons.precision_manufacturing_outlined,
              background: const Color(0xFFE8EAF4),
              foreground: const Color(0xFF5A608A),
              label: '仪器'
            ),
          StepType.result => (
              icon: Icons.fact_check_outlined,
              background: const Color(0xFFF8E8E8),
              foreground: const Color(0xFF9A5E63),
              label: '结果'
            ),
        };

String stepTypeLabel(StepType type) => stepTypeStyle(type).label;
