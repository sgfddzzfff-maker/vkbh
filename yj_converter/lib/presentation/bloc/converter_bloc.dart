import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/video_item.dart';
import '../../domain/usecases/pick_videos_usecase.dart';
import '../../domain/usecases/convert_video_usecase.dart';
import '../../domain/repositories/converter_repository.dart';
import 'converter_event.dart';
import 'converter_state.dart';

const int _maxParallel = 3;

class ConverterBloc extends Bloc<ConverterEvent, ConverterState> {
  final PickVideosUseCase pickVideos;
  final ConvertVideoUseCase convertVideo;
  final ConverterRepository repository;

  String? _outputDir;
  final Map<String, StreamSubscription<VideoItem>> _subs = {};

  ConverterBloc({
    required this.pickVideos,
    required this.convertVideo,
    required this.repository,
  }) : super(const ConverterState()) {
    on<PickVideosEvent>(_onPick);
    on<ConvertAllEvent>(_onConvertAll);
    on<RetryItemEvent>(_onRetry);
    on<RemoveItemEvent>(_onRemove);
    on<RenameItemEvent>(_onRename);
    on<ClearDoneEvent>(_onClearDone);
    on<_ItemProgressEvent>(_onItemProgress);
  }

  Future<void> _ensureOutputDir() async {
    _outputDir ??= await repository.getOutputDirectory();
  }

  Future<void> _onPick(PickVideosEvent event, Emitter<ConverterState> emit) async {
    final picked = await pickVideos();
    if (picked.isEmpty) return;
    final updated = [...state.items, ...picked];
    emit(state.copyWith(
      items: updated,
      toastMessage: '✦ تمت إضافة ${picked.length} فيديو',
    ));
    add(ConvertAllEvent());
  }

  void _onConvertAll(ConvertAllEvent event, Emitter<ConverterState> emit) {
    _triggerQueue();
  }

  void _onRetry(RetryItemEvent event, Emitter<ConverterState> emit) {
    final items = state.items.map((i) {
      if (i.id == event.itemId) {
        return i.copyWith(status: ConvertStatus.queued, progress: 0.0);
      }
      return i;
    }).toList();
    emit(state.copyWith(items: items));
    _triggerQueue();
  }

  void _onRemove(RemoveItemEvent event, Emitter<ConverterState> emit) {
    _subs[event.itemId]?.cancel();
    _subs.remove(event.itemId);
    final items = state.items.where((i) => i.id != event.itemId).toList();
    emit(state.copyWith(items: items));
  }

  void _onRename(RenameItemEvent event, Emitter<ConverterState> emit) {
    final items = state.items.map((i) {
      if (i.id == event.itemId) return i.copyWith(outputName: event.newName);
      return i;
    }).toList();
    emit(state.copyWith(items: items));
  }

  void _onClearDone(ClearDoneEvent event, Emitter<ConverterState> emit) {
    final items = state.items
        .where((i) => i.status != ConvertStatus.done)
        .toList();
    emit(state.copyWith(items: items, toastMessage: '🧹 تم حذف المكتملة'));
  }

  void _onItemProgress(_ItemProgressEvent event, Emitter<ConverterState> emit) {
    final items = state.items.map((i) {
      if (i.id == event.item.id) return event.item;
      return i;
    }).toList();
    emit(state.copyWith(items: items));
    if (event.item.status == ConvertStatus.done ||
        event.item.status == ConvertStatus.error) {
      _subs.remove(event.item.id);
      _triggerQueue();
    }
  }

  void _triggerQueue() {
    final active = state.items
        .where((i) => i.status == ConvertStatus.processing)
        .length;
    int slots = _maxParallel - active;
    if (slots <= 0) return;

    for (final item in state.items) {
      if (slots <= 0) break;
      if (item.status == ConvertStatus.queued && !_subs.containsKey(item.id)) {
        _startConvert(item);
        slots--;
      }
    }
  }

  void _startConvert(VideoItem item) {
    _ensureOutputDir().then((_) {
      final sub = convertVideo(item, _outputDir!)
          .listen((updated) => add(_ItemProgressEvent(updated)));
      _subs[item.id] = sub;
    });
  }

  @override
  Future<void> close() {
    for (final sub in _subs.values) {
      sub.cancel();
    }
    _subs.clear();
    return super.close();
  }
}
