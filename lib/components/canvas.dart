import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as image;
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../pages/position.dart';
import 'dart:ui' as ui;

class canvasRoute extends StatefulWidget {
  String imageUrl = "";
  canvasRoute(this.imageUrl);

  @override
  _canvasRouteState createState() => _canvasRouteState();
}

class _canvasRouteState extends State<canvasRoute> {
  ui.Image images;
  static Future<ui.Image> loadImageByProvider(ImageProvider provider) async {
    ImageConfiguration config = ImageConfiguration(size: Size(400, 400));

    Completer<ui.Image> completer = Completer<ui.Image>(); //完成的回调
    ImageStreamListener listener;
    ImageStream stream = provider.resolve(config); //获取图片流
    listener = ImageStreamListener((ImageInfo frame, bool sync) {
//监听

      ui.Image image = frame.image;
      completer.complete(image); //完成
      stream.removeListener(listener); //移除监听
    });
    stream.addListener(listener); //添加监听
    return completer.future; //返回
  }

  Completer<ImageInfo> completer = Completer();
  Future<ui.Image> getImage(String path) async {
    var img = new NetworkImage(path);

    img
        .resolve(ImageConfiguration(size: Size(400, 400)))
        .addListener(ImageStreamListener((ImageInfo info, bool _) {
      completer.complete(info);
    }));
    ImageInfo imageInfo = await completer.future;

    return imageInfo.image;
  }

  @override
  void initState() {
    super.initState();
    print(widget.imageUrl);
    (() async {
      if (this.images == null) {
        images = await getImage(widget.imageUrl);

        setState(() {});
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
    canvas.drawImageRect(
        image,
        Offset(0.0, 0.0) &
            Size(image.width.toDouble(), image.height.toDouble()),
        Offset(0.0, 0.0) & Size(400, 400),
        painter);
    // canvas.drawImage(image, Offset(0.0, 0.0), painter);
    int count = 0;
    if (nowPosition.length > 0) {
      for (var item in nowPosition) {
        count += 1;
        if (count == nowPosition.length) {
          painter
            ..style = PaintingStyle.fill
            ..color = Colors.yellow;
        } else {
          painter
            ..style = PaintingStyle.fill
            ..color = Colors.green;
        }
        canvas.drawCircle(
          Offset(item.x * 8.27, size.height - item.y * 7.7),
          3,
          painter,
        );
        // final textStyle = ui.TextStyle(
        //   color: Colors.red[400],
        //   fontSize: 12,
        // );
        // final paragraphStyle = ui.ParagraphStyle(
        //   textDirection: TextDirection.ltr,
        // );
        // final paragraphBuilder = ui.ParagraphBuilder(paragraphStyle)
        //   ..pushStyle(textStyle)
        //   ..addText(count.toString());
        // final constraints = ui.ParagraphConstraints(width: 300);
        // final paragraph = paragraphBuilder.build();
        // paragraph.layout(constraints);
        // canvas.drawParagraph(
        //     paragraph, Offset(item.x * 8.1, size.height - item.y * 8.0));
      }
    }
    painter
      ..style = PaintingStyle.fill
      ..color = Colors.red;
    for (var item in device) {
      canvas.drawCircle(
        Offset(item.x * 8.27, size.height - item.y * 7.7),
        4,
        painter,
      );
      final textStyle = ui.TextStyle(
        color: Colors.blue,
        fontSize: 14,
      );
      final paragraphStyle = ui.ParagraphStyle(
        textDirection: TextDirection.ltr,
      );
      final paragraphBuilder = ui.ParagraphBuilder(paragraphStyle)
        ..pushStyle(textStyle)
        ..addText(item.mac.toString().substring(
            item.mac.toString().length - 2, item.mac.toString().length));
      final constraints = ui.ParagraphConstraints(width: 300);
      final paragraph = paragraphBuilder.build();
      paragraph.layout(constraints);
      canvas.drawParagraph(paragraph,
          Offset(item.x * 8.27 - 9, size.height - item.y * 7.7 - 15));
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
