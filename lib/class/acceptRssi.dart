class AcceptRssi {
  String mac;
  int rssi;
  AcceptRssi(this.mac, this.rssi);
  AcceptRssi.fromJson(Map<String, dynamic> json)
      : mac = json['mac'],
        rssi = json['rssi'];

  Map<String, dynamic> toJson() => {
        'mac': mac,
        'rssi': rssi,
      };
}
