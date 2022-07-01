import 'package:flutter/gestures.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_native_drag_n_drop/src/native_drag_item.dart';

/// Base class for drop events, mainly used by [NativeDropTarget]
///
/// [items] is list of drag items
/// [location] is the global location of the cursor
abstract class DropEvent {
  List<NativeDragItem> items;
  Offset location;
  DropEvent(this.location, this.items);
}

/// Event object when drop has entered the drop target area
class DropEnterEvent extends DropEvent {
  DropEnterEvent(
      {required Offset location, required List<NativeDragItem> items})
      : super(location, items);
}

/// Event object when drag has exited the drop target area
class DropExitEvent extends DropEvent {
  DropExitEvent({required Offset location, required List<NativeDragItem> items})
      : super(location, items);
}

/// Event object when drag has moved on a drop target
class DropUpdateEvent extends DropEvent {
  DropUpdateEvent(
      {required Offset location, required List<NativeDragItem> items})
      : super(location, items);
}

/// Event object when drop has finished
class DropDoneEvent extends DropEvent {
  DropDoneEvent({required Offset location, required List<NativeDragItem> items})
      : super(location, items);
}

/// Base class for drag events, mainly used by [NativeDraggable]
///
/// [location] is the global location of the cursor
abstract class DragEvent {
  Offset location;
  DragEvent(this.location);
}

/// Event object when drag has started
class DragBeginEvent extends DragEvent {
  DragBeginEvent({required Offset location}) : super(location);
}

/// Event object when drag has moved
class DragMovedEvent extends DragEvent {
  DragMovedEvent({required Offset location}) : super(location);
}

/// Event object when drag has ended
class DragEndedEvent extends DragEvent {
  DragEndedEvent({required Offset location}) : super(location);
}

/// Event object which is fired when native layer needs the fileStream to write the file
class FileStreamEvent {
  final NativeDragFileItem item;
  final String fileName;
  final String url;
  FileStreamEvent(this.item, this.fileName, this.url);
}
