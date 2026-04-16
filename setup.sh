#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║         YOUSSEF JABER VIDEO CONVERTER — Flutter Setup           ║
# ║         Clean Architecture + BLoC + FFmpeg → 3GP               ║
# ║         Supports: Android & iOS  |  minSdk: 24                 ║
# ╚══════════════════════════════════════════════════════════════════╝
set -euo pipefail

APP_NAME="yj_converter"
APP_DISPLAY="Youssef Jaber Converter"
ORG="com.youssefjaber"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR/$APP_NAME"

# ── Colours for output ──────────────────────────────────────────────
AQUA='\033[38;2;0;229;255m'
NEON='\033[38;2;204;0;255m'
GRN='\033[38;2;0;230;118m'
RED='\033[38;2;255;23;68m'
YLW='\033[38;2;255;215;64m'
RST='\033[0m'

log()  { echo -e "${AQUA}[YJ]${RST} $1"; }
ok()   { echo -e "${GRN}[✓]${RST} $1"; }
warn() { echo -e "${YLW}[!]${RST} $1"; }
err()  { echo -e "${RED}[✗]${RST} $1"; exit 1; }
sec()  { echo -e "\n${NEON}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"; \
         echo -e "${NEON}  $1${RST}"; \
         echo -e "${NEON}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}\n"; }

# ── Pre-flight checks ───────────────────────────────────────────────
sec "🔍 فحص المتطلبات"
command -v flutter >/dev/null 2>&1 || err "Flutter غير مثبت. قم بتثبيته أولاً من flutter.dev"
command -v dart    >/dev/null 2>&1 || err "Dart غير مثبت"
ok "Flutter & Dart متاحان"
flutter --version | head -1

# ── Create Flutter project ──────────────────────────────────────────
sec "🚀 إنشاء مشروع Flutter"
if [ -d "$PROJECT_DIR" ]; then
  warn "المجلد '$APP_NAME' موجود مسبقاً — سيتم الحذف والإعادة"
  rm -rf "$PROJECT_DIR"
fi
flutter create \
  --org "$ORG" \
  --project-name "$APP_NAME" \
  --platforms android,ios \
  --description "Youssef Jaber MP4 to 3GP Video Converter" \
  "$PROJECT_DIR"
ok "تم إنشاء المشروع في $PROJECT_DIR"
cd "$PROJECT_DIR"

# ════════════════════════════════════════════════════════════════════
# ── pubspec.yaml ────────────────────────────────────────────────────
# ════════════════════════════════════════════════════════════════════
sec "📦 كتابة pubspec.yaml"
cat > pubspec.yaml << 'PUBSPEC'
name: yj_converter
description: Youssef Jaber MP4 to 3GP Video Converter
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_bloc: ^8.1.4
  equatable: ^2.0.5
  ffmpeg_kit_flutter_full: ^6.0.3
  file_picker: ^8.0.0+1
  permission_handler: ^11.3.0
  path_provider: ^2.1.3
  path: ^1.9.0
  google_fonts: ^6.2.1
  flutter_animate: ^4.5.0
  gap: ^3.0.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/
PUBSPEC
ok "pubspec.yaml جاهز"

# ── Create asset dirs ───────────────────────────────────────────────
mkdir -p assets

# ════════════════════════════════════════════════════════════════════
# ── Android: build.gradle (app level) ───────────────────────────────
# ════════════════════════════════════════════════════════════════════
sec "🤖 تعديل Android build.gradle"
GRADLE_APP="android/app/build.gradle"
cat > "$GRADLE_APP" << 'GRADLE'
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
}

android {
    namespace "com.youssefjaber.yj_converter"
    compileSdkVersion flutter.compileSdkVersion
    ndkVersion flutter.ndkVersion

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = '1.8'
    }

    sourceSets {
        main.java.srcDirs += 'src/main/kotlin'
    }

    defaultConfig {
        applicationId "com.youssefjaber.yj_converter"
        minSdkVersion 24
        targetSdkVersion flutter.targetSdkVersion
        versionCode flutter.versionCode
        versionName flutter.versionName
        multiDexEnabled true
    }

    buildTypes {
        release {
            signingConfig signingConfigs.debug
            minifyEnabled false
            shrinkResources false
        }
    }
}

