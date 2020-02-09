import 'dart:async';
//import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:provider/provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget{
  MyApp({Key key}) : super(key: key);
  @override
  Widget build(BuildContext context){
    return ChangeNotifierProvider<Doze>(
      create: (_) => Doze(),
      child: MyHomePage(),
    );
  }
}
class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context){
    final chartState = Provider.of<Doze>(context, listen: false);
    return MaterialApp(
      title:'Doz',
      home:Scaffold(
          appBar: AppBar(
          title: Text('Doz'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Consumer<Doze>(
                builder: (context, chart, child){
                  return chartWidget(chart);
                }
              ),
              Consumer<Doze>(
                builder: (context, chart, child){
                  return Text(chart.connectionState);
                },
              )
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: chartState.start,
          tooltip: 'connecetToDevice',
          child: Icon(Icons.bluetooth),
        ),
      ),
    );
  }
}

Widget chartWidget(Doze data){
  var series = [
    charts.Series(
      id: 'Dozed Time',
      domainFn: (DozingPerDay dozingData, _) => dozingData.day,
      measureFn: (DozingPerDay dozingData, _) => dozingData.dozingTime,
      colorFn: (DozingPerDay dozingData, _) => dozingData.color,
      data: data.dozingData,
    ),
  ];

  var chart = charts.BarChart(
    series,
    animate: true,
  );

  return Padding(
      padding: EdgeInsets.all(32.0),
      child: SizedBox(
      height: 200.0,
      child: chart,
    )
  );
}

class DozingPerDay extends ChangeNotifier {
  final String day;
  final int dozingTime;
  final charts.Color color;

  DozingPerDay(this.day, this.dozingTime, Color color)
    :this.color = charts.Color(
      r: color.red, g: color.green, b: color.blue, a:color.alpha
    );
}
class Doze extends ChangeNotifier {
  // アドレスは後で変更する
  DateTime today = DateTime.now();
  List<DozingPerDay> _dozingData;
  List<DozingPerDay> get dozingData => _dozingData;
  String connectionState = 'not connected';

  Doze(){
    _dozingData = [
      DozingPerDay('Mn', /*int.parse(getIntData('monday').toString())*/1, Colors.blue),
      DozingPerDay('Tu', /*int.parse(getIntData('tuesday').toString())*/2, Colors.blue),
      DozingPerDay('Wd', /*int.parse(getIntData('wednesday').toString())*/3, Colors.blue),
      DozingPerDay('Th', /*int.parse(getIntData('thursday').toString())*/4, Colors.blue),
      DozingPerDay('Fr', /*int.parse(getIntData('friday').toString())*/5, Colors.blue),
      DozingPerDay('Sa', /*int.parse(getIntData('saturday').toString())*/6, Colors.blue),
      DozingPerDay('Su', /*int.parse(getIntData('sunday').toString())*/7, Colors.blue),
    ];
    notifyListeners();
    assert(_dozingData != null);
    //start();
  }

  void start() async {
    final String address = 'addresss';
    if(today.weekday == DateTime.monday){
      removeData();
    }
    BluetoothConnection connection = await BluetoothConnection.toAddress(address);
    connectionState = 'connected!';
    notifyListeners();
      try{
        connection.input.listen((Uint8List data) {
        String str = ascii.decode(data);
        List<String> strDataFromDevice = str.split(',');
        List<int> dataFromDevice = strDataFromDevice.map(int.parse).toList();
        if(isDozing(dataFromDevice)){ // 居眠りをしていたら
          switch(today.weekday){
            case DateTime.monday:
            dozingData[0] = DozingPerDay('Mn', int.parse(getIntData('monday').toString()) + 1, Colors.blue);
            saveIntData('monday', int.parse(('monday').toString()) + 1);
            break;
            case DateTime.tuesday:
            _dozingData[1] = DozingPerDay('Tu', int.parse(getIntData('tuesday').toString()) + 1, Colors.blue);
            saveIntData('tuesday', int.parse(('tuesday').toString()) + 1);
            break;
            case DateTime.wednesday:
            _dozingData[2] = DozingPerDay('Wd', int.parse(getIntData('wednesday').toString()) + 1, Colors.blue);
            saveIntData('wednesday', int.parse(('wednesday').toString()) + 1);
            break;
            case DateTime.thursday:
            _dozingData[3] = DozingPerDay('Th', int.parse(getIntData('thursday').toString()) + 1, Colors.blue);
            saveIntData('thursday', int.parse(('thursday').toString()) + 1);
            break;
            case DateTime.friday:
            _dozingData[4] = DozingPerDay('Fr', int.parse(getIntData('friday').toString()) + 1, Colors.blue);
            saveIntData('friday', int.parse(('friday').toString()) + 1);
            break;
            case DateTime.saturday:
            _dozingData[5] = DozingPerDay('Sa', int.parse(getIntData('saturday').toString()) + 1, Colors.blue);
            saveIntData('saturday', int.parse(('saturday').toString()) + 1);
            break;
            case DateTime.sunday:
            _dozingData[6] = DozingPerDay('Su', int.parse(getIntData('sunday').toString()) + 1, Colors.blue);
            saveIntData('sunday', int.parse(('sunday').toString()) + 1);
            break;
          }
          notifyListeners();
        }
          //接続を解除
        if (ascii.decode(data).contains('!')) {
          connection.finish();
          connectionState = 'not connected';
          notifyListeners();
        }
      }).onDone(() {
        // 接続を解除したら
      });
    }catch(exception){
      connectionState = 'somethig is wrong';
      notifyListeners();
    }
  }

  bool isDozing(Uint8List data)
  {
    return false;
  }

  Future<int> getIntData(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int num = prefs.getInt(id);
    //print(num.runtimeType);
    return num ?? 0;
  }

  void saveIntData(String id, int num) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt(id, num);
  }

  void removeData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('monday');
    prefs.remove('tuesday');
    prefs.remove('wednesday');
    prefs.remove('thursday');
    prefs.remove('friday');
    prefs.remove('saturday');
    prefs.remove('sunday');
  }
}