import 'package:flutter/widgets.dart';
import 'package:flutter_native_drag_n_drop/src/channel.dart';
import 'package:flutter_native_drag_n_drop/src/native_drag_item.dart';
import 'events.dart';

@immutable
class DropDoneDetails {
  const DropDoneDetails({required this.items, required this.localPosition, required this.globalPosition});

  final List<NativeDragItem> items;
  final Offset localPosition;
  final Offset globalPosition;
}

class DropEventDetails {
  DropEventDetails({required this.items, required this.localPosition, required this.globalPosition});

  final List<NativeDragItem> items;
  final Offset localPosition;
  final Offset globalPosition;
}

typedef OnDragDoneCallback = void Function(DropDoneDetails details);
typedef OnDragCallback<Detail> = void Function(Detail details);
typedef DragTargetWillAccept<T extends Object> = bool Function(List<NativeDragItem> items);

/// A widget that accepts draggable files.
class NativeDropTarget extends StatefulWidget {
  const NativeDropTarget({
    Key? key,
    required this.builder,
    this.onDragEntered,
    this.onDragExited,
    this.onDragUpdated,
    this.onWillAccept,
    this.onDragDone,
    this.enable = true,
  }) : super(key: key);

  final DragTargetBuilder<NativeDragItem> builder;
  final OnDragCallback<DropEventDetails>? onDragEntered;
  final OnDragCallback<DropEventDetails>? onDragExited;
  final OnDragCallback<DropEventDetails>? onDragUpdated;
  final DragTargetWillAccept? onWillAccept;
  final OnDragDoneCallback? onDragDone;

  final bool enable;

  @override
  State<NativeDropTarget> createState() => _DropTargetState();
}

enum _DragTargetStatus {
  enter,
  update,
  idle,
}

class _DropTargetState extends State<NativeDropTarget> {
  _DragTargetStatus _status = _DragTargetStatus.idle;
  List<NativeDragItem> _acceptedData = [];
  List<NativeDragItem> _rejectedData = [];

  @override
  void initState() {
    super.initState();
    FlutterNativeDragNDrop.instance.init();
    if (widget.enable) {
      FlutterNativeDragNDrop.instance.addRawDropEventListener(_onDropEvent);
    }
  }

  @override
  void didUpdateWidget(NativeDropTarget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enable && !oldWidget.enable) {
      FlutterNativeDragNDrop.instance.addRawDropEventListener(_onDropEvent);
    } else if (!widget.enable && oldWidget.enable) {
      FlutterNativeDragNDrop.instance.removeRawDropEventListener(_onDropEvent);
      if (_status != _DragTargetStatus.idle) {
        _updateStatus(_DragTargetStatus.idle, localLocation: Offset.zero, globalLocation: Offset.zero, items: []);
      }
    }
  }

  void _onDropEvent(DropEvent event) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return;
    }
    final globalPosition = event.location;
    final position = renderBox.globalToLocal(globalPosition);
    bool inBounds = renderBox.paintBounds.contains(position);
    if (event is DropEnterEvent) {
      if (!inBounds) {
        assert(_status == _DragTargetStatus.idle);
      } else {
        _updateStatus(_DragTargetStatus.enter, globalLocation: globalPosition, localLocation: position, items: event.items);
      }
    } else if (event is DropUpdateEvent) {
      if (_status == _DragTargetStatus.idle && inBounds) {
        _updateStatus(_DragTargetStatus.enter, globalLocation: globalPosition, localLocation: position, items: event.items);
      } else if ((_status == _DragTargetStatus.enter || _status == _DragTargetStatus.update) && inBounds) {
        _updateStatus(_DragTargetStatus.update, globalLocation: globalPosition, localLocation: position, debugRequiredStatus: false, items: event.items);
      } else if (_status != _DragTargetStatus.idle && !inBounds) {
        _updateStatus( _DragTargetStatus.idle, globalLocation: globalPosition, localLocation: position, items: event.items);
      }
    } else if (event is DropExitEvent && _status != _DragTargetStatus.idle) {
      _updateStatus(_DragTargetStatus.idle, globalLocation: globalPosition, localLocation: position, items: event.items);
    } else if (event is DropDoneEvent && _status != _DragTargetStatus.idle && inBounds) {
      _updateStatus( _DragTargetStatus.idle, debugRequiredStatus: false, globalLocation: globalPosition, localLocation: position, items: event.items);
      if (widget.onWillAccept != null && !widget.onWillAccept!(event.items)) {
        return;
      }
      widget.onDragDone?.call(DropDoneDetails(items: event.items, localPosition: position, globalPosition: globalPosition));
    }
  }

  void _updateStatus(_DragTargetStatus status, {bool debugRequiredStatus = true, required Offset localLocation, required Offset globalLocation, required List<NativeDragItem> items}) {
    assert(!debugRequiredStatus || _status != status);
    _status = status;
    final details = DropEventDetails(items: items, localPosition: localLocation, globalPosition: globalLocation);
    switch (_status) {
      case _DragTargetStatus.enter:
        widget.onDragEntered?.call(details);
        setState(() {
          if (widget.onWillAccept != null) {
            if (widget.onWillAccept!(items)) {
              _acceptedData = items;
              _rejectedData = [];
            } else {
              _acceptedData = [];
              _rejectedData = items;
            }
          } else {
            _acceptedData = items;
            _rejectedData = [];
          }
        });
        break;
      case _DragTargetStatus.update:
        widget.onDragUpdated?.call(details);
        break;
      case _DragTargetStatus.idle:
        widget.onDragExited?.call(details);
        setState(() {
          _acceptedData = [];
          _rejectedData = [];
        });
        break;
    }
  }

  @override
  void dispose() {
    if (widget.enable) {
      FlutterNativeDragNDrop.instance.removeRawDropEventListener(_onDropEvent);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _acceptedData, _rejectedData);
  }
}