flutter {
    source '../..'
}

dependencies {
    implementation 'androidx.multidex:multidex:2.0.1'
}
GRADLE
ok "build.gradle معدّل (minSdkVersion=24)"

# ── Android Manifest permissions ────────────────────────────────────
sec "🔐 إضافة الصلاحيات في AndroidManifest.xml"
MANIFEST="android/app/src/main/AndroidManifest.xml"
cat > "$MANIFEST" << 'MANIFEST'
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- Storage permissions -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
        android:maxSdkVersion="32"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
        android:maxSdkVersion="29"/>
    <uses-permission android:name="android.permission.READ_MEDIA_VIDEO"/>
    <uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE"/>

    <!-- Required for ffmpeg_kit -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
    <uses-permission android:name="android.permission.WAKE_LOCK"/>

    <application
        android:label="YJ Converter"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:requestLegacyExternalStorage="true"
        android:hardwareAccelerated="true">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"/>
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>

        <meta-data
            android:name="flutterEmbedding"
            android:value="2"/>
    </application>

    <queries>
        <intent>
            <action android:name="android.intent.action.VIEW"/>
            <data android:scheme="content"/>
        </intent>
    </queries>
</manifest>
MANIFEST
ok "AndroidManifest.xml جاهز بكل الصلاحيات"

# ════════════════════════════════════════════════════════════════════
# ── iOS: Info.plist permissions ─────────────────────────────────────
# ════════════════════════════════════════════════════════════════════
sec "🍎 إضافة صلاحيات iOS"
IOS_INFO="ios/Runner/Info.plist"
# Inject keys before </dict>
PLIST_KEYS='
	<key>NSPhotoLibraryUsageDescription</key>
	<string>يحتاج التطبيق الوصول إلى مكتبة الصور لاختيار الفيديوهات</string>
	<key>NSPhotoLibraryAddUsageDescription</key>
	<string>يحتاج التطبيق إلى حفظ الفيديوهات المحوّلة</string>
	<key>UISupportsDocumentBrowser</key>
	<true/>
	<key>LSSupportsOpeningDocumentsInPlace</key>
	<true/>'

# Use python3 to inject (safe approach)
python3 - "$IOS_INFO" "$PLIST_KEYS" << 'PYEOF'
import sys, re
path, keys = sys.argv[1], sys.argv[2]
with open(path, 'r') as f:
    content = f.read()
content = content.replace('</dict>\n</plist>', keys + '\n</dict>\n</plist>')
with open(path, 'w') as f:
    f.write(content)
print("iOS Info.plist updated")
PYEOF
ok "Info.plist معدّل"

# ════════════════════════════════════════════════════════════════════
# ── Dart source files ────────────────────────────────────────────────
# Clean Architecture:  lib/
#   core/
#   domain/  entities/ usecases/ repositories/
#   data/    models/ repositories_impl/ datasources/
#   presentation/  bloc/ pages/ widgets/
# ════════════════════════════════════════════════════════════════════
sec "🎯 كتابة ملفات Dart (Clean Architecture)"

mkdir -p lib/core/theme
mkdir -p lib/domain/entities
mkdir -p lib/domain/usecases
mkdir -p lib/domain/repositories
mkdir -p lib/data/models
mkdir -p lib/data/repositories_impl
mkdir -p lib/data/datasources
mkdir -p lib/presentation/bloc
mkdir -p lib/presentation/pages
mkdir -p lib/presentation/widgets

