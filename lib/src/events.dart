import 'package:flutter/gestures.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_native_drag_n_drop/src/native_drag_item.dart';

abstract class DropEvent {
  List<NativeDragItem> items;
  Offset location;
  DropEvent(this.location, this.items);
}

class DropEnterEvent extends DropEvent {
  DropEnterEvent({required Offset location, required List<NativeDragItem> items}) : super(location, items);
}

class DropExitEvent extends DropEvent {
  DropExitEvent({required Offset location, required List<NativeDragItem> items}) : super(location, items);
}

class DropUpdateEvent extends DropEvent {
  DropUpdateEvent({required Offset location, required List<NativeDragItem> items}) : super(location, items);
}

class DropDoneEvent extends DropEvent {
  DropDoneEvent({required Offset location, required List<NativeDragItem> items}) : super(location, items);
}

abstract class DragEvent {
  // global position of the dragged cursor
  Offset location;
  DragEvent(this.location);
}

class DragBeginEvent extends DragEvent {
  DragBeginEvent({required Offset location}) : super(location);
}

class DragMovedEvent extends DragEvent {
  DragMovedEvent({required Offset location}) : super(location);
}

class DragEndedEvent extends DragEvent {
  DragEndedEvent({required Offset location}) : super(location);
}

class FileStreamEvent {
  final NativeDragFileItem item;
  final String fileName;
  final String url;
  FileStreamEvent(this.item, this.fileName, this.url);
}