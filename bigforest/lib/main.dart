import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:charts_flutter/flutter.dart' as charts;


void main() => runApp(MyApp());
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
    title:'Doz',
    home:Graph(title: 'Doz'),
  );
}

class Graph extends StatefulWidget{
  Graph({Key key, this.title}):super(key:key);

  final String title;

  @override
  _GraphState createState() => _GraphState();
}

class _GraphState extends State<Graph>{
  @override
  Widget build(BuildContext context){
    Data d = Data();
    int monday = d.day[0];
    int tuesday = d.day[1];
    int wednesday = d.day[2];
    int thursday = d.day[3];
    int friday = d.day[4];
    int saturday = d.day[5];
    int sunday = d.day[6];

    var data = [
      DozingPerDay('Mn', monday, Colors.blue),
      DozingPerDay('Tu', tuesday, Colors.blue),
      DozingPerDay('Wd', wednesday, Colors.blue),
      DozingPerDay('Th', thursday, Colors.blue),
      DozingPerDay('Fr', friday, Colors.blue),
      DozingPerDay('Sa', saturday, Colors.blue),
      DozingPerDay('Su', sunday, Colors.blue),
    ];

    var series = [
      charts.Series(
        id: 'Dozing Time',
        domainFn: (DozingPerDay dozingData, _) => dozingData.day,
        measureFn: (DozingPerDay dozingData, _) => dozingData.dozingTime,
        colorFn: (DozingPerDay dozingData, _) => dozingData.color,
        data: data,
      ),
    ];

    var chart = charts.BarChart(
      series,
      animate: true,
    );

    var chartWidget = Padding(
      padding: EdgeInsets.all(32.0),
      child: SizedBox(
        height: 200.0,
        child: chart,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            chartWidget
          ],
        ),
      )
    );
  }
}



class DozingPerDay {
  final String day;
  final int dozingTime;
  final charts.Color color;

  DozingPerDay(this.day, this.dozingTime, Color color)
    :this.color = charts.Color(
      r: color.red, g: color.green, b: color.blue, a:color.alpha
    );
}

/*
  DateTime.day
  monday:1
  tuesday:2
  wednesday:3
  thursday:4
  friday:5
  saturday:6
  sunday:7
*/
// https://api.dart.dev/stable/2.7.1/dart-core/DateTime-class.html

class Data {
  Doze dozing = Doze();
  //List<Future<int>> day;
  var day = List.filled(7, 0);
  DateTime _now = DateTime.now();

  Data(){
    if(_now.day != getDayData()){
      switch(_now.day){
        case DateTime.monday:
        saveSundayData(getTodayData());
        break;
        case DateTime.tuesday:
        saveMondayData(getTodayData());
        break;
        case DateTime.wednesday:
        saveTuesdayData(getTodayData());
        break;
        case DateTime.thursday:
        saveWednesdayData(getTodayData());
        break;
        case DateTime.friday:
        saveThursdayData(getTodayData());
        break;
        case DateTime.saturday:
        saveFridayData(getTodayData());
        break;
        case DateTime.sunday:
        saveSaturdayData(getTodayData());
        break;
      }
      removeTodayData();
      saveTodayData(_now.day);
    }

    // データ削除
    if(_now.day == DateTime.monday){
      removeData();
    }

    // 曜日ごとのデータを同期
    day[0] = getMondayData();
    day[1] = getTuesdayData();
    day[2] = getWednesdayData();
    day[3] = getThursdayData();
    day[4] = getFridayData();
    day[5] = getSaturdayData();
    day[6] = getSundayData();

    // 今日のデータを同期
    switch(_now.day){
      case DateTime.monday:
      day[0] = getTodayData();
      break;
      case DateTime.tuesday:
      day[1] = getTodayData();
      break;
      case DateTime.wednesday:
      day[2] = getTodayData();
      break;
      case DateTime.thursday:
      day[3] = getTodayData();
      break;
      case DateTime.friday:
      day[4] = getTodayData();
      break;
      case DateTime.saturday:
      day[5] = getTodayData();
      break;
      case DateTime.sunday:
      day[6] = getTodayData();
      break;
    }

    organize();
  }

  void organize() async {
    while(true){
      if(dozing.isDozing()){
        saveTodayData(getTodayData() + 1);
        switch(_now.day){
          case DateTime.monday:
          day[0]++;
          break;
          case DateTime.tuesday:
          day[1]++;
          break;
          case DateTime.wednesday:
          day[2]++;
          break;
          case DateTime.thursday:
          day[3]++;
          break;
          case DateTime.friday:
          day[4]++;
          break;
          case DateTime.saturday:
          day[5]++;
          break;
          case DateTime.sunday:
          day[6]++;
          break;
        }
      }
    }
  }

  // 各曜日のデータ保存

  void saveTodayData(int num) async {
    saveIntData('Today', num);
  }

  void saveDay(int day) async {
    saveIntData('Day', day);
  }

  void saveMondayData(int num) async {
    saveIntData('Monday', num);
  }

  void saveTuesdayData(int num) async {
    saveIntData('Tuesday', num);
  }

  void saveWednesdayData(int num) async {
    saveIntData('Wednesday', num);
  }

  void saveThursdayData(int num) async {
    saveIntData('Thursay', num);
  }

  void saveFridayData(int num) async {
    saveIntData('Friday', num);
  }

  void saveSaturdayData(int num) async {
    saveIntData('Saturday', num);
  }

  void saveSundayData(int num) async {
    saveIntData('Sunday', num);
  }

  // 各曜日のデータ取得

  getTodayData() async {
    return getIntData('Today');
  }

  getDayData(){
    return getIntData('Day');
  }

  getMondayData(){
    return getIntData('Monday');
  }

  getTuesdayData(){
    return getIntData('Tuesday');
  }

  getWednesdayData(){
    return getIntData('Wednesday');
  }

  getThursdayData(){
    return getIntData('Thursday');
  }

  getFridayData(){
    return getIntData('Friday');
  }

  getSaturdayData(){
    return getIntData('Saturday');
  }

  getSundayData(){
    return getIntData('SunDay');
  }

  void removeData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('Monday');
    prefs.remove('Tuesday');
    prefs.remove('Wednesday');
    prefs.remove('Thursday');
    prefs.remove('Friday');
    prefs.remove('Saturday');
    prefs.remove('Sunday');
  }
  void removeTodayData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('Today');
  }

  // データが存在しなかった場合はnull
  getIntData(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int num = prefs.getInt(id);
    if(num == null){
      return 0;
    } else {
      return num;
    }
  }

  void saveIntData(String id, int num) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt(id, num);
  }
}
class Doze{
  // アドレスは後で変更する
  final String address = 'addresss';
  String result = '';
  List<int> data;

  // 呼び出しと同時にデータ取得が始まる
  Doze(){
    start();
  }

  // bluetoothでデータを取得するメソッド
  void start() async {
    try {
      BluetoothConnection connection = await BluetoothConnection.toAddress(address);
      connection.input.listen((Uint8List data) {
        String str = ascii.decode(data);
        data = str.split(",") as Uint8List;
        //connection.output.add(data); // Sending data
        //接続を解除
        if (ascii.decode(data).contains('!')) {
          connection.finish();
          result = 'Disconnecting by local host'; // Closing connection
        }
      }).onDone(() {
        // 接続を解除
        result = 'Disconnected by remote request';
      });
    }catch(exception){
      // 接続失敗
      result = 'failed to connect';
    }
  }

  bool isDozing()
  {
    return true;
  }
}