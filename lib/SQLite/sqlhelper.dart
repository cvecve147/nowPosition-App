import 'dart:async';
import 'package:sqflite/sqflite.dart';

import './AllJoin_model.dart';
import './employee_model.dart';
import './temperature_model.dart';
import 'package:path/path.dart' as path;
import 'employee_model.dart';

class SQLhelper {
  String _DbDir;
  String _Dbname = "NewApp07.db";
  Database _DB;

  initDB() async {
    _DbDir = await getDatabasesPath();
    _DB = await openDatabase(path.join(_DbDir, _Dbname),
        onCreate: (database, version) async {
      await database.execute('''
            CREATE TABLE employees(id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,employeeID TEXT, name TEXT,mac TEXT DEFAULT NULL);
          ''');
      await database.execute('''
            CREATE TABLE temperatures(id INTEGER, temp TEXT,roomTemp TEXT,time TEXT,symptom TEXT DEFAULT NULL);
          ''');
    }, version: 4);
  }

  Future<String> insertData(dynamic data) async {
    await initDB();
    if (data is employee) {
      List searchData = await searchEmployeeID(data.employeeID.trim());
      if (data.id == 0 || searchData.length > 0) {
        return "請檢查資料";
      }
      await _DB.insert('employees', data.toMap());
      var res = await showEmployeeLast();
      try {
        // await uploadDataUser(res);
      } catch (e) {
        print(e);
      }
    } else {
      try {
        await _DB.insert('temperatures', data.toMap());
        // await uploadDataTemp(data);
      } catch (e) {
        print(e);
      }
    }
  }

  Future<employee> showEmployeeLast() async {
    await initDB();
    final List<Map<String, dynamic>> maps = await _DB.rawQuery('''
          SELECT * FROM employees ORDER BY id DESC LIMIT 1
    ''');
    return employee(
      id: maps[0]['id'],
      name: maps[0]['name'],
      employeeID: maps[0]['employeeID'],
      mac: maps[0]['mac'],
    );
  }

  Future<List<employee>> showEmployee() async {
    await initDB();
    final List<Map<String, dynamic>> maps =
        await _DB.rawQuery('select * from employees ORDER BY employeeID');
    return List.generate(maps.length, (i) {
      return employee(
        id: maps[i]['id'],
        name: maps[i]['name'],
        employeeID: maps[i]['employeeID'],
        mac: maps[i]['mac'],
      );
    });
  }

  Future<List<temperature>> showtemperature() async {
    await initDB();
    final List<Map<String, dynamic>> maps = await _DB.query('temperatures');
    return List.generate(maps.length, (i) {
      return temperature(
          id: maps[i]['id'],
          roomTemp: maps[i]['roomTemp'],
          temp: maps[i]['temp'],
          time: maps[i]['time'],
          symptom: maps[i]['symptom']);
    });
  }

  showEmployeeJoinTemp() async {
    await initDB();
    final List<Map<String, dynamic>> maps =
        await _DB.rawQuery('''select * from employees 
        INNER JOIN temperatures 
        on temperatures.id= employees.id
        ''');
    return List.generate(maps.length, (i) {
      return AllJoinTable(
        id: maps[i]['id'],
        employeeID: maps[i]['employeeID'],
        name: maps[i]['name'],
        mac: maps[i]['mac'],
        roomTemp: maps[i]['roomTemp'],
        temp: maps[i]['temp'],
        time: maps[i]['time'],
        symptom: maps[i]['symptom'],
      );
    });
  }

  showLastTempDate() async {
    await initDB();
    final List<Map<String, dynamic>> maps = await _DB.rawQuery('''
      select employees.id,employeeID,name,time,mac,roomTemp,temp,symptom from employees  LEFT  JOIN
      (select * from
        (select * from temperatures
          ORDER BY temperatures.time)          
          GROUP BY  id      ) as temperatures
      ON temperatures.id = employees.id
      ORDER BY employeeID;
    ''');

    return List.generate(maps.length, (i) {
      return AllJoinTable(
        id: maps[i]['id'],
        employeeID: maps[i]['employeeID'],
        name: maps[i]['name'],
        mac: maps[i]['mac'],
        roomTemp: maps[i]['roomTemp'],
        temp: maps[i]['temp'],
        time: maps[i]['time'],
        symptom: maps[i]['symptom'],
      );
    });
  }

