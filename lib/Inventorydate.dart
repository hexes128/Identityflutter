import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:identityflutter/GlobalVariable.dart' as GV;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:identityflutter/InventoryItems.dart';
import 'package:intl/intl.dart';
import 'package:scan/scan.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:future_progress_dialog/future_progress_dialog.dart';

class InventoryRecord extends StatefulWidget {
  InventoryRecord({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => InventoryRecordState();
}

class InventoryRecordState extends State<InventoryRecord>
    with TickerProviderStateMixin , WidgetsBindingObserver{
  Future<List<dynamic>> _callApi() async {
    var access_token =GV.info['accessToken'];

    try {
      var response = await http.get(
          Uri(
              scheme: 'http',
              host: '140.133.78.140',
              port: 81,
              path: 'Item/inventoryrecord'),
          headers: {"Authorization": "Bearer $access_token"});
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {}
    } on Error catch (e) {
      throw Exception('123');
    }
  }

  @override
  void initState() {
    super.initState();
    futureList = _callApi();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if(state.index==0){
      if(     DateTime.parse(GV.info['accessTokenExpirationDateTime']).difference(DateTime.now()).inSeconds<GV.settimeout){
        GV.timeout=true;
        Navigator.of(context).popUntil((route) =>route.isFirst
        );
      }

    }
  }

  Future<List<dynamic>> futureList;

  List<dynamic> PlaceList;

  int Placeindex = 0;



  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: futureList,
      builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.hasData) {
          PlaceList = snapshot.data;
          var place = PlaceList[Placeindex];
          List<dynamic> eventlist = place['inventoryEventList'];
          eventlist.sort((a,b)=>DateTime.parse(a['inventoryDate']).isBefore(DateTime.parse(b['inventoryDate']))?1:-1);
          print(place['placeName']);
          var a = 0;
          return Scaffold(
              appBar: AppBar(
                title:  CupertinoPicker(
                  children: PlaceList.map((e) =>
                      Center(child: Text(e['placeName']))).toList(),
                  itemExtent: 50,
                  onSelectedItemChanged: (int index) {
                    setState(() {
                      Placeindex = index;
                    });
                  },
                ),

              ),
              body: ListView(
                shrinkWrap: true,
                children:
                eventlist
                    .map((e) {
                      DateTime etime = DateTime.parse(e['inventoryDate']);
                      return DateTime(etime.year, etime.month);
                    })
                    .toSet()
                    .map((e) => ExpansionTile(
                          title: Text('${e.year}年 ${e.month}月'),
                          children: eventlist
                              .where((x) => (DateTime.parse(x['inventoryDate'])
                                          .year ==
                                      e.year &&
                                  (DateTime.parse(x['inventoryDate']).month ==
                                      e.month)))
                              .map((y) {
                            return Card(
                                child: ListTile(
                                    title: Text(DateFormat('MM/dd kk:mm')
                                        .format(DateTime.parse(
                                            y['inventoryDate']))),
                                subtitle: Text(y['userName']),

                                onTap: (){  Navigator.push(
                                  //從登入push到第二個
                                  context,
                                  new MaterialPageRoute(
                                      builder: (context) => InventoryRecorditem(inventoryid:y['eventId'],date: DateFormat('MM/dd kk:mm')
                                          .format(DateTime.parse(
                                          y['inventoryDate'])) )),
                                );},));
                          }).toList(),

                        ))
                    .toList(),
              ));
        } else if (snapshot.hasError) {
          return Text('錯誤');
        } else {
          return Scaffold(
            body: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Text(
                        '資料讀取中',
                        style: Theme.of(context).textTheme.headline6,
                      ),
                      CircularProgressIndicator(),
                    ],
                  ),
                )),
          );
        }
      },
    );
  }
}
