import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_drag_n_drop/flutter_native_drag_n_drop.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _dragging = false;
  AssetImage? _img;
  ByteData? _imageData;

  @override
  initState() {
    super.initState();

    rootBundle.load("assets/maldives.jpg").then((imgData) {
      setState(() {
        _imageData = imgData;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
            appBar: AppBar(
              title: const Text('Native drag & drop example'),
            ),
            body: Center(
                child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                NativeDropTarget(
                  builder: ((context, candidateData, rejectedData) {
                    return Container(
                      height: 200,
                      width: 200,
                      color: _dragging ? Colors.blueAccent : Colors.grey,
                      child: _img != null
                          ? Image(height: 200, width: 200, image: _img!)
                          : const Center(child: Text("Drop Target")),
                    );
                  }),
                  onDragEntered: (details) {
                    setState(() {
                      _dragging = true;
                    });
                  },
                  onDragExited: (details) {
                    setState(() {
                      _dragging = false;
                    });
                  },
                  onDragDone: (details) {
                    AssetImage droppedImage =
                        details.items.first.data! as AssetImage;
                    setState(() {
                      _dragging = false;
                      _img = droppedImage;
                    });
                  },
                  onWillAccept: (details) {
                    return true;
                  },
                ),
                const SizedBox(width: 15),
                NativeDraggable(
                  child: const Image(
                      height: 200,
                      width: 200,
                      image: AssetImage("assets/maldives.jpg")),
                  fileStreamCallback: passFileContent,
                  fileItems: [
                    NativeDragFileItem(
                        fileName: "maldives.jpeg",
                        fileSize:
                            _imageData != null ? _imageData!.lengthInBytes : 0,
                        data: const AssetImage("assets/maldives.jpg"))
                  ],
                )
              ],
            ))));
  }

  Stream<Uint8List> passFileContent(
      NativeDragItem<Object> item,
      String fileName,
      String url,
      ProgressController progressController) async* {
    final buffer = _imageData!.buffer.asUint8List();
    final range = buffer.length ~/ 10;

    for (var i = 0; i < 10; i++) {
      final startByte = i * range;
      final endByte = startByte + range;
      final sub = buffer.sublist(startByte, endByte);
      yield sub;
      progressController.updateProgress(endByte);
      await Future.delayed(const Duration(milliseconds: 500));
    }
    return;
  }
}
