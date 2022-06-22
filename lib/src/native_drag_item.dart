class NativeDragItem<T extends Object> {
  final String name;
  final T? data;

  NativeDragItem({required this.name, this.data});
}

class NativeDragFileItem<T extends Object> extends NativeDragItem {
  final String fileName;
  final int fileSize;

  NativeDragFileItem({required this.fileName, required this.fileSize, T? data})
      : super(name: fileName, data: data);
}
