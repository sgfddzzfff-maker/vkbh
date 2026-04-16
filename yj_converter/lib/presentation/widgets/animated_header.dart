import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class AnimatedHeader extends StatefulWidget {
  final bool collapsed;
  const AnimatedHeader({super.key, required this.collapsed});

  @override
  State<AnimatedHeader> createState() => _AnimatedHeaderState();
}

class _AnimatedHeaderState extends State<AnimatedHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final p = _pulse.value;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          height: widget.collapsed ? 64 : 188,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.fromRGBO(8 + (p * 12).round(), 8 + (p * 4).round(),
                    20 + (p * 18).round(), 1),
                Color.fromRGBO(2 + (p * 10).round(), 2 + (p * 5).round(),
                    30 + (p * 20).round(), 1),
                const Color(0xFF050510),
              ],
            ),
            border: const Border(
              bottom: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: Stack(
            children: [
              // Grid
              Positioned.fill(
                child: CustomPaint(
                  painter: _GridPainter(),
                ),
              ),
              // Neon orb left
              Positioned(
                left: MediaQuery.of(context).size.width * 0.08,
                top: widget.collapsed ? 0 : 20,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      AppColors.neon.withOpacity(0.18 + p * 0.1),
                      Colors.transparent,
                    ]),
                  ),
                ),
              ),
              // Aqua orb right
              Positioned(
                right: MediaQuery.of(context).size.width * 0.1,
                bottom: 10,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      AppColors.aqua.withOpacity(0.14 + p * 0.08),
                      Colors.transparent,
                    ]),
                  ),
                ),
              ),
              // Content
              Positioned(
                left: 18, right: 18, bottom: 14,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!widget.collapsed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          '✦ YOUSSEF JABER ✦ VIDEO CONVERTER ✦',
                          style: GoogleFonts.tajawal(
                            fontSize: 9,
                            letterSpacing: 4,
                            color: AppColors.aqua.withOpacity(0.67),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          AppColors.txt1,
                          AppColors.aqua,
                          AppColors.neon,
                          AppColors.txt1,
                        ],
                        stops: [0.0, 0.3, 0.55, 0.8],
                      ).createShader(bounds),
                      child: Text(
                        'يوسف جابر',
                        style: GoogleFonts.scheherazadeNew(
                          fontSize: widget.collapsed ? 22 : 40,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                    ),
                    if (!widget.collapsed)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            _PulsingDot(color: AppColors.aqua),
                            const SizedBox(width: 8),
                            Text(
                              'Youssef Jaber',
                              style: GoogleFonts.scheherazadeNew(
                                fontSize: 13,
                                letterSpacing: 1.5,
                                color: AppColors.aqua.withOpacity(0.8),
                              ),
                            ),
                            const Spacer(),
                            ...[
                              'MP4→3GP', 'itel', 'H.263'
                            ].map((t) => _Badge(label: t)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  const _Badge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.aqua.withOpacity(0.27)),
        color: AppColors.aqua.withOpacity(0.08),
      ),
      child: Text(
        label,
        style: GoogleFonts.tajawal(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: AppColors.aqua,
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Container(
        width: 7, height: 7,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color,
          boxShadow: [BoxShadow(color: widget.color, blurRadius: 6 + _c.value * 8)],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.aqua.withOpacity(0.07)
      ..strokeWidth = 1;
    const step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override
  bool shouldRepaint(_) => false;
}
