import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/video_item.dart';

const _palettes = [
  [Color(0xFF0D001F), Color(0xFFCC00FF)],
  [Color(0xFF001520), Color(0xFF00E5FF)],
  [Color(0xFF0A1A00), Color(0xFF00E676)],
  [Color(0xFF1A0800), Color(0xFFFF6D00)],
  [Color(0xFF001A1A), Color(0xFF00BCD4)],
  [Color(0xFF1A001A), Color(0xFFE040FB)],
];

class VideoCard extends StatefulWidget {
  final VideoItem item;
  final int index;
  final void Function(String) onRename;
  final VoidCallback onRemove;
  final VoidCallback onRetry;

  const VideoCard({
    super.key,
    required this.item,
    required this.index,
    required this.onRename,
    required this.onRemove,
    required this.onRetry,
  });

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> {
  bool _pressed = false;
  bool _editing = false;
  late TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.item.outputName);
  }

  @override
  void didUpdateWidget(VideoCard old) {
    super.didUpdateWidget(old);
    if (!_editing && old.item.outputName != widget.item.outputName) {
      _nameCtrl.text = widget.item.outputName;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Color get _statusColor => switch (widget.item.status) {
        ConvertStatus.queued     => AppColors.txt2,
        ConvertStatus.processing => AppColors.aqua,
        ConvertStatus.done       => AppColors.success,
        ConvertStatus.error      => AppColors.error,
      };

  String get _statusLabel => switch (widget.item.status) {
        ConvertStatus.queued     => '◷ في الانتظار',
        ConvertStatus.processing => '⚙ جارٍ التحويل',
        ConvertStatus.done       => '✓ مكتمل',
        ConvertStatus.error      => '✕ خطأ',
      };

  @override
  Widget build(BuildContext context) {
    final palette = _palettes[widget.index % _palettes.length];
    final bg = palette[0];
    final accent = palette[1];

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.975 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _statusColor.withOpacity(0.16)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 20),
              BoxShadow(color: _statusColor.withOpacity(0.06), blurRadius: 0, spreadRadius: 0.5),
            ],
          ),
          child: Column(
            children: [
              // Top row
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thumbnail
                    Container(
                      width: 62, height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [bg, Colors.black],
                        ),
                        border: Border.all(color: accent.withOpacity(0.2)),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Icon(Icons.play_arrow, color: accent.withOpacity(0.8), size: 22),
                          ),
                          Positioned(
                            bottom: 3, right: 4,
                            child: Text(
                              widget.item.duration,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                color: Color(0xAABBBBBB),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Center info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _editing
                              ? TextField(
                                  autofocus: true,
                                  controller: _nameCtrl,
                                  style: GoogleFonts.tajawal(
                                    fontSize: 12.5, color: AppColors.txt1),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.09),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(9),
                                      borderSide: const BorderSide(
                                          color: AppColors.aqua, width: 1.5),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(9),
                                      borderSide: const BorderSide(
                                          color: AppColors.aqua, width: 1.5),
                                    ),
                                  ),
                                  onSubmitted: (v) {
                                    setState(() => _editing = false);
                                    widget.onRename(v.trim().isEmpty
                                        ? widget.item.outputName
                                        : v.trim());
                                  },
                                  onEditingComplete: () {
                                    setState(() => _editing = false);
                                    widget.onRename(_nameCtrl.text.trim().isEmpty
                                        ? widget.item.outputName
                                        : _nameCtrl.text.trim());
                                  },
                                )
                              : GestureDetector(
                                  onTap: () => setState(() => _editing = true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            widget.item.outputName,
                                            style: GoogleFonts.tajawal(
                                              fontSize: 12.5,
                                              color: AppColors.txt1,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          '.3gp',
                                          style: GoogleFonts.tajawal(
                                            fontSize: 9,
                                            color: AppColors.aqua.withOpacity(0.53),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              _PulsingStatusDot(
                                color: _statusColor,
                                animate: widget.item.status == ConvertStatus.processing,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _statusLabel,
                                style: GoogleFonts.tajawal(
                                  fontSize: 10, color: _statusColor),
                              ),
                              const Spacer(),
                              Text(
                                widget.item.size,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 9,
                                  color: AppColors.txt3,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Actions
                    Column(
                      children: [
                        if (widget.item.status == ConvertStatus.error)
                          _ActionBtn(
                            icon: Icons.refresh,
                            color: AppColors.warn,
                            onTap: widget.onRetry,
                          ),
                        const SizedBox(height: 3),
                        _ActionBtn(
                          icon: Icons.close,
                          color: AppColors.error,
                          onTap: widget.onRemove,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Progress bar
              if (widget.item.status == ConvertStatus.processing)
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: SizedBox(
                          height: 4,
                          child: LinearProgressIndicator(
                            value: widget.item.progress,
                            backgroundColor: AppColors.surface2,
                            valueColor: AlwaysStoppedAnimation(AppColors.aqua),
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'FFmpeg · H.263 · AMR-NB',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 9,
                              color: AppColors.aqua,
                            ),
                          ),
                          Text(
                            '${(widget.item.progress * 100).round()}%',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.aqua,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              // Done banner
              if (widget.item.status == ConvertStatus.done)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Text(
                    '✓ محفوظ في Download/Youssef_Jaber_Converter/',
                    style: GoogleFonts.tajawal(
                      fontSize: 10, color: AppColors.success),
                  ),
                ),
              // Error banner
              if (widget.item.status == ConvertStatus.error)
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                  child: Text(
                    widget.item.errorMessage ?? 'FFmpeg exit code 1',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: AppColors.error,
                    ),
                  ),
                ),
            ],
          ),
        )
            .animate(delay: Duration(milliseconds: widget.index * 40))
            .fadeIn(duration: 350.ms)
            .slideY(begin: 0.14, end: 0, duration: 350.ms),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: color.withOpacity(0.08),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Icon(icon, color: color.withOpacity(0.73), size: 16),
      ),
    );
  }
}

class _PulsingStatusDot extends StatefulWidget {
  final Color color;
  final bool animate;
  const _PulsingStatusDot({required this.color, required this.animate});

  @override
  State<_PulsingStatusDot> createState() => _PulsingStatusDotState();
}

class _PulsingStatusDotState extends State<_PulsingStatusDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Container(
        width: 5, height: 5,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color,
          boxShadow: widget.animate
              ? [BoxShadow(color: widget.color, blurRadius: 4 + _c.value * 4)]
              : null,
        ),
      ),
    );
  }
}