# ── core/theme/app_theme.dart ────────────────────────────────────────
cat > lib/core/theme/app_theme.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class AppColors {
  static const bg       = Color(0xFF08080F);
  static const surface  = Color(0xFF0F0F1C);
  static const surface2 = Color(0xFF161626);
  static const aqua     = Color(0xFF00E5FF);
  static const aquaDim  = Color(0xFF00B8CC);
  static const neon     = Color(0xFFCC00FF);
  static const success  = Color(0xFF00E676);
  static const error    = Color(0xFFFF1744);
  static const warn     = Color(0xFFFFD740);
  static const txt1     = Color(0xFFEEF2FF);
  static const txt2     = Color(0xFF6677AA);
  static const txt3     = Color(0xFF334466);
  static const border   = Color(0x12FFFFFF);
  static const card     = Color(0x0EFFFFFF);
}

class AppTheme {
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.aqua,
      secondary: AppColors.neon,
      surface: AppColors.surface,
      error: AppColors.error,
    ),
    textTheme: GoogleFonts.tajawalTextTheme(ThemeData.dark().textTheme).copyWith(
      headlineLarge: GoogleFonts.scheherazadeNew(
        color: AppColors.txt1,
        fontSize: 40,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: GoogleFonts.scheherazadeNew(
        color: AppColors.txt1,
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: GoogleFonts.tajawal(color: AppColors.txt1, fontSize: 14),
      bodyMedium: GoogleFonts.tajawal(color: AppColors.txt2, fontSize: 12),
    ),
  );
}
DART

# ── domain/entities/video_item.dart ─────────────────────────────────
cat > lib/domain/entities/video_item.dart << 'DART'
import 'package:equatable/equatable.dart';

enum ConvertStatus { queued, processing, done, error }

class VideoItem extends Equatable {
  final String id;
  final String sourcePath;
  final String outputName;
  final String size;
  final String duration;
  final ConvertStatus status;
  final double progress;
  final String? errorMessage;

  const VideoItem({
    required this.id,
    required this.sourcePath,
    required this.outputName,
    required this.size,
    required this.duration,
    this.status = ConvertStatus.queued,
    this.progress = 0.0,
    this.errorMessage,
  });

  VideoItem copyWith({
    String? id,
    String? sourcePath,
    String? outputName,
    String? size,
    String? duration,
    ConvertStatus? status,
    double? progress,
    String? errorMessage,
  }) =>
      VideoItem(
        id: id ?? this.id,
        sourcePath: sourcePath ?? this.sourcePath,
        outputName: outputName ?? this.outputName,
        size: size ?? this.size,
        duration: duration ?? this.duration,
        status: status ?? this.status,
        progress: progress ?? this.progress,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  @override
  List<Object?> get props => [
        id, sourcePath, outputName, size, duration, status, progress, errorMessage
      ];
}
DART

# ── domain/repositories/converter_repository.dart ────────────────────
cat > lib/domain/repositories/converter_repository.dart << 'DART'
import '../entities/video_item.dart';

abstract class ConverterRepository {
  Future<List<VideoItem>> pickVideos();
  Stream<VideoItem> convertVideo(VideoItem item, String outputDir);
  Future<String> getOutputDirectory();
}
DART

# ── domain/usecases/pick_videos_usecase.dart ─────────────────────────
cat > lib/domain/usecases/pick_videos_usecase.dart << 'DART'
import '../entities/video_item.dart';
import '../repositories/converter_repository.dart';

class PickVideosUseCase {
  final ConverterRepository repository;
  PickVideosUseCase(this.repository);

  Future<List<VideoItem>> call() => repository.pickVideos();
}
DART

# ── domain/usecases/convert_video_usecase.dart ───────────────────────
cat > lib/domain/usecases/convert_video_usecase.dart << 'DART'
import '../entities/video_item.dart';
import '../repositories/converter_repository.dart';

class ConvertVideoUseCase {
  final ConverterRepository repository;
  ConvertVideoUseCase(this.repository);

