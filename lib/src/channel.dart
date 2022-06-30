import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'events.dart';
import 'native_drag_item.dart';
import 'native_draggable.dart' as d;

typedef RawDropListener = void Function(DropEvent);

class FlutterNativeDragNDrop {
  static const MethodChannel _channel =
      MethodChannel('flutter_native_drag_n_drop');
  static final instance = FlutterNativeDragNDrop._();

  FlutterNativeDragNDrop._();

  final _dropListeners = <RawDropListener>{};
  final _draggableListeners = <d.DraggableState>{};
  late List<NativeDragItem> _draggedItems;
  Offset? _offset;

  var _initialized = false;
  init() {
    if (_initialized) {
      return;
    }
    _initialized = true;
    FlutterNativeDragNDrop._channel.setMethodCallHandler((call) async {
      return _handleMethodChannel(call);
    });
  }

  /// This method creates the draggable view and dropTargetView on native side
  setDraggableView<T extends Object>(String id, Offset position, Size size,
      Uint8List? image, List<NativeDragItem> items) async {
    _draggedItems = items;

    if (items.first is NativeDragFileItem) {
      final fileItems = _draggedItems.map((e) => e as NativeDragFileItem);
      await _channel.invokeMethod("setDraggableView", <String, dynamic>{
        "id": id,
        "x": position.dx,
        "y": position.dy,
        "width": size.width,
        "height": size.height,
        "image": image,
        "names": fileItems.map((e) => e.name).toList(),
        "fileNames": fileItems.map((e) => e.fileName).toList(),
        "fileSizes": fileItems.map((e) => e.fileSize).toList()
      });
    } else {
      await _channel.invokeMethod("setDraggableView", <String, dynamic>{
        "id": id,
        "x": position.dx,
        "y": position.dy,
        "width": size.width,
        "height": size.height,
        "image": image,
        "names": _draggedItems.map((e) => e.name).toList()
      });
    }
  }

  /// This method removes the draggable view and dropTargetView on native side
  removeDraggableView(String id) async {
    await _channel
        .invokeMethod("removeDraggableView", <String, dynamic>{"id": id});
  }

  updateProgress(String id, String fileName, int count) {
    _channel.invokeMethod("updateProgress",
        <String, dynamic>{"id": id, "fileName": fileName, "count": count});
  }

  Future<dynamic> _handleMethodChannel(MethodCall call) async {
    switch (call.method) {
      case "draggingEntered":
        final position = (call.arguments as List).cast<double>();
        _offset = Offset(position[0], position[1]);
        _notifyDropEvent(DropEnterEvent(location: _offset!, items: _draggedItems));
        break;
      case "draggingUpdated":
        final position = (call.arguments as List).cast<double>();
        _offset = Offset(position[0], position[1]);
        _notifyDropEvent(DropUpdateEvent(location: _offset!, items: _draggedItems));
        break;
      case "draggingExited":
        _notifyDropEvent(DropExitEvent(location: _offset ?? Offset.zero, items: _draggedItems));
        _offset = null;
        break;
      case "performDragOperation":
        _notifyDropEvent(DropDoneEvent(location: _offset ?? Offset.zero, items: _draggedItems));
        _offset = null;
        break;
      case "draggingBegin":
        final arguments = Map.from(call.arguments);
        final id = arguments["id"] as String;
        final position = (arguments["position"] as List).cast<double>();
        _notifyDragEvent(id, DragBeginEvent(location: Offset(position[0], position[1])));
        break;
      case "draggingMoved":
        final arguments = Map.from(call.arguments);
        final id = arguments["id"] as String;
        final position = (arguments["position"] as List).cast<double>();
        _notifyDragEvent(id, DragMovedEvent(location: Offset(position[0], position[1])));
        break;
      case "draggingEnded":
        final arguments = Map.from(call.arguments);
        final id = arguments["id"] as String;
        final position = (arguments["position"] as List).cast<double>();
        _notifyDragEvent(id, DragEndedEvent(location: Offset(position[0], position[1])));
        break;
      case "fileStreamCallback":
        final arguments = Map.from(call.arguments);
        final id = arguments["id"] as String;
        final fileName = arguments["fileName"] as String;
        final url = arguments["url"] as String;
        final item = _draggedItems.firstWhere((i) => i.name == fileName) as NativeDragFileItem;
        _notifyFileStreamEvent(id, FileStreamEvent(item, fileName, url));
        break;
      default:
        throw UnimplementedError('${call.method} not implement.');
    }
  }

  void _notifyDropEvent(DropEvent event) {
    for (final listener in _dropListeners) {
      listener(event);
    }
  }

  void addRawDropEventListener(RawDropListener listener) {
    _dropListeners.add(listener);
  }

  void removeRawDropEventListener(RawDropListener listener) {
    _dropListeners.remove(listener);
  }

  void _notifyDragEvent(String id, DragEvent event) {
    for (final listener in _draggableListeners) {
      if (id == listener.uniqueKey.toString()) {
        listener.onDragEvent(event);
      }
    }
  }

  _notifyFileStreamEvent(String id, FileStreamEvent event) async {
    for (final listener in _draggableListeners) {
      if (id == listener.uniqueKey.toString()) {
        _listenToFileStream(
            id, event.fileName, listener.onFileStreamEvent(event));
      }
    }
  }

  _listenToFileStream(String id, String fileName, Stream<Uint8List> stream) {
    stream.listen(
      (data) {
        _channel.invokeMethod(
            "feedFileStream", <String, dynamic>{"id": id, "fileName": fileName, "data": data, "status": "kWriting"});
      },
      onDone: () {
        _channel.invokeMethod(
            "feedFileStream", <String, dynamic>{"id": id, "fileName": fileName, "data": null, "status": "kEnded"});
      },
    );
  }

  void addDraggableListener(d.DraggableState listener) {
    _draggableListeners.add(listener);
  }

  void removeDraggableListener(d.DraggableState listener) {
    _draggableListeners.remove(listener);
  }
}
