class Device {
  final String mac;
  final double x;
  final double y;
  double distance;
  List<int> rssi; //抓取五個
  int index; //抓取到哪裡了
  int notGetRssi; //抓不到超過5次以上 清空
  Device({this.mac, this.x, this.y}) {
    this.notGetRssi = 0;
    this.index = 0;
    this.distance = 0;
    this.rssi = List<int>();
  }

  @override
  String toString() {
    // TODO: implement toString
    return 'Device{mac: $mac, x: $x, y: $y}';
  }

  DeviceClearRssi() {
    this.distance = 0;
    this.notGetRssi = 0;
    this.rssi.clear();
    this.index = 0;
  }
}