  Stream<VideoItem> call(VideoItem item, String outputDir) =>
      repository.convertVideo(item, outputDir);
}
DART

# ── data/datasources/ffmpeg_datasource.dart ──────────────────────────
cat > lib/data/datasources/ffmpeg_datasource.dart << 'DART'
import 'dart:async';
import 'package:ffmpeg_kit_flutter_full/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_full/log.dart';
import 'package:ffmpeg_kit_flutter_full/statistics.dart';
import 'package:ffmpeg_kit_flutter_full/return_code.dart';

/// itel 3GP profile:
///   -vcodec h263 -s 176x144 -r 15 -b:v 256k
///   -acodec amr_nb -ar 8000 -ac 1 -ab 12.2k
class FfmpegDatasource {
  /// Converts [inputPath] to 3GP using itel settings.
  /// Emits progress values 0.0→1.0 via [onProgress].
  /// Returns true on success.
  Future<bool> convertTo3gp({
    required String inputPath,
    required String outputPath,
    required double videoDurationSec,
    required void Function(double) onProgress,
    required void Function(String) onLog,
  }) async {
    final completer = Completer<bool>();

    FFmpegKitConfig.enableStatisticsCallback((Statistics stats) {
      if (videoDurationSec > 0) {
        final timeSec = stats.getTime() / 1000.0;
        final prog = (timeSec / videoDurationSec).clamp(0.0, 1.0);
        onProgress(prog);
      }
    });

    FFmpegKitConfig.enableLogCallback((Log log) {
      onLog(log.getMessage());
    });

    await FFmpegKit.executeAsync(
      '-y -i "$inputPath" '
      '-vcodec h263 '
      '-s 176x144 '
      '-r 15 '
      '-b:v 256k '
      '-acodec amr_nb '
      '-ar 8000 '
      '-ac 1 '
      '-ab 12200 '
      '"$outputPath"',
      (session) async {
        final rc = await session.getReturnCode();
        completer.complete(ReturnCode.isSuccess(rc));
      },
    );

    return completer.future;
  }
}
DART

# ── data/repositories_impl/converter_repository_impl.dart ────────────
cat > lib/data/repositories_impl/converter_repository_impl.dart << 'DART'
import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/video_item.dart';
import '../../domain/repositories/converter_repository.dart';
import '../datasources/ffmpeg_datasource.dart';

class ConverterRepositoryImpl implements ConverterRepository {
  final FfmpegDatasource ffmpeg;
  ConverterRepositoryImpl(this.ffmpeg);

  @override
  Future<List<VideoItem>> pickVideos() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: true,
    );
    if (result == null || result.files.isEmpty) return [];

    return result.files.map((f) {
      final sizeBytes = f.size;
      final sizeMb = (sizeBytes / (1024 * 1024)).toStringAsFixed(1);
      return VideoItem(
        id: '${f.name}_${DateTime.now().microsecondsSinceEpoch}',
        sourcePath: f.path ?? '',
        outputName: p.basenameWithoutExtension(f.name),
        size: '$sizeMb MB',
        duration: '--:--',
        status: ConvertStatus.queued,
      );
    }).toList();
  }

  @override
  Future<String> getOutputDirectory() async {
    Directory dir;
    if (Platform.isAndroid) {
      dir = Directory('/storage/emulated/0/Download/Youssef_Jaber_Converter');
    } else {
      final docs = await getApplicationDocumentsDirectory();
      dir = Directory('${docs.path}/Youssef_Jaber_Converter');
    }
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  @override
  Stream<VideoItem> convertVideo(VideoItem item, String outputDir) {
    final controller = StreamController<VideoItem>();

    Future<void> run() async {
      // Mark as processing
      controller.add(item.copyWith(status: ConvertStatus.processing, progress: 0.0));

      final outputPath = p.join(outputDir, '${item.outputName}.3gp');

      // Estimate duration from filename (simple heuristic; real apps use MediaMetadata)
      const fallbackDuration = 120.0;

      final success = await ffmpeg.convertTo3gp(
        inputPath: item.sourcePath,
        outputPath: outputPath,
        videoDurationSec: fallbackDuration,
        onProgress: (prog) {
          controller.add(item.copyWith(
            status: ConvertStatus.processing,
            progress: prog,
          ));
        },
        onLog: (_) {},
      );

      if (success) {
        controller.add(item.copyWith(status: ConvertStatus.done, progress: 1.0));
      } else {
        controller.add(item.copyWith(
          status: ConvertStatus.error,
          errorMessage: 'FFmpeg exit code 1 · codec incompatible',
        ));
      }
    }

    run().catchError((e) {
      controller.add(item.copyWith(
        status: ConvertStatus.error,
        errorMessage: e.toString(),
      ));
    }).whenComplete(() => controller.close());

    return controller.stream;
  }
}
DART

