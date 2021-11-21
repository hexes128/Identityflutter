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

class StatusRecord extends StatefulWidget {
  StatusRecord({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => StatusRecordState();
}

class StatusRecordState extends State<StatusRecord>
   {
  ScanController scanController = ScanController();

  Future<List<dynamic>> _callApi() async {
    var access_token = GV.tokenResponse.accessToken;

    try {
      var response = await http.get(
          Uri(
              scheme: 'http',
              host: '192.168.10.152',
              port: 3000,
              path: 'Item/ChangeStatusRecord'),
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
  var ItemStatus = ['正常', '借出', '報修', '遺失', '停用', '尚未盤點'];







  @override
  Widget build(BuildContext context) {
    return  FutureBuilder<List<dynamic>>(
      future: futureList,
      builder:
          (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.hasData) {
          PlaceList = snapshot.data;
          var Place = PlaceList[Placeindex];
          List<dynamic> recordlist = Place['statusChangeList'];
recordlist.sort((a,b)=>DateTime.parse(a['changeDate']).isBefore(DateTime.parse(b['changeDate']))?1:-1);

          return Scaffold(
              appBar: AppBar(
                title:
                CupertinoPicker(
                  children: PlaceList.map((e) =>
                      Center(child: Text(e['placeName']))).toList(),
                  itemExtent: 50,
                  onSelectedItemChanged: (int index) {
                    setState(() {
                      Placeindex = index;
                    });
                  },
                ),
                // Text(Place['placeName'] ),
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
              body:
                  ListView(
                    shrinkWrap: true,
                    children:     recordlist
                        .map((e) {
                      DateTime etime = DateTime.parse(e['changeDate']);
                      return DateTime(etime.year, etime.month);
                    })
                        .toSet()
                        .map((e) => ExpansionTile(
                      title: Text('${e.year}年 ${e.month}月'),
                      children: recordlist
                          .where((x) => (DateTime.parse(x['changeDate'])
                          .year ==
                          e.year &&
                          (DateTime.parse(x['changeDate']).month ==
                              e.month)))
                          .map((y) {

                        return Card(
                            child: ListTile(
                              // title: Text(DateFormat('MM/dd kk:mm')
                              //     .format(DateTime.parse(
                              //     y['changeDate']))),
                                          title: Text(y['fireitemRef']['itemId'] +
                                              ' ' +
                                              y['fireitemRef']['itemName']),
                              subtitle: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '原始狀態:'
                                                  +
                                                  ItemStatus[y['beforechange']],

                                            ),
                                            Text(
                                              '更改狀態:' +
                                                  ItemStatus[y['statusCode']],

                                            ),
                                            Text(
                                                '日期:' +
                                                    DateFormat('yyyy/MM/dd kk:mm').format(DateTime.parse( y['changeDate']))

                                            ),
                                            Text(
                                                '更改人:' +
                                                    y['userId'])


                                          ],
                                        ),



                              onTap: (){ },));
                      }).toList(),

                    ))
                        .toList(),
                  )



              // ListView.builder(
              //     itemCount: recordlist.length,
              //     itemBuilder: (context, index) {
              //       var record = recordlist[index];
              //       var Fireitem = record['fireitemRef'];
              //
              //
              //       return Card(
              //           child: ListTile(
              //
              //
              //             title: Text(Fireitem['itemId'] +
              //                 ' ' +
              //                 Fireitem['itemName']),
              //             subtitle: Column(
              //               crossAxisAlignment:
              //               CrossAxisAlignment.start,
              //               children: [
              //                 Text(
              //                   '原始狀態:'
              //                       +
              //                       ItemStatus[record['beforechange']],
              //
              //                 ),
              //                 Text(
              //                   '更改狀態:' +
              //                       ItemStatus[record['statusCode']],
              //
              //                 ),
              //                 Text(
              //                     '日期:' +
              //                         DateFormat('yyyy/MM/dd kk:mm').format(DateTime.parse( record['changeDate']))
              //
              //                 ),
              //                 Text(
              //                     '更改人:' +
              //                         record['userId'])
              //
              //
              //               ],
              //             ),
              //
              //
              //           ));
              //     })
          );
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