  showLastDate() async {
    await initDB();
    final List<Map<String, dynamic>> maps = await _DB.rawQuery('''
      select * from temperatures
          ORDER BY temperatures.time DESC
    ''');
    return List.generate(maps.length, (i) {
      return temperature(
          id: maps[i]['id'],
          roomTemp: maps[i]['roomTemp'],
          temp: maps[i]['temp'],
          time: maps[i]['time'],
          symptom: maps[i]['symptom']);
    });
  }

  Future<List<employee>> searchEmployee(int id) async {
    await initDB();
    final List<Map<String, dynamic>> maps =
        await _DB.query('employees', where: "id=?", whereArgs: [id]);
    return List.generate(maps.length, (i) {
      return employee(
        id: maps[i]['id'],
        name: maps[i]['name'],
        employeeID: maps[i]['employeeID'],
        mac: maps[i]['mac'],
      );
    });
  }

  searchEmployeeID(String id) async {
    await initDB();
    final List<Map<String, dynamic>> maps =
        await _DB.query('employees', where: "employeeID=?", whereArgs: [id]);
    return List.generate(maps.length, (i) {
      return employee(
        id: maps[i]['id'],
        name: maps[i]['name'],
        employeeID: maps[i]['employeeID'],
        mac: maps[i]['mac'],
      );
    });
  }

  searchEmployeeMAC(String mac) async {
    await initDB();
    final List<Map<String, dynamic>> maps =
        await _DB.query('employees', where: "mac=?", whereArgs: [mac]);
    return List.generate(maps.length, (i) {
      return employee(
        id: maps[i]['id'],
        name: maps[i]['name'],
        employeeID: maps[i]['employeeID'],
        mac: maps[i]['mac'],
      );
    });
  }

  searchTemp(String startData, String endData) async {
    await initDB();
    final List<Map<String, dynamic>> maps = await _DB.rawQuery(
        "SELECT * FROM temperatures WHERE time BETWEEN '${startData}' AND '${endData}'"); //2020-01-01
    return List.generate(maps.length, (i) {
      return temperature(
          id: maps[i]['id'],
          roomTemp: maps[i]['roomTemp'],
          temp: maps[i]['temp'],
          time: maps[i]['time'],
          symptom: maps[i]['symptom']);
    });
  }

  updateData(dynamic data) async {
    await initDB();
    if (data is employee) {
      await _DB.update("employees", data.toMap(),
          where: "id=?", whereArgs: [data.id]);
      // await editServerData(data);
    }
  }

  showLastData() async {
    await initDB();
    final List<Map<String, dynamic>> maps = await _DB.rawQuery('''
      select * from employees         
      INNER JOIN 
      (
        select * from
        (select * from temperatures
          ORDER BY temperatures.time DESC)          
          GROUP BY  id      
      )as temperatures
      on temperatures.id= employees.id
      ORDER BY temperatures.time 
    ''');
    return List.generate(maps.length, (i) {
      return AllJoinTable(
        id: maps[i]['id'],
        employeeID: maps[i]['employeeID'],
        name: maps[i]['name'],
        mac: maps[i]['mac'],
        roomTemp: maps[i]['roomTemp'],
        temp: maps[i]['temp'],
        time: maps[i]['time'],
        symptom: maps[i]['symptom'],
      );
    });
  }

  showLastTemp() async {
    await initDB();
    final List<Map<String, dynamic>> maps = await _DB.rawQuery('''
      select * from employees        
      ORDER BY employeeID
    ''');
    return List.generate(maps.length, (i) {
      return AllJoinTable(
        id: maps[i]['id'],
        employeeID: maps[i]['employeeID'],
        name: maps[i]['name'],
        mac: maps[i]['mac'],
        roomTemp: "",
        temp: "",
        time: "",
        symptom: "",
      );
    });
  }

  String twoDigit(int n) {
    if (n >= 10) return "$n";
    return "0$n";
  }

  deleteEmployee(int id) async {
    await initDB();
    await _DB.delete('employees', where: "id=?", whereArgs: [id]);
    // await deleteServerData(id);
  }

  dropEmployee() async {
    await initDB();
    await _DB.delete('employees');
  }

  dropTemp() async {
    await initDB();
    await _DB.delete('temperatures');
  }

  dropAll() async {
    await initDB();
    await _DB.delete('employees');
    await _DB.delete('temperatures');
  }
}
