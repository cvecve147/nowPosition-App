import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import './components/canvas.dart';
import 'dart:math';
import './class/device.dart';
import './searchTag.dart';

List<Device> device = new List<Device>();
List<Device> nowPosition = new List<Device>();

List macList = List();
// 初始化所有Tag 值
// 取消多輸入的情形
// 若取修多輸入 需修改定位過濾功能
int needRssiCount = 5;
void main() {
  runApp(MyApp());
  // 加速 Use map
  //   Map<String, List<int>> myMapList = Map();

  // myMapList['listA'] = [1, 2, 3];
  // myMapList['listB'] = [4, 5, 6];

  // print(myMapList);
  // {listA: [1, 2, 3], listB: [4, 5, 6]}

  devicePushLab();
  pushMacList();
}

pushMacList() {
  for (var item in device) {
    macList.add(item.mac);
  }
}

devicePushSchool() {
  device.add(Device(mac: "D4:6C:51:7D:F8:DB", x: 12, y: 14.4));
  device.add(Device(mac: "FE:42:E1:2F:42:77", x: 24, y: 12));
  device.add(Device(mac: "EB:A7:C6:6A:7C:CD", x: 36, y: 12));
  device.add(Device(mac: "DC:F6:28:8B:95:8E", x: 45, y: 14.4));
  device.add(Device(mac: "CC:E1:BF:9D:6B:9C", x: 31.95, y: 21));
  device.add(Device(mac: "CA:8F:29:16:7F:4A", x: 37.2, y: 31.8));
  device.add(Device(mac: "F8:94:1E:4E:31:D3", x: 34.65, y: 42));
}

devicePushLab() {
  device.add(Device(mac: "30:45:11:3E:91:6F", x: 12.5, y: 16));
  device.add(Device(mac: "30:45:11:38:F8:4F", x: 19.5, y: 16));
  device.add(Device(mac: "30:45:11:38:72:E6", x: 12.8, y: 24.5));
  device.add(Device(mac: "30:45:11:3F:4E:54", x: 19.75, y: 24.5));
  device.add(Device(mac: "30:45:11:3E:08:63", x: 16.5, y: 19.7));
  // device.add(Device(mac: "30:45:11:3C:64:7E", x: 14 / 3, y: 40 - 0.5));
  // device.add(Device(mac: "30:45:11:38:72:E6", x: 14 / 3, y: 40 - 0.5));
  // device.add(Device(mac: "30:45:11:3E:2A:D1", x: 21 / 3, y: 40 - 4.0));
  // device.add(Device(mac: "30:45:11:3C:64:7E", x: 6 / 3, y: 40 - 0.2));
}

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

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
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
      if (item.notGetRssi > 3) {
        item.DeviceClearRssi();
      }
    }
    for (var getrssi in snapshot) {
      print("${getrssi.device.id}:${getrssi.rssi}");
      for (var item in device) {
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

  bool school = false;
  Set<ScanResult> collectScanResult = new Set();
  List<ScanResult> topThreeDate = new List();
  @override
  Widget build(BuildContext context) {
    String position = "";
    bool condition = true;
    String title = "";
    if (school)
      title = widget.title + " School";
    else
      title = widget.title + " Lab";
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: <Widget>[
          Switch(
            activeColor: Colors.lightGreenAccent,
            onChanged: ((value) => {
                  if (condition)
                    setState(() {
                      school = value;
                      device.clear();
                      macList.clear();
                      print("Switch");
                      if (school) {
                        devicePushSchool();
                      } else {
                        devicePushLab();
                      }
                      pushMacList();
                    })
                }),
            value: school,
          ),
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
                          canvasRoute()
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
