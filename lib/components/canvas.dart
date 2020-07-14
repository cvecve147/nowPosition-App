import 'package:flutter/material.dart';
import 'package:image/image.dart' as image;
import 'package:flutter/services.dart' show rootBundle;
import '../main.dart';
import 'dart:ui' as ui;

class canvasRoute extends StatefulWidget {
  @override
  _canvasRouteState createState() => _canvasRouteState();
}

class _canvasRouteState extends State<canvasRoute> {
  ui.Image images;
  @override
  void initState() {
    super.initState();
    (() async {
      if (this.images == null) {
        loadUiImage('image/7F.png', 400, 400).then((img) {
          images = img;
          setState(() {});
        });
      }
    })();
  }

  Future<ui.Image> loadUiImage(String assetPath, height, width) async {
    final data = await rootBundle.load(assetPath);
    image.Image baseSizeImage = image.decodeImage(data.buffer.asUint8List());
    image.Image resizeImage =
        image.copyResize(baseSizeImage, height: height, width: width);
    ui.Codec codec =
        await ui.instantiateImageCodec(image.encodePng(resizeImage));
    ui.FrameInfo frameInfo = await codec.getNextFrame();
    return frameInfo.image;
  }

  @override
  Widget build(BuildContext context) {
    if (this.images == null) return Center(child: Text("loading Image"));
    return Container(
      child: CustomPaint(
        size: Size(400, 400),
        painter: MyPainter(image: this.images),
      ),
    );
  }
}

class MyPainter extends CustomPainter {
  ui.Image image;
  Paint painter;
  MyPainter({this.image});
  @override
  void paint(Canvas canvas, Size size) {
    painter = Paint();
    canvas.drawImage(image, Offset(0.0, 0.0), painter);
    painter
      ..style = PaintingStyle.fill
      ..color = Colors.red;
    for (var item in device) {
      canvas.drawCircle(
        Offset(item.x * 8.27, size.height - item.y * 7.7),
        5,
        painter,
      );
    }

    int count = 0;
    if (nowPosition.length > 0) {
      for (var item in nowPosition) {
        count += 1;
        if (count == nowPosition.length) {
          painter
            ..style = PaintingStyle.fill
            ..color = Colors.blue;
        } else {
          painter
            ..style = PaintingStyle.fill
            ..color = Colors.green;
        }
        canvas.drawCircle(
          Offset(item.x * 8.27, size.height - item.y * 7.7),
          5,
          painter,
        );
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
