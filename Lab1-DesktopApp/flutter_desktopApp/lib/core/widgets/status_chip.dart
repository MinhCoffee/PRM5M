import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum StatusChipType { present, absent, warning, neutral }

class StatusChip extends StatelessWidget {
  final String label;
  final StatusChipType type;
  final bool showIcon;
  const StatusChip({super.key, required this.label, required this.type, this.showIcon = false});

  @override
  Widget build(BuildContext context) {
    final (background, foreground, border) = switch (type) {
      StatusChipType.present => (const Color(0xFFE6F4EA), const Color(0xFF1E7E34), const Color(0xFFA8DAB5)),
      StatusChipType.absent => (AppColors.errorContainer, AppColors.error, const Color(0xFFF5C2C7)),
      StatusChipType.warning => (const Color(0xFFFEF3D6), const Color(0xFFB76E00), const Color(0xFFFCD38D)),
      StatusChipType.neutral => (const Color(0xFFF1F3F4), const Color(0xFF5F6368), const Color(0xFFDADCE0)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(6), border: Border.all(color: border)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (showIcon) ...[Icon(Icons.warning_amber_rounded, size: 13, color: foreground), const SizedBox(width: 3)],
        Text(label, style: TextStyle(color: foreground, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}