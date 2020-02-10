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
          onPressed: chartState.start, // ここを本番はstartにする
          tooltip: 'connecetToDevice',
          child: Consumer<Doze>(
            builder: (context, chart, child){
              if(chart.connectionState == 'connected!'){
                return Icon(Icons.bluetooth_connected);
              } else if(chart.connectionState == 'not connected') {
                return Icon(Icons.bluetooth);
              }
            },
          ),
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
  List<DozingPerDay> _dozingData = [
    DozingPerDay('Mn', 0, Colors.blue),
    DozingPerDay('Tu', 0, Colors.blue),
    DozingPerDay('Wd', 0, Colors.blue),
    DozingPerDay('Th', 0, Colors.blue),
    DozingPerDay('Fr', 0, Colors.blue),
    DozingPerDay('Sa', 0, Colors.blue),
    DozingPerDay('Su', 0, Colors.blue),
  ];
  List<DozingPerDay> get dozingData => _dozingData;
  String connectionState = 'not connected';

  Doze(){
    setupData();
    //assert(_dozingData != null);
    //start();
  }

  void start() async {
    final String address = '24:0A:C4:08:73:76';
    BluetoothConnection connection = await BluetoothConnection.toAddress(address);
    connectionState = 'connected!';
    notifyListeners();
      try{
        connection.input.listen((Uint8List data) {
        updateData();
          //接続を解除
        if (ascii.decode(data).contains('!')) {
          connection.finish();
        }
      }).onDone(() {
        // 接続を解除したら
        connectionState = 'not connected';
        notifyListeners();
      });
    }catch(exception){
      connectionState = 'somethig is wrong';
      notifyListeners();
    }
  }


  void setupData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if(DateTime.now().weekday == DateTime.monday && prefs.getInt('today') != DateTime.monday){
      prefs.remove('monday');
      prefs.remove('tuesday');
      prefs.remove('wednesday');
      prefs.remove('thursday');
      prefs.remove('friday');
      prefs.remove('saturday');
      prefs.remove('sunday');
    }
    _dozingData = [
      DozingPerDay('Mn', prefs.getInt(DateTime.monday.toString()) ?? 0, Colors.blue),
      DozingPerDay('Tu', prefs.getInt(DateTime.tuesday.toString()) ?? 0, Colors.blue),
      DozingPerDay('Wd', prefs.getInt(DateTime.wednesday.toString()) ?? 0, Colors.blue),
      DozingPerDay('Th', prefs.getInt(DateTime.thursday.toString()) ?? 0, Colors.blue),
      DozingPerDay('Fr', prefs.getInt(DateTime.friday.toString()) ?? 0, Colors.blue),
      DozingPerDay('Sa', prefs.getInt(DateTime.saturday.toString()) ?? 0, Colors.blue),
      DozingPerDay('Su', prefs.getInt(DateTime.sunday.toString()) ?? 0, Colors.blue),
    ];
    notifyListeners();
    prefs.setInt('today', DateTime.now().weekday);
  }

  void updateData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if(DateTime.now().weekday == DateTime.monday && prefs.getInt('today') != DateTime.monday){
      prefs.remove(DateTime.monday.toString());
      prefs.remove(DateTime.tuesday.toString());
      prefs.remove(DateTime.wednesday.toString());
      prefs.remove(DateTime.thursday.toString());
      prefs.remove(DateTime.friday.toString());
      prefs.remove(DateTime.saturday.toString());
      prefs.remove(DateTime.sunday.toString());

      _dozingData = [
        DozingPerDay('Mn', prefs.getInt(DateTime.monday.toString()) ?? 0, Colors.blue),
        DozingPerDay('Tu', prefs.getInt(DateTime.tuesday.toString()) ?? 0, Colors.blue),
        DozingPerDay('Wd', prefs.getInt(DateTime.wednesday.toString()) ?? 0, Colors.blue),
        DozingPerDay('Th', prefs.getInt(DateTime.thursday.toString()) ?? 0, Colors.blue),
        DozingPerDay('Fr', prefs.getInt(DateTime.friday.toString()) ?? 0, Colors.blue),
        DozingPerDay('Sa', prefs.getInt(DateTime.saturday.toString()) ?? 0, Colors.blue),
        DozingPerDay('Su', prefs.getInt(DateTime.sunday.toString()) ?? 0, Colors.blue),
      ];
    }
    int num = prefs.getInt(DateTime.now().weekday.toString()) ?? 0;
    prefs.setInt(DateTime.now().weekday.toString(), num + 1);
    switch(DateTime.now().weekday){
      case DateTime.monday:
      _dozingData[0] = DozingPerDay('Mn', num + 1, Colors.blue);
      break;
      case DateTime.tuesday:
      _dozingData[1] = DozingPerDay('Tu', num + 1, Colors.blue);
      break;
      case DateTime.wednesday:
      _dozingData[2] = DozingPerDay('Wd', num + 1, Colors.blue);
      break;
      case DateTime.thursday:
      _dozingData[3] = DozingPerDay('Th', num + 1, Colors.blue);
      break;
      case DateTime.friday:
      _dozingData[4] = DozingPerDay('Fr', num + 1, Colors.blue);
      break;
      case DateTime.saturday:
      _dozingData[5] = DozingPerDay('Sa', num + 1, Colors.blue);
      break;
      case DateTime.sunday:
      _dozingData[6] = DozingPerDay('Su', num + 1, Colors.blue);
      break;
    }
    notifyListeners();
    prefs.setInt('today', DateTime.now().weekday);
  }
}