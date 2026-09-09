// Resizes all PNGs in a directory to a target size (e.g. to match an App
// Store screenshot size Apple accepts). Converts to 8-bit/channel first —
// resizing the 16-bit/channel PNGs the iOS Simulator produces directly
// corrupts colors.
//
// Usage: dart run tool/resize_screenshots.dart <input_dir> <output_dir> [width] [height]
import 'dart:io';
import 'package:image/image.dart' as img;

void main(List<String> args) {
  if (args.length < 2) {
    stderr.writeln('Usage: dart run tool/resize_screenshots.dart <input_dir> <output_dir> [width] [height]');
    exit(1);
  }
  final inputDir = Directory(args[0]);
  final outputDir = Directory(args[1])..createSync(recursive: true);
  final targetWidth = args.length > 2 ? int.parse(args[2]) : 1284;
  final targetHeight = args.length > 3 ? int.parse(args[3]) : 2778;

  for (final entity in inputDir.listSync()) {
    if (entity is! File || !entity.path.endsWith('.png')) continue;
    final decoded = img.decodePng(entity.readAsBytesSync())!;
    final original = decoded.convert(numChannels: 4, format: img.Format.uint8);
    final resized = img.copyResize(
      original,
      width: targetWidth,
      height: targetHeight,
      interpolation: img.Interpolation.cubic,
    );
    final outPath = '${outputDir.path}/${entity.uri.pathSegments.last}';
    File(outPath).writeAsBytesSync(img.encodePng(resized));
    print('Resized ${entity.path} (${original.width}x${original.height}) -> $outPath (${resized.width}x${resized.height})');
  }
}