# ── presentation/bloc/converter_event.dart ───────────────────────────
cat > lib/presentation/bloc/converter_event.dart << 'DART'
import 'package:equatable/equatable.dart';
import '../../domain/entities/video_item.dart';

abstract class ConverterEvent extends Equatable {
  const ConverterEvent();
  @override
  List<Object?> get props => [];
}

class PickVideosEvent extends ConverterEvent {}

class ConvertAllEvent extends ConverterEvent {}

class RetryItemEvent extends ConverterEvent {
  final String itemId;
  const RetryItemEvent(this.itemId);
  @override
  List<Object?> get props => [itemId];
}

class RemoveItemEvent extends ConverterEvent {
  final String itemId;
  const RemoveItemEvent(this.itemId);
  @override
  List<Object?> get props => [itemId];
}

class RenameItemEvent extends ConverterEvent {
  final String itemId;
  final String newName;
  const RenameItemEvent(this.itemId, this.newName);
  @override
  List<Object?> get props => [itemId, newName];
}

class ClearDoneEvent extends ConverterEvent {}

class _ItemProgressEvent extends ConverterEvent {
  final VideoItem item;
  const _ItemProgressEvent(this.item);
  @override
  List<Object?> get props => [item];
}
DART

# ── presentation/bloc/converter_state.dart ───────────────────────────
cat > lib/presentation/bloc/converter_state.dart << 'DART'
import 'package:equatable/equatable.dart';
import '../../domain/entities/video_item.dart';

class ConverterState extends Equatable {
  final List<VideoItem> items;
  final String? toastMessage;

  const ConverterState({
    this.items = const [],
    this.toastMessage,
  });

  ConverterState copyWith({
    List<VideoItem>? items,
    String? toastMessage,
  }) =>
      ConverterState(
        items: items ?? this.items,
        toastMessage: toastMessage,
      );

  int get total     => items.length;
  int get doneCount => items.where((i) => i.status == ConvertStatus.done).length;
  int get activeCount => items.where((i) => i.status == ConvertStatus.processing).length;
  int get errorCount => items.where((i) => i.status == ConvertStatus.error).length;

  @override
  List<Object?> get props => [items, toastMessage];
}
DART

# ── presentation/bloc/converter_bloc.dart ────────────────────────────
cat > lib/presentation/bloc/converter_bloc.dart << 'DART'
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
DART

# ── presentation/widgets/animated_header.dart ────────────────────────
cat > lib/presentation/widgets/animated_header.dart << 'DART'
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
DART

# ── presentation/widgets/stats_strip.dart ────────────────────────────
cat > lib/presentation/widgets/stats_strip.dart << 'DART'
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
DART

# ── presentation/widgets/video_card.dart ─────────────────────────────
cat > lib/presentation/widgets/video_card.dart << 'DART'
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
DART

# ── presentation/widgets/empty_state.dart ────────────────────────────
cat > lib/presentation/widgets/empty_state.dart << 'DART'
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
DART

# ── presentation/widgets/neon_fab.dart ───────────────────────────────
cat > lib/presentation/widgets/neon_fab.dart << 'DART'
import 'package:flutter/material.dart';

