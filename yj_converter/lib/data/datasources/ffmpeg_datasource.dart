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
