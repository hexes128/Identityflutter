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

class EditinfoRecord extends StatefulWidget {
  EditinfoRecord({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => EditinfoRecordState();
}

List<dynamic> recordlist;
class EditinfoRecordState extends State<EditinfoRecord>  with  WidgetsBindingObserver  {
  ScanController scanController = ScanController();

  Future<List<dynamic>> _callApi() async {
    var access_token =GV.info['accessToken'];

    try {
      var response = await http.get(
          Uri(
              scheme: 'http',
              host: '140.133.78.140',
              port: 81,
              path: 'Item/editinforecord'),
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: futureList,
      builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.hasData) {
           recordlist = snapshot.data;
          recordlist.sort((a, b) => DateTime.parse(a['changeDate'])
                  .isBefore(DateTime.parse(b['changeDate']))
              ? 1
              : -1);

          return Scaffold(
              appBar: AppBar(
                title: Text('資訊編輯紀錄'),
                actions: [
                  IconButton(
                      onPressed: () {
                        showSearch(context: context, delegate: Datasearch());
                      },
                      icon: Icon(Icons.search))
                ],

                // Text(Place['placeName'] ),
              ),
              body:
              ListView(
                shrinkWrap: true,
                children: recordlist
                    .map((e) {
                  DateTime etime = DateTime.parse(e['changeDate']);
                  return DateTime(etime.year, etime.month);
                })
                    .toSet()
                    .map((e) => ExpansionTile(
                  title: Text('${e.year}年 ${e.month}月'),
                  children: snapshot.data
                      .where((x) => (DateTime.parse(x['changeDate'])
                      .year ==
                      e.year &&
                      (DateTime.parse(x['changeDate']).month ==
                          e.month)))
                      .map((y) {
                    return
                      Card(child:  Column(
                        children: [
                          Container(
                            child: Center(child: Text(y['itemid'])),
                            width: double.infinity,
                          ),
                          Row(
                            children: [
                              Expanded(child:
                              ListTile(
                                title: Text('編輯前'),

                                subtitle: Text('設備名稱:'+y['oldname']+'\n'+'地點:'+y['oldplace']+'\n'+'區域:'+y['oldarea']),
                              )
                                ,
                                flex: 1,),
                              Expanded(child:
                              ListTile(
                                title:  Text('編輯後'),

                                subtitle: Text('設備名稱:'+y['newname']+'\n'+'地點:'+y['newplace']+'\n'+'區域:'+y['newarea']),
                              ),
                                flex: 1,),




                            ],
                          ),
                          Container(
                            child: Center(child: Text(
                                '更動人:'+y['userId']+' 日期:'+
                                    DateFormat('MM/dd kk:mm')
                                        .format(DateTime.parse(
                                        y['changeDate'])))),
                            width: double.infinity,
                          ),
                        ],
                      ))
                    ;
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
    var suggestions = query.isEmpty? recordlist:recordlist.where((e) => e['itemid'].toString().contains(query)).toList();
    var a=0;




    return ListView.builder(
      itemBuilder: (context, index) {
        var record = suggestions[index];

        var a =0;
        return

          Card(child:  Column(
            children: [
              Container(
                child: Center(child: Text(record['itemid'])),
                width: double.infinity,
              ),
              Row(
                children: [
                  Expanded(child:
                  ListTile(
                    title: Text('編輯前'),

                    subtitle: Text('設備名稱:'+record['oldname']+'\n'+'地點:'+record['oldplace']+'\n'+'區域:'+record['oldarea']),
                  )
                    ,
                    flex: 1,),
                  Expanded(child:
                  ListTile(
                    title:  Text('編輯後'),

                    subtitle: Text('設備名稱:'+record['newname']+'\n'+'地點:'+record['newplace']+'\n'+'區域:'+record['newarea']),
                  ),
                    flex: 1,),




                ],
              ),
              Container(
                child: Center(child: Text(
                    '更動人:'+record['userId']+' 日期:'+
                        DateFormat('MM/dd kk:mm')
                            .format(DateTime.parse(
                            record['changeDate'])))),
                width: double.infinity,
              ),
            ],
          ))
        ;

      },
      itemCount: suggestions.length,
    );
  }
}
