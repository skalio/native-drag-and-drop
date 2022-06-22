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

  AssetImage? img;
  ByteData? imageData;

  @override
  void initState() {
    super.initState();

    rootBundle.load("assets/nature_1.jpeg").then((imgData) {
      imageData = imgData;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Plugin example app'),
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
                    color: _dragging
                        ? Colors.blue.withOpacity(0.4)
                        : Colors.black26,
                    child: img != null
                        ? Image(height: 200, width: 200, image: img!)
                        : const Center(),
                  );
                }),
                onDragEntered: (d) {
                  setState(() {
                    _dragging = true;
                  });
                },
                onDragExited: (d) {
                  setState(() {
                    _dragging = false;
                  });
                },
                onDragDone: (d) {
                  final image = d.items.first.data! as AssetImage;
                  setState(() {
                    _dragging = false;
                    img = image;
                  });
                },
                onWillAccept: (d) {
                  return true;
                },
              ),
              const SizedBox(width: 15),
              NativeDraggable(
                child: const Image(
                    height: 300,
                    width: 300,
                    image: AssetImage("assets/nature_1.jpeg")),
                fileStreamCallback: passFileContent,
                items: [
                  NativeDragFileItem(
                      fileName: "image.jpeg",
                      fileSize: 1024,
                      data: const AssetImage("assets/nature_1.jpeg"))
                ],
                onDragStarted: (event) {},
                onDragUpdate: (event) {},
                onDragEnd: (event) {},
              ),
            ],
          ))),
    );
  }

  Stream<Uint8List> passFileContent(
      NativeDragItem<Object> item,
      String fileName,
      String url,
      ProgressController progressController) async* {
    final buf = imageData!.buffer.asUint8List();
    final range = buf.length / 5;

    for (var i = 0; i < 5; i++) {
      final sub =
          buf.sublist(i * range.toInt(), i * range.toInt() + range.toInt());
      yield sub;
      await Future.delayed(const Duration(milliseconds: 500));
    }
    return;
  }
}
