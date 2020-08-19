import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import './pages/position.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Select Position',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class GetData {
  String position;
  String img;
  GetData(x, y) {
    this.position = x;
    this.img = y;
  }
}

class _MyHomePageState extends State<MyHomePage> {
  List<GetData> position = [];
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _asyncMethod();
    });
  }

  _asyncMethod() async {
    var dio = Dio();
    Response response = await dio.get('http://120.105.161.209:3000/position');
    for (var item in response.data["data"]) {
      position.add(GetData(item["position"], item["img"]));
    }
    setState(() {});
  }

  void selectPosition() {}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: ListView.builder(
          itemCount: position.length,
          itemBuilder: (context, index) {
            return ListTile(
                title: Text(position[index].position),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => new Position(
                              title: "Indoor Position ",
                              position: position[index].position,
                              image: position[index].img)));
                });
          },
        ));
  }
}
