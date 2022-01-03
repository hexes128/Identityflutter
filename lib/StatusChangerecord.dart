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
List<dynamic> recordlist;

var ItemStatus = ['正常', '借出', '報修', '遺失', '停用', '尚未盤點'];
class StatusRecordState extends State<StatusRecord>
  with WidgetsBindingObserver {
  ScanController scanController = ScanController();

  Future<List<dynamic>> _callApi() async {
    var access_token =GV.info['accessToken'];

    try {
      var response = await http.get(
          Uri(
              scheme: 'http',
              host: '140.133.78.140',
              port: 81,
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
    return  FutureBuilder<List<dynamic>>(
      future: futureList,
      builder:
          (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.hasData) {
          PlaceList = snapshot.data;
          var Place = PlaceList[Placeindex];
         recordlist = Place['statusChangeList'];
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
                  IconButton(
                      onPressed: () {
                        showSearch(context: context, delegate: Datasearch());
                      },
                      icon: Icon(Icons.search))
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

                        return
                          Card(
                            child: ListTile(

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
class Datasearch extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [IconButton(onPressed: () {
      close(context, null);

    }, icon: Icon(Icons.clear))];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
        onPressed: () {
          close(context, null);
        },
        icon: AnimatedIcon(
          icon: AnimatedIcons.menu_arrow,
          progress: transitionAnimation,
        ));
  }

  @override
  Widget buildResults(BuildContext context) {
    // TODO: implement buildResults
    throw UnimplementedError();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    var suggestions = query.isEmpty? recordlist:recordlist.where((e) => e['fireitemRef']['itemId'].toString().contains(query) ||e['fireitemRef']['itemName'].toString().contains(query)).toList();
    var a=0;




    return ListView.builder(
      itemBuilder: (context, index) {
        var record = suggestions[index];
        var fireitem = record['fireitemRef'];
        var a =0;
        return

          Card(
              child: ListTile(

                title: Text(fireitem['itemId'] +
                    ' ' +
                    fireitem['itemName']),
                subtitle: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      '原始狀態:'
                          +
                          ItemStatus[record['beforechange']],

                    ),
                    Text(
                      '更改狀態:' +
                          ItemStatus[record['statusCode']],

                    ),
                    Text(
                        '日期:' +
                            DateFormat('yyyy/MM/dd kk:mm').format(DateTime.parse( record['changeDate']))

                    ),
                    Text(
                        '更改人:' +
                            record['userId'])


                  ],
                ),



                onTap: (){ },));

      },
      itemCount: suggestions.length,
    );
  }
}