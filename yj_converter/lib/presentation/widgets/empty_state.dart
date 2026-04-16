import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class EmptyState extends StatefulWidget {
  final VoidCallback onPick;
  const EmptyState({super.key, required this.onPick});

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState> {
  final _icons = ['🎬', '🎥', '📽', '🎞'];
  int _frame = 0;

  @override
  void initState() {
    super.initState();
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return false;
      setState(() => _frame = (_frame + 1) % 4);
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _icons[_frame],
              style: const TextStyle(fontSize: 68),
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد فيديوهات بعد',
              style: GoogleFonts.scheherazadeNew(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.txt2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'اضغط على + لاختيار فيديوهات MP4\nيدعم 100+ ملف بالمعالجة المتوازية',
              style: GoogleFonts.tajawal(
                fontSize: 12,
                color: AppColors.txt3,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: widget.onPick,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 13),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(34),
                  gradient: const LinearGradient(
                    colors: [AppColors.aqua, AppColors.aquaDim],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.aqua.withOpacity(0.4),
                      blurRadius: 28,
                    ),
                  ],
                ),
                child: Text(
                  '+ اختر الفيديوهات',
                  style: GoogleFonts.tajawal(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.neon.withOpacity(0.2)),
                color: AppColors.neon.withOpacity(0.04),
              ),
              child: Column(
                children: [
                  Text(
                    'itel Flags',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.neon,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '-vcodec h263 · -s 176x144 · -r 15\n'
                    '-b:v 256k · -acodec amr_nb · -ar 8000\n'
                    '-ac 1 · -ab 12.2k',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 9,
                      color: AppColors.txt2,
                      height: 1.8,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
