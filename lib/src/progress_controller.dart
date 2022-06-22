import 'package:flutter_native_drag_n_drop/src/channel.dart';

class ProgressController {
  final String id;
  final String fileName;

  ProgressController({required this.id, required this.fileName});
  
  updateProgress(int count) {
    FlutterNativeDragNDrop.instance.updateProgress(id, fileName, count);
  }
}