import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/video_item.dart';
import '../bloc/converter_bloc.dart';
import '../bloc/converter_event.dart';
import '../bloc/converter_state.dart';
import '../widgets/animated_header.dart';
import '../widgets/stats_strip.dart';
import '../widgets/video_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/neon_fab.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double _scrollY = 0;
  String? _toast;

  void _showToast(String msg) {
    setState(() => _toast = msg);
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ConverterBloc, ConverterState>(
      listenWhen: (p, c) => c.toastMessage != null,
      listener: (context, state) {
        if (state.toastMessage != null) {
          _showToast(state.toastMessage!);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    // Status bar
                    _TopBar(),
                    // Animated header
                    AnimatedHeader(collapsed: _scrollY > 60),
                    // Stats
                    if (state.items.isNotEmpty)
                      StatsStrip(
                        total: state.total,
                        done: state.doneCount,
                        active: state.activeCount,
                        error: state.errorCount,
                      ),
                    // Body
                    Expanded(
                      child: state.items.isEmpty
                          ? EmptyState(
                              onPick: () =>
                                  context.read<ConverterBloc>().add(PickVideosEvent()),
                            )
                          : NotificationListener<ScrollNotification>(
                              onNotification: (n) {
                                if (n is ScrollUpdateNotification) {
                                  setState(() => _scrollY = n.metrics.pixels);
                                }
                                return false;
                              },
                              child: ListView.builder(
                                padding: const EdgeInsets.only(bottom: 100),
                                itemCount: state.items.length,
                                itemBuilder: (_, i) {
                                  final item = state.items[i];
                                  return VideoCard(
                                    key: ValueKey(item.id),
                                    item: item,
                                    index: i,
                                    onRename: (name) => context
                                        .read<ConverterBloc>()
                                        .add(RenameItemEvent(item.id, name)),
                                    onRemove: () => context
                                        .read<ConverterBloc>()
                                        .add(RemoveItemEvent(item.id)),
                                    onRetry: () => context
                                        .read<ConverterBloc>()
                                        .add(RetryItemEvent(item.id)),
                                  );
                                },
                              ),
                            ),
                    ),
                    // Nav hint
                    Container(
                      height: 22,
                      color: Colors.black.withOpacity(0.4),
                      child: Center(
                        child: Container(
                          width: 90, height: 3,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // FABs
                Positioned(
                  right: 14, bottom: 32,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (state.doneCount > 0) ...[
                        NeonFab(
                          size: 42,
                          color: const Color(0xFF334455),
                          icon: const Text('🧹', style: TextStyle(fontSize: 18)),
                          onTap: () => context.read<ConverterBloc>().add(ClearDoneEvent()),
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (state.items.isNotEmpty) ...[
                        NeonFab(
                          size: 50,
                          color: AppColors.neon,
                          icon: const Icon(Icons.play_arrow, color: Colors.white, size: 26),
                          onTap: () => context.read<ConverterBloc>().add(ConvertAllEvent()),
                        ),
                        const SizedBox(height: 10),
                      ],
                      NeonFab(
                        size: 58,
                        color: AppColors.aqua,
                        icon: const Icon(Icons.add, color: Colors.black, size: 28),
                        onTap: () => context.read<ConverterBloc>().add(PickVideosEvent()),
                      ),
                    ],
                  ),
                ),
                // Toast
                if (_toast != null)
                  Positioned(
                    bottom: 88, left: 0, right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 9),
                        decoration: BoxDecoration(
                          color: AppColors.aqua.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                              color: AppColors.aqua.withOpacity(0.27)),
                          boxShadow: [
                            BoxShadow(
                                color: AppColors.aqua.withOpacity(0.2),
                                blurRadius: 24),
                          ],
                        ),
                        child: Text(
                          _toast!,
                          style: GoogleFonts.tajawal(
                            fontSize: 12, color: AppColors.txt1),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TopBar extends StatefulWidget {
  @override
  State<_TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<_TopBar> {
  String _time = '';

  @override
  void initState() {
    super.initState();
    _updateTime();
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 10));
      if (!mounted) return false;
      _updateTime();
      return true;
    });
  }

  void _updateTime() {
    final d = DateTime.now();
    setState(() {
      _time =
          '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
      color: Colors.black.withOpacity(0.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _time,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.txt2,
            ),
          ),
          Row(
            children: [
              ...List.generate(
                3,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  width: 3,
                  height: 6.0 + i * 2,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: AppColors.aqua.withOpacity(0.7 + i * 0.1),
                  ),
                ),
              ),
              const SizedBox(width: 3),
              Container(
                width: 14, height: 7,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: AppColors.aqua.withOpacity(0.4)),
                ),
                child: FractionallySizedBox(
                  widthFactor: 0.75,
                  alignment: Alignment.centerLeft,
                  child: Container(color: AppColors.aqua.withOpacity(0.7)),
                ),
              ),
            ],
          ),
          const Text('⚙', style: TextStyle(fontSize: 12, color: AppColors.txt2)),
        ],
      ),
    );
  }
}
