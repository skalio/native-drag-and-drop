import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_native_drag_n_drop/src/native_drag_item.dart';
import 'package:flutter_native_drag_n_drop/src/events.dart';
import 'package:flutter_native_drag_n_drop/src/progress_controller.dart';
import 'dart:typed_data';
import 'channel.dart';
import 'package:meta/meta.dart';
import 'package:visibility_detector/visibility_detector.dart';

typedef OnDragUpdateCallback = void Function(DragEvent event);

/// Callback which is called when the native layer needs the file bytes
///
/// [item] is the corresponding [NativeDragFileItem] object
/// [fileName] is the fileName
/// [url] is the location where the user dropped the drag file item
/// [progressController] must be used to inform about the current progress
/// must return a Stream to write to
typedef FileStreamCallback = Stream<Uint8List> Function(
    NativeDragFileItem item, String fileName, String url, ProgressController progressController);

/// A widget that can be dragged from to a NativeDragTarget.
class NativeDraggable extends StatefulWidget {
  final Widget child;

  /// Drag items when dragging only within application
  final List<NativeDragItem>? items;

  /// Drag file items when dragging out of application
  final List<NativeDragFileItem>? fileItems;

  /// Callback which is called when you drop a drag file item out of application boundary
  final FileStreamCallback fileStreamCallback;

  /// Callback when drag has started
  final OnDragUpdateCallback? onDragStarted;

  /// Callback when drag has moved
  final OnDragUpdateCallback? onDragUpdate;

  /// Callback when drag has ended
  final OnDragUpdateCallback? onDragEnd;

  const NativeDraggable(
      {Key? key,
      required this.child,
      required this.fileStreamCallback,
      this.items,
      this.fileItems,
      this.onDragStarted,
      this.onDragUpdate,
      this.onDragEnd})
      : assert((items == null) != (fileItems == null)),
        super(key: key);

  @override
  DraggableState createState() => DraggableState();
}

class DraggableState extends State<NativeDraggable> {
  final GlobalKey _widgetKey = GlobalKey();

  /// Identifies this receiver across Flutter- and the native-layer
  final UniqueKey uniqueKey = UniqueKey();

  /// List of [ProgressController] objects which controls the progress indicator of every drag file item
  final List<ProgressController> progressControllers = [];

  bool _isVisible = true;

  /// WIP
  //final ScreenshotController _screenshotController = ScreenshotController();
  //Uint8List? _feedbackImage;

  @override
  void initState() {
    super.initState();
    RendererBinding.instance.addPostFrameCallback(_postFrameCallback);
    // ignore: invalid_use_of_protected_member
    FlutterNativeDragNDrop.instance.init();
    FlutterNativeDragNDrop.instance.addDraggableListener(this);

    if (widget.fileItems != null) {
      _createProgressControllers(widget.fileItems!);
    }
  }

  @override
  void didUpdateWidget(covariant NativeDraggable oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.fileItems != null) {
      _createProgressControllers(widget.fileItems!);
    }
  }

  @override
  void dispose() {
    removeDraggableView();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
        key: UniqueKey(),
        child: RepaintBoundary(key: _widgetKey, child: widget.child),
        onVisibilityChanged: (visibilityInfo) {
          if (visibilityInfo.visibleFraction < 1) {
            _isVisible = false;
            removeDraggableView();
          } else {
            _isVisible = true;
          }
        });
  }

  void _postFrameCallback(Duration duration) {
    WidgetsBinding.instance.addPostFrameCallback(_postFrameCallback);

    if (_isVisible) {
      RenderBox? renderBox = _widgetKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        Offset position = renderBox.localToGlobal(Offset.zero);
        FlutterNativeDragNDrop.instance.setDraggableView(uniqueKey.toString(), position, renderBox.size, null,
            (widget.items != null) ? widget.items! : widget.fileItems!);
      }
    }
  }

  void removeDraggableView() {
    FlutterNativeDragNDrop.instance.removeDraggableView(uniqueKey.toString());
    FlutterNativeDragNDrop.instance.removeDraggableListener(this);
  }

  /// WIP
/*
  _captureFeedbackWidget() {
    if (widget.feedback != null) {
      _screenshotController
          .captureFromWidget(widget.feedback!,
              delay: const Duration(milliseconds: 100))
          .then((capturedImage) {
        _feedbackImage = capturedImage;
      });
    }
  }*/

  _createProgressControllers(List<NativeDragFileItem> fileItems) {
    progressControllers.clear();
    for (var item in fileItems) {
      progressControllers.add(ProgressController(id: uniqueKey.toString(), fileName: item.fileName));
    }
  }

  @internal
  Stream<Uint8List> onFileStreamEvent(FileStreamEvent event) {
    final progressController = progressControllers.firstWhere((p) => event.fileName == p.fileName);
    return widget.fileStreamCallback(event.item, event.fileName, event.url, progressController);
  }

  @internal
  void onDragEvent(DragEvent event) {
    if (event is DragBeginEvent) {
      widget.onDragStarted?.call(event);
    } else if (event is DragMovedEvent) {
      widget.onDragUpdate?.call(event);
    } else if (event is DragEndedEvent) {
      widget.onDragEnd?.call(event);
    }
  }
}
