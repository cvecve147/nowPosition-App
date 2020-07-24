# nowPosition

A new Flutter project.

## class 介紹

Device class
```dart
class Device {
  final String mac; //紀錄mac 
  final double x;   //x座標
  final double y;   //y座標
  double distance;  //距離計算結果存放位置
  List<int> rssi; //抓取五個
  int index; //抓取到哪裡了
  int notGetRssi; //抓不到超過5次以上 清空
  Device({this.mac, this.x, this.y}) {  //建構子
    this.notGetRssi = 0;
    this.index = 0;
    this.distance = 0;
    this.rssi = List<int>();
  }

  @override
  String toString() {   //可直接print
    // TODO: implement toString
    return 'Device{mac: $mac, x: $x, y: $y}';
  }

  DeviceClearRssi() {   //清空長時間未接收到封包的內容
    this.distance = 0;
    this.notGetRssi = 0;
    this.rssi.clear();
    this.index = 0;
  }
}
```

## 組件介紹
canvas 組件
```dart 
import 'package:flutter/material.dart';
import 'package:image/image.dart' as image;
import 'package:flutter/services.dart' show rootBundle;
import '../main.dart';
import 'dart:ui' as ui;

// 主要用來顯示下方2D平面圖

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
        //如果圖片是空的 就載入
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
    //圖片轉碼 重新設定size等
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
    // 預防圖片未載入
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
    //載入圖片
    canvas.drawImage(image, Offset(0.0, 0.0), painter);
    //設定畫筆顏色
    painter
      ..style = PaintingStyle.fill
      ..color = Colors.red;
    //畫出所有紀錄的device 座標
    for (var item in device) {
      canvas.drawCircle(
        Offset(item.x * 8.27, size.height - item.y * 7.7),
        5,
        painter,
      );
    }
    //計算出到第幾個座標
    int count = 0;
    if (nowPosition.length > 0) {
    //利用foreach(for in ) 將所有 點位列印出來
      for (var item in nowPosition) {
        count += 1;
        //當點位為最後一個時 畫筆改成藍色
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
        //設定文字大小與顏色
        final textStyle = ui.TextStyle(
          color: Colors.red[400],
          fontSize: 14,
        );
        //設定文字方向
        final paragraphStyle = ui.ParagraphStyle(
          textDirection: TextDirection.ltr,
        );
        //文字內容等
        final paragraphBuilder = ui.ParagraphBuilder(paragraphStyle)
          ..pushStyle(textStyle)
          ..addText(count.toString());
        final constraints = ui.ParagraphConstraints(width: 300);
        
        final paragraph = paragraphBuilder.build();
        paragraph.layout(constraints);
        //將編號畫在canvas上
        canvas.drawParagraph(
            paragraph, Offset(item.x * 8.1, size.height - item.y * 8.0));
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

```

## 主程式

