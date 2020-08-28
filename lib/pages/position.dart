import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import '../components/canvas.dart';
import 'dart:math';
import '../class/device.dart';
import '../searchTag.dart';
import 'package:dio/dio.dart';

List<Device> device = new List<Device>();
List<Device> nowPosition = new List<Device>();

List macList = List();
// 初始化所有Tag 值
// 取消多輸入的情形
// 若取修多輸入 需修改定位過濾功能
int needRssiCount = 5;

pushMacList() {
  for (var item in device) {
    macList.add(item.mac);
  }
}

class Position extends StatefulWidget {
  String title = "", position = "", image = "";
  Position({Key key, this.title, this.position, this.image}) : super(key: key);

  @override
  _PositionState createState() => _PositionState();
}

class _PositionState extends State<Position> {
  calculationPreDist(double x, double y) {
    if (nowPosition.length == 0) return 0.0;
    double prePointX = nowPosition[nowPosition.length - 1].x;
    double prePointY = nowPosition[nowPosition.length - 1].y;
    double dist = sqrt(pow(prePointX - x, 2) + pow(prePointY - y, 2));
    return dist;
  }

  calculationDist() {
    int count = 0;
    List<Device> point = List<Device>();
    for (var item in device) {
      if (item.rssi.length >= needRssiCount) {
        count += 1;
      }
    }
    for (var item in device) {
      if (count >= 3 && item.rssi.length >= needRssiCount) {
        List<int> tmp = item.rssi.toList();
        tmp = tmp.sublist(0, 5); //不過濾最後一個
        int maxrssi = tmp.reduce(max); //負數最大
        int minrssi = tmp.reduce(min); //負數最小

        int sum = item.rssi.reduce((a, b) => a + b);
        sum = sum.abs();
        double rssi = (sum + maxrssi + minrssi) / (item.rssi.length - 2);
        double power = (rssi - item.rssiDef) / (10.0 * 3.3);
        item.distance = pow(10, power);
        point.add(item);
      }
    }
    if (point.length > 0) {
      point.sort((a, b) {
        return a.distance > b.distance ? -1 : 1;
      });
    }
    return point;
  }

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
          //x = x0 + (x1 - x0) * r0 / (r0 + r1);
          Y += point[i].y +
              (point[j].y - point[i].y) *
                  point[i].distance /
                  (point[i].distance + point[j].distance);
          //y = y0 + (y1 - y0) * r0 / (r0 + r1);
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
    double dist = calculationPreDist(X, Y);
    nowPosition.add(Device(mac: "", x: X, y: Y));
    return "${X.toStringAsFixed(2)} , ${Y.toStringAsFixed(2)} 與上點距離為${dist.toStringAsFixed(2)}";
  }

  containsMac(List<ScanResult> snapshot, List macList) {
    List<ScanResult> temp = List<ScanResult>();
    for (var item in snapshot) {
      if (macList.contains(item.device.id.toString())) {
        temp.add(item);
      }
    }
    return temp;
  }

  topThree(List<ScanResult> snapshot) {
    snapshot = containsMac(snapshot, macList);

    snapshot.sort((a, b) {
      return a.rssi > b.rssi ? -1 : 1;
    });
    for (var item in snapshot) {
      print("${item.device.id} ${item.rssi}");
    }
    if (snapshot.length >= 3) {
      return snapshot.sublist(0, 3);
    }
    return snapshot;
  }

  putRssi(List<ScanResult> snapshot) {
    if (snapshot.length == 0) return;
    for (var item in device) {
      //如果超過10次沒收到 清空
      item.notGetRssi += 1;
      if (item.notGetRssi > 7) {
        item.DeviceClearRssi();
      }
    }
    for (var getrssi in snapshot) {
      print("${getrssi.device.id}:${getrssi.rssi}");
      for (var item in device) {
        if (item.mac == getrssi.device.id.toString()) {
          item.notGetRssi = 0;
          if (item.rssi.length < 5) {
            item.rssi.add(getrssi.rssi);
          } else {
            item.rssi.removeFirst();
            item.rssi.add(getrssi.rssi);
          }
          break;
        }
      }
    }
  }

  Set<ScanResult> collectScanResult = new Set();
  List<ScanResult> topThreeDate = new List();
  String position = "";
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getData();
    });
  }

  _getData() async {
    this.position = "loading";
    var dio = Dio();
    device.clear();
    nowPosition.clear();
    Response response = await dio.get(
        'http://120.105.161.209:3000/position-tags?query=%7B%22where%22%3A%7B%22position%22%3A%22${widget.position}%22%7D%7D');
    for (var item in response.data["data"]) {
      device.add(Device(
          mac: item["mac"],
          x: double.parse(item["x"]),
          y: double.parse(item["y"]),
          rssiDef: int.parse(item["rssi"])));
    }
    setState(() {});
    await pushMacList();
    this.position = "ok";
    //
  }

  @override
  Widget build(BuildContext context) {
    bool condition = true;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title + widget.position),
        actions: <Widget>[
          RaisedButton(
            color: Colors.blue,
            child: Icon(
              Icons.search,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SecondRoute()),
              );
            },
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            FlutterBlue.instance.startScan(timeout: Duration(seconds: 4)),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              StreamBuilder<List<ScanResult>>(
                  stream: FlutterBlue.instance.scanResults,
                  initialData: [],
                  builder: (c, snapshot) {
                    String res = "";
                    // print(snapshot.data.toList().toString());
                    print(snapshot.data.toList().length);
                    for (var item in snapshot.data) {
                      res += item.device.id.toString() + " rssi:";
                      res += item.rssi.toString() + ",";
                    }
                    print(res);

                    snapshot.data.map((e) => collectScanResult.add(e)).toList();
                    return Container(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          if (!condition) Text("開始掃描"),
                          Text(
                            position,
                            style: TextStyle(fontSize: 18),
                          ),
                          for (var item in device)
                            if (item.rssi.length > 0)
                              Column(
                                children: <Widget>[
                                  Text(item.mac),
                                  Text(item.rssi.join("、"))
                                ],
                              ),
                          for (var item in topThreeDate)
                            Text(item.rssi.toString()),
                          canvasRoute(widget.image)
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
          if (snapshot.data) {
            return FloatingActionButton(
              child: Icon(Icons.stop),
              onPressed: () async {
                setState(() async {
                  condition = true;
                  await FlutterBlue.instance.stopScan();
                });
              },
              backgroundColor: Colors.red,
            );
          } else {
            return FloatingActionButton(
                child: Icon(Icons.search),
                onPressed: () async {
                  condition = false;
                  while (true) {
                    if (condition) {
                      break;
                    }
                    collectScanResult.clear();
                    await FlutterBlue.instance.startScan(
                        timeout: Duration(seconds: 6),
                        allowDuplicates: false,
                        scanMode: ScanMode.lowLatency);
                    await FlutterBlue.instance.stopScan();
                    topThreeDate = topThree(collectScanResult.toList());
                    if (topThreeDate.length > 0) {
                      putRssi(topThreeDate);
                    }
                    List point = calculationDist();
                    if (point.length >= 3) {
                      position = calculationPosition(point);
                    } else {
                      position = "此次收集數量不足";
                    }
                    position += "\n";
                  }
                });
          }
        },
      ),
    );
  }
}
