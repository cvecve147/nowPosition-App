class temperature {
  final int id;
  final String temp;
  final String roomTemp;
  final String time;
  final String symptom;
  temperature({this.id, this.temp, this.roomTemp, this.time, this.symptom});
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'temp': temp,
      'roomTemp': roomTemp,
      'time': time,
      'symptom': symptom,
    };
  }

  Future<Map<String, dynamic>> toJson() async {
    String uploadid = "";
    return {
      "id": uploadid,
      "temp": temp,
      "roomTemp": roomTemp,
      "time": time,
      "symptom": symptom,
    };
  }

  String toString() {
    return 'temperature{id: $id, temp: $temp,roomTemp: $roomTemp,time: $time,symptom:$symptom}';
  }
}