```dart 
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import './components/canvas.dart';
import 'dart:math';
import './class/device.dart';

//建立device 物件 存放tag
List<Device> device = new List<Device>();
//建立nowPosition 物件 存放計算出來的點位
List<Device> nowPosition = new List<Device>();
//建立 macList 列表  用於快速驗證是否為我們的tag
List macList = List();
void main() {
  runApp(MyApp());

  // device.add(Device(mac: "30:45:11:38:F8:4F", x: 19.5, y: 15));
  // device.add(Device(mac: "30:45:11:39:07:20", x: 21, y: 15));
  // 將所有tag放入device
  device.add(Device(mac: "D4:6C:51:7D:F8:DB", x: 12, y: 14.4));
  device.add(Device(mac: "FE:42:E1:2F:42:77", x: 24, y: 12));
  device.add(Device(mac: "EB:A7:C6:6A:7C:CD", x: 36, y: 12));
  device.add(Device(mac: "DC:F6:28:8B:95:8E", x: 45, y: 14.4));
  device.add(Device(mac: "CC:E1:BF:9D:6B:9C", x: 31.95, y: 21));
  device.add(Device(mac: "CA:8F:29:16:7F:4A", x: 37.2, y: 31.8));
  device.add(Device(mac: "F8:94:1E:4E:31:D3", x: 34.65, y: 42));
  //將所有tag的mac放入maclist
  for (var item in device) {
    macList.add(item.mac);
  }
}

//設定header 
class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'indoor Position',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Indoor Position'),
    );
  }
}

//建立會變更的物件
class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}
//主要介面展示與計算公式等
class _MyHomePageState extends State<MyHomePage> {
  //計算前一個點到目前計算出來的這個點的距離
  calculationPreDist(double x, double y) {
    if (nowPosition.length == 0) return 0.0;
    double prePointX = nowPosition[nowPosition.length - 1].x;
    double prePointY = nowPosition[nowPosition.length - 1].y;
    double dist = sqrt(pow(prePointX - x, 2) + pow(prePointY - y, 2));
    return dist;
  }
  /* 
  計算是否有超過三個tag有收集到五個rssi 如果有 將這些點位相加後取絕對值 在剪掉最大最小值
  並且把tag的距離記錄下來並放入陣列中
  */
  calculationDist() {
    int count = 0;
    List<Device> point = List<Device>();
    for (var item in device) {
      if (item.rssi.length >= 5) {
        count += 1;
      }
    }
    for (var item in device) {
      if (count >= 3 && item.rssi.length >= 5) {
        int maxrssi = item.rssi.reduce(max); //負數最大
        int minrssi = item.rssi.reduce(min); //負數最小
        int sum = item.rssi.reduce((a, b) => a + b);
        sum = sum.abs();
        double rssi = (sum + maxrssi + minrssi) / (item.rssi.length - 2);
        double power = (rssi - 60) / (10.0 * 3.3);
        item.DeviceClearRssi();
        item.distance = pow(10, power);
        point.add(item);
      }
    }
    return point;
  } 
  //利用上方calculationDist函式過濾掉得點位計算三角定位
  calculationPosition(point) {
    double X, Y;
    X = Y = 0;
    for (int i = 0; i < 2; i++) {
      for (int j = i + 1; j < 3; j++) {
        if (point[i].distance < 0) {
          return Container(child: Text("系統錯誤"));
        }
        double p2p = sqrt(pow(point[i].x - point[j].x, 2) +
            pow(point[i].y - point[j].y, 2)); //圓心公式
        //判斷两圆是否相交
        if (point[i].distance + point[j].distance <= p2p) {
          // var overDisance = point[i].distance + point[j].distance;
          //不相交，按比例求
          X += point[i].x +
              (point[j].x - point[i].x) *
                  point[i].distance /
                  (point[i].distance + point[j].distance);
          //x = x0+ (x1 - x0)*r0/(r0 + r1);
          Y += point[i].y +
              (point[j].y - point[i].y) *
                  point[i].distance /
                  (point[i].distance + point[j].distance);
          //y = y0+ (y1- y0)*r0/(r0 + r1);
        } else {
          //相交则套用公式（上面推导出的）
          //(BE) =(AB) /2+((BQ) ^2-(AQ) ^2)/(2(AB)  )
          double dr = p2p / 2 +
              (pow(point[i].distance, 2) - pow(point[j].distance, 2)) /
                  (2 * p2p);
          X += point[i].x + (point[j].x - point[i].x) * dr / p2p;
          Y += point[i].y + (point[j].y - point[i].y) * dr / p2p;
        }
      }
    }
    X /= 3;
    Y /= 3;
    //呼叫calculationPreDist
    double dist = calculationPreDist(X, Y);
    nowPosition.add(Device(mac: "", x: X, y: Y));
    return "${X.toStringAsFixed(2)} , ${Y.toStringAsFixed(2)} 與上點距離為${dist.toStringAsFixed(2)}";
  }
  //判斷是否在我們macList中 contains這函式是內建函示
  containsMac(List<ScanResult> snapshot, List macList) {
    List<ScanResult> temp = List<ScanResult>();
    for (var item in snapshot) {
      if (macList.contains(item.device.id.toString())) {
        temp.add(item);
      }
    }
    return temp;
  }
  //抓取我們tag中的資料 利用rssi 排序 並且利用sublist 抓取前三筆資料
  topThree(List<ScanResult> snapshot) {
    snapshot = containsMac(snapshot, macList);
    snapshot.sort((a, b) {
      return a.rssi > b.rssi ? -1 : 1;
    });
    if (snapshot.length >= 3) {
      return snapshot.sublist(0, 3);
    }
    return snapshot;
  }
  //放入rssi值
  putRssi(List<ScanResult> snapshot) {
    for (var item in device) {
      //如果超過10次沒收到 清空
      item.notGetRssi += 1;
      if (item.notGetRssi > 10) {
        item.DeviceClearRssi();
      }
    }
    /*
    利用雙迴圈抓取每一個tag資料 外層迴圈最多3個
    內層迴圈看device 資料有多少 bigO(3*n)
    */
    for (var getrssi in snapshot) {
      print(getrssi.rssi);
      for (var item in device) {
        //抓取如果mac 相同 放入此device的rssi陣列中
        if (item.mac == getrssi.device.id.toString()) {
          item.notGetRssi = 0;
          item.index += 1;
          if (item.rssi.length < 5) {
            item.rssi.add(getrssi.rssi);
          } else {
            if (item.index >= 5) {
              item.index = 0;
            }
            item.rssi.replaceRange(item.index, item.index + 1, [getrssi.rssi]);
            print("replace " +
                item.mac +
                " " +
                item.index.toString() +
                " " +
                (item.index + 1).toString());
          }
          break;
        }
      }
    }
  }
  // 這class生命週期必經之路 build 一定會執行
  @override
  Widget build(BuildContext context) {
    // 將計算出來的position 存放在文字中 如果數量不足 就顯示數量不足
    String position = "";
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            FlutterBlue.instance.startScan(timeout: Duration(seconds: 4)),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              //主要藍芽掃描結果函式
              StreamBuilder<List<ScanResult>>(
                  stream: FlutterBlue.instance.scanResults,
                  initialData: [],
                  builder: (c, snapshot) {
                    //列印出所有掃描到的藍芽資料
                    print(snapshot.data.toList().toString());
                    //過濾是否為我們tag的資料並且只挑出強度前3的tag
                    List<ScanResult> topThreeDate =
                        topThree(snapshot.data.toList());
                    //如果有值 放入device中
                    if (topThreeDate.length > 0) {
                      putRssi(topThreeDate);
                    }
                    //計算點到點的距離
                    List point = calculationDist();
                    //計算三角定位
                    if (point.length >= 3) {
                      position = calculationPosition(point);
                    } else {
                      position = "數量不足";
                    }
                    position += "\n";
                    return Container(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        //顯示position計算的結果
                        children: <Widget>[
                          Text(
                            position,
                            style: TextStyle(fontSize: 18),
                          ),
                          //顯示device rssi陣列不為空的值
                          for (var item in device)
                            if (item.rssi.length > 0)
                              Column(
                                children: <Widget>[
                                  Text(item.mac),
                                  Text(item.rssi.join("、"))
                                ],
                              ),
                          //顯示topThreeData的rssi
                          for (var item in topThreeDate)
                            Text(item.rssi.toString()),
                          canvasRoute()     //載入canvas 組件
                        ],
                      ),
                    );
                  }),
            ],
          ),
        ),
      ),
      floatingActionButton: StreamBuilder<bool>(
        stream: FlutterBlue.instance.isScanning,
        initialData: false,
        builder: (c, snapshot) {
            //如果snapshot.data有資料 顯示紅色停止按鈕，否則顯示搜尋按鈕
            //搜尋時間設定為999秒 allowDuplicates:false scanMode:lowLatency 低延遲
          if (snapshot.data) {
            return FloatingActionButton(
              child: Icon(Icons.stop),
              onPressed: () => FlutterBlue.instance.stopScan(),
              backgroundColor: Colors.red,
            );
          } else {
            return FloatingActionButton(
                child: Icon(Icons.search),
                onPressed: () async {
                  await FlutterBlue.instance.startScan(
                      timeout: Duration(seconds: 999),
                      allowDuplicates: false,
                      scanMode: ScanMode.lowLatency);
                });
          }
        },
      ),
    );
  }
}

```