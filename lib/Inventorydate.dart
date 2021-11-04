import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:identityflutter/GlobalVariable.dart' as GV;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
    with TickerProviderStateMixin {
  Future<List<dynamic>> _callApi() async {
    var access_token = GV.tokenResponse.accessToken;

    try {
      var response = await http.get(
          Uri(
              scheme: 'http',
              host: '192.168.10.152',
              port: 3000,
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
  }

  Future<List<dynamic>> futureList;

  List<dynamic> PlaceList;

  int Placeindex = 0;

  Future<String> sendInventory(List<dynamic> iteminfo) async {
    var access_token = GV.tokenResponse.accessToken;

    try {
      var response = await http.get(
        Uri(
            scheme: 'http',
            host: '192.168.10.152',
            port: 3000,
            path: 'Item/inventoryrecord'),
        headers: {
          "Authorization": "Bearer $access_token",
        },
      );

      if (response.statusCode == 200) {
        print(response.body);
        return response.body;
      } else {
        print('錯誤');
      }
    } on Error catch (e) {
      throw Exception('123');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: futureList,
      builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.hasData) {
          PlaceList = snapshot.data;
          var place = PlaceList[Placeindex];
          List<dynamic> eventlist = place['inventoryEventList'];
          print(place['placeName']);
          var a = 0;
          return Scaffold(
              appBar: AppBar(
                title: Text(place['placeName']),
                actions: [
                  PopupMenuButton(
                    icon: Icon(Icons.more_vert),
                    itemBuilder: (BuildContext context) => <PopupMenuEntry>[
                      PopupMenuItem(
                        child: ListTile(
                          onTap: () {
                            Navigator.pop(context);
                            showDialog<String>(
                              context: context,
                              builder: (BuildContext context) => AlertDialog(
                                title: Text('請選擇地點'),
                                content: Container(
                                  width: double.maxFinite,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: PlaceList.length,
                                    itemBuilder: (context, index) {
                                      return Card(
                                          child: ListTile(
                                        onTap: () {
                                          setState(() {
                                            Placeindex = index;
                                          });

                                          Navigator.pop(context);
                                        },
                                        title: Text(PlaceList[index]
                                                ['placeName'] +
                                            (PlaceList[index]['todaysend']
                                                ? '(已完成)'
                                                : '')),
                                        subtitle: Placeindex == index
                                            ? Text('當前選擇')
                                            : null,
                                      ));
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                          leading: Icon(Icons.switch_left),
                          title: Text('切換地點'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              body: ListView(
                shrinkWrap: true,
                children: eventlist
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
                                subtitle: Text(y['userId']),));
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