class NeonFab extends StatefulWidget {
  final Widget icon;
  final Color color;
  final VoidCallback onTap;
  final double size;

  const NeonFab({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
    this.size = 54,
  });

  @override
  State<NeonFab> createState() => _NeonFabState();
}

class _NeonFabState extends State<NeonFab> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.87 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.6),
                blurRadius: _pressed ? 8 : 26,
              ),
              const BoxShadow(
                color: Colors.black54,
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Center(child: widget.icon),
        ),
      ),
    );
  }
}
DART

# ── presentation/pages/home_page.dart ────────────────────────────────
cat > lib/presentation/pages/home_page.dart << 'DART'
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
DART

# ── main.dart ─────────────────────────────────────────────────────────
cat > lib/main.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import 'core/theme/app_theme.dart';
import 'data/datasources/ffmpeg_datasource.dart';
import 'data/repositories_impl/converter_repository_impl.dart';
import 'domain/usecases/pick_videos_usecase.dart';
import 'domain/usecases/convert_video_usecase.dart';
import 'presentation/bloc/converter_bloc.dart';
import 'presentation/pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF08080F),
  ));

  // Request permissions
  await _requestPermissions();

  runApp(const YJConverterApp());
}

Future<void> _requestPermissions() async {
  await [
    Permission.storage,
    Permission.manageExternalStorage,
    Permission.videos,
  ].request();
}

class YJConverterApp extends StatelessWidget {
  const YJConverterApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ffmpeg = FfmpegDatasource();
    final repo   = ConverterRepositoryImpl(ffmpeg);

    return BlocProvider(
      create: (_) => ConverterBloc(
        pickVideos:   PickVideosUseCase(repo),
        convertVideo: ConvertVideoUseCase(repo),
        repository:   repo,
      ),
      child: MaterialApp(
        title: 'YJ Converter',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const HomePage(),
        builder: (context, child) {
          // Force RTL for Arabic UI
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          );
        },
      ),
    );
  }
}
DART

ok "كافة ملفات Dart كُتبت بنجاح (Clean Architecture + BLoC)"

# ════════════════════════════════════════════════════════════════════
# ── flutter pub get ──────────────────────────────────────────────────
# ════════════════════════════════════════════════════════════════════
sec "📥 تنزيل الحزم (flutter pub get)"
flutter pub get
ok "تم تنزيل كافة الحزم"

# ════════════════════════════════════════════════════════════════════
# ── flutter build apk --release ─────────────────────────────────────
# ════════════════════════════════════════════════════════════════════
sec "🏗️  بناء APK (Release)"
flutter build apk --release

APK_PATH="$PROJECT_DIR/build/app/outputs/flutter-apk/app-release.apk"
if [ -f "$APK_PATH" ]; then
  APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
  echo ""
  echo -e "${NEON}╔══════════════════════════════════════════════════════════╗${RST}"
  echo -e "${NEON}║${RST}  ${GRN}✓ بناء APK اكتمل بنجاح!${RST}                              ${NEON}║${RST}"
  echo -e "${NEON}║${RST}  📦 الحجم : ${YLW}$APK_SIZE${RST}                                    ${NEON}║${RST}"
  echo -e "${NEON}║${RST}  📍 المسار: ${AQUA}build/app/outputs/flutter-apk/${RST}               ${NEON}║${RST}"
  echo -e "${NEON}║${RST}       ${AQUA}app-release.apk${RST}                                   ${NEON}║${RST}"
  echo -e "${NEON}╚══════════════════════════════════════════════════════════╝${RST}"
  echo ""
  echo -e "${GRN}لتثبيت التطبيق مباشرةً على جهازك المتصل:${RST}"
  echo -e "  ${AQUA}adb install -r $APK_PATH${RST}"
else
  warn "لم يُعثر على APK في المسار المتوقع — راجع أخطاء البناء أعلاه."
fi
