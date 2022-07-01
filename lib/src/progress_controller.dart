import 'package:flutter_native_drag_n_drop/src/channel.dart';
import 'package:meta/meta.dart';

/// An object where you have to pass the current progress of the fileStream in bytes. The system use the progress to update the progress indicator in the filesystem manager(e.g. Finder on macOS)
///
/// [id] identifies this progress controller to their drag file item
/// [fileName] is the corresponding fileName
class ProgressController {
  final String id;
  final String fileName;

  @internal
  ProgressController({required this.id, required this.fileName});

  /// Used [count] to updates the current progress indicator
  ///
  /// [count] is the current progress in bytes
  updateProgress(int count) {
    FlutterNativeDragNDrop.instance.updateProgress(id, fileName, count);
  }
}
