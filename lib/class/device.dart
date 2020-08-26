import 'dart:collection';

class Device {
  final String mac;
  final double x;
  final double y;
  double distance;
  Queue<int> rssi; //抓取五個
  int rssiDef;
  int notGetRssi; //抓不到超過5次以上 清空
  Device({this.mac, this.x, this.y, this.rssiDef}) {
    this.notGetRssi = 0;
    this.distance = 0;
    this.rssi = Queue<int>();
  }

  @override
  String toString() {
    // TODO: implement toString
    return 'Device{mac: $mac, x: $x, y: $y,Def: $rssiDef}';
  }

  DeviceClearRssi() {
    this.distance = 0;
    this.notGetRssi = 0;
    this.rssi.clear();
  }
}
