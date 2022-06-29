import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_native_drag_n_drop/src/native_drag_item.dart';
import 'package:flutter_native_drag_n_drop/src/events.dart';
import 'package:flutter_native_drag_n_drop/src/progress_controller.dart';
import 'dart:typed_data';
import 'channel.dart';

typedef OnDragUpdateCallback = void Function(DragEvent event);
typedef FileStreamCallback = Stream<Uint8List> Function(NativeDragFileItem item,
    String fileName, String url, ProgressController progressController);

/// A widget that can be dragged from to a NativeDragTarget.
class NativeDraggable extends StatefulWidget {
  final Widget child;
  final List<NativeDragItem>? items;
  final List<NativeDragFileItem>? fileItems;
  final FileStreamCallback fileStreamCallback;
  final OnDragUpdateCallback? onDragStarted;
  final OnDragUpdateCallback? onDragUpdate;
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
  final UniqueKey uniqueKey = UniqueKey();
  final List<ProgressController> progressControllers = [];

  /// WIP
  //final ScreenshotController _screenshotController = ScreenshotController();
  //Uint8List? _feedbackImage;

  @override
  void initState() {
    super.initState();
    RendererBinding.instance.addPostFrameCallback(_postFrameCallback);
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
    FlutterNativeDragNDrop.instance.removeDraggableView(uniqueKey.toString());
    FlutterNativeDragNDrop.instance.removeDraggableListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(key: _widgetKey, child: widget.child);
  }

  void _postFrameCallback(Duration duration) {
    WidgetsBinding.instance.addPostFrameCallback(_postFrameCallback);

    RenderBox? renderBox =
        _widgetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      Offset position = renderBox.localToGlobal(Offset.zero);
      FlutterNativeDragNDrop.instance.setDraggableView(
          uniqueKey.toString(),
          position,
          renderBox.size,
          null,
          (widget.items != null) ? widget.items! : widget.fileItems!);
    }
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
      progressControllers.add(ProgressController(
          id: uniqueKey.toString(), fileName: item.fileName));
    }
  }

  Stream<Uint8List> onFileStreamEvent(FileStreamEvent event) {
    final progressController =
        progressControllers.firstWhere((p) => event.fileName == p.fileName);
    return widget.fileStreamCallback(
        event.item, event.fileName, event.url, progressController);
  }

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
