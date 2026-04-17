import 'dart:async';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_full/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_full/return_code.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

/// itel 3GP profile:
///   -vcodec h263 -s 176x144 -r 15 -b:v 256k
///   -acodec amr_nb -ar 8000 -ac 1 -b:a 12.2k
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
    final normalizedInput = await _normalizeInputPath(inputPath);
    if (normalizedInput.isEmpty) {
      onLog('Input path غير صالح: $inputPath');
      return false;
    }

    await _requestAndroidPermissions();

    final absoluteInput = p.normalize(p.absolute(normalizedInput));
    final absoluteOutput = p.normalize(p.absolute(outputPath));

    await _ensureDirectoryExists(absoluteOutput);

    FFmpegKitConfig.enableLogCallback((log) {
      onLog(log.getMessage());
    });

    final command = '-y -i "$absoluteInput" '
        '-c:v h263 -s 176x144 -r 15 -b:v 256k '
        '-c:a amr_nb -ar 8000 -ac 1 -b:a 12.2k '
        '"$absoluteOutput"';

    final completer = Completer<bool>();

    await FFmpegKit.executeAsync(
      command,
      (session) async {
        final returnCode = await session.getReturnCode();
        if (ReturnCode.isSuccess(returnCode)) {
          completer.complete(true);
          return;
        }

        final stackTrace = await session.getFailStackTrace();
        onLog('FFmpeg فشل برمز: ${returnCode?.getValue() ?? 'unknown'}');
        if (stackTrace != null && stackTrace.isNotEmpty) {
          onLog(stackTrace);
        }
        completer.complete(false);
      },
      (log) {
        onLog(log.getMessage());
      },
      (statistics) {
        final timeMs = statistics.getTime();
        final progress = videoDurationSec > 0
            ? (timeMs / (videoDurationSec * 1000)).clamp(0.0, 1.0)
            : 0.0;
        onProgress(progress);
      },
    );

    return completer.future;
  }

  Future<String> _normalizeInputPath(String rawPath) async {
    final path = rawPath.trim();
    if (path.isEmpty) return '';

    if (path.startsWith('file://')) {
      return File.fromUri(Uri.parse(path)).path;
    }

    final uri = Uri.tryParse(path);
    if (uri != null && uri.scheme == 'content') {
      final cacheDir = await getTemporaryDirectory();
      final tempFile = File(p.join(cacheDir.path, uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'input_video'));
      return tempFile.path;
    }

    return path;
  }

  Future<void> _ensureDirectoryExists(String absoluteOutputPath) async {
    final directory = Directory(p.dirname(absoluteOutputPath));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
  }

  Future<void> _requestAndroidPermissions() async {
    if (!Platform.isAndroid) return;

    final statuses = await [
      Permission.storage,
      Permission.manageExternalStorage,
      Permission.videos,
    ].request();

    final bool storageGranted = statuses[Permission.storage]?.isGranted == true;
    final bool manageGranted = statuses[Permission.manageExternalStorage]?.isGranted == true;
    final bool videosGranted = statuses[Permission.videos]?.isGranted == true;

    if (!storageGranted && !manageGranted && !videosGranted) {
      throw Exception('يتطلب التطبيق أذونات التخزين أو الفيديو لتشغيل FFmpeg.');
    }
  }
}
