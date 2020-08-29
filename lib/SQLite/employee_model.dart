import 'dart:io';

class employee {
  final int id;
  final String name;
  final String employeeID;
  final String mac;
  employee({this.id, this.name, this.employeeID, this.mac});
  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'employeeID': employeeID, 'mac': mac};
  }

  Future<Map<String, dynamic>> toJson() async {
    String id = "";
    id += this.id.toString();

    //{\"_id\":\"2\",\"employeeID\":\"1\",\"mac\":\"F8:34:41:27:79:A1\",\"name\":\"username\"}
    return {"_id": id, "name": name, "employeeID": employeeID, "mac": mac};
  }

  @override
  String toString() {
    // TODO: implement toString
    return 'employee{id: $id, name: $name, employeeID: $employeeID,mac: $mac}';
  }
}
