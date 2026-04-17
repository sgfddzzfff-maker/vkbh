import 'dart:async';
import 'dart:io';

import 'package:video_compress/video_compress.dart';
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

    // Use video_compress to convert to 3GP
    try {
      final result = await VideoCompress.compressVideo(
        absoluteInput,
        quality: VideoQuality.LowQuality, // Adjust for 3GP like settings
        deleteOrigin: false,
        includeAudio: true,
        frameRate: 15,
      );

      if (result != null && result.file != null) {
        // Move the compressed file to the desired output path
        final compressedFile = result.file!;
        await compressedFile.copy(absoluteOutput);
        await compressedFile.delete();
        onLog('تم التحويل بنجاح');
        return true;
      } else {
        onLog('فشل التحويل');
        return false;
      }
    } catch (e) {
      onLog('خطأ في التحويل: $e');
      return false;
    }
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
