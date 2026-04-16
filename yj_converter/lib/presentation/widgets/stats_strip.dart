import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class StatsStrip extends StatelessWidget {
  final int total, done, active, error;
  const StatsStrip({
    super.key,
    required this.total,
    required this.done,
    required this.active,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    final stats = [
      (label: 'المجموع', value: total,  color: AppColors.txt2),
      (label: 'يعمل',    value: active, color: AppColors.aqua),
      (label: 'مكتمل',   value: done,   color: AppColors.success),
      (label: 'خطأ',     value: error,  color: AppColors.error),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: stats.asMap().entries.map((e) {
            final s = e.value;
            final isLast = e.key == stats.length - 1;
            return Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : const Border(right: BorderSide(color: AppColors.border)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      s.value.toString(),
                      style: GoogleFonts.scheherazadeNew(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: s.color,
                        shadows: s.value > 0
                            ? [Shadow(color: s.color.withOpacity(0.53), blurRadius: 12)]
                            : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.label,
                      style: GoogleFonts.tajawal(
                        fontSize: 9,
                        color: AppColors.txt2,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
