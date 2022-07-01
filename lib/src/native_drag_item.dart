/// [NativeDragItems] is used for when you just drag and drop within the application (e.g folder, image)
/// 
/// [name] should be a unique name which identifies this drag item
/// [data] are any data passed to the [NativeDropTarget]
class NativeDragItem<T extends Object> {
  final String name;
  final T? data;

  NativeDragItem({required this.name, this.data});
}

/// [NativeDragFileItem] is used for files, especially when you want to support the drag and drop outside of the application (e.g file to Finder or Mail client)
/// 
/// [fileName] will be the future fileName
/// [fileSize] is the size of the file
/// [data] are any data passed to the [NativeDropTarget]
class NativeDragFileItem<T extends Object> extends NativeDragItem {
  final String fileName;
  final int fileSize;

  NativeDragFileItem({required this.fileName, required this.fileSize, T? data})
      : super(name: fileName, data: data);
}
