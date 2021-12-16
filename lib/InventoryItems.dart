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

class InventoryRecorditem extends StatefulWidget {
  InventoryRecorditem({Key key, this.inventoryid, this.date}) : super(key: key);
  int inventoryid;
  String date;

  @override
  State<StatefulWidget> createState() => InventoryRecorditemState();
}
List<dynamic> Itemlist;
var ItemStatus = ['正常', '借出', '報修', '遺失', '停用', '尚未盤點'];
class InventoryRecorditemState extends State<InventoryRecorditem>
    with TickerProviderStateMixin {
  Future<List<dynamic>> _callApi() async {
    var access_token = GV.tokenResponse.accessToken;

    try {
      var response = await http.get(
          Uri(
              scheme: 'http',
              host: '140.133.78.140',
              port: 81,
              path: 'Item/InventoryItemrecord',
              queryParameters: {'inventoryid': '${widget.inventoryid}'}),
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

  // List<dynamic> Itemlist;

  int Placeindex = 0;


  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: futureList,
      builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.hasData) {
          Itemlist = snapshot.data;

          return Scaffold(
              appBar: AppBar(
                title: Text(widget.date),
                actions: [
                  IconButton(
                      onPressed: () {
                        showSearch(context: context, delegate: Datasearch());
                      },
                      icon: Icon(Icons.search))
                ],
              ),
              body: ListView.builder(
                  itemCount: Itemlist.length,
                  itemBuilder: (context, index) {
                    var record = Itemlist[index];
                    var fireitem = record['fireitemsRef'];

                    return

                      Card(
                        child: ListTile(
                      title:
                          Text(fireitem['itemId'] + ' ' + fireitem['itemName']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '盤點前:' + ItemStatus[record['statusBefore']],
                            style: TextStyle(
                                color: record['statusBefore'] == 0
                                    ? Colors.grey
                                    : Colors.red),
                          ),
                          Text(
                            '盤點後:' +
                                (record['statusBefore'] == record['statusAfter']
                                    ? '狀態無異'
                                    : ItemStatus[record['statusAfter']]),
                            style: TextStyle(
                                color: record['statusAfter'] ==
                                        record['statusBefore']
                                    ? Colors.grey
                                    : Colors.red),
                          ),
                        ],
                      ),
                    ));
                  }));
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
    var suggestions = query.isEmpty? Itemlist:Itemlist.where((e) => e['fireitemsRef']['itemId'].toString().contains(query) ||e['fireitemsRef']['itemName'].toString().contains(query)).toList();
 var a=0;


    return ListView.builder(
      itemBuilder: (context, index) {
        var record = suggestions[index];
        var fireitem = record['fireitemsRef'];
        return

          Card(
              child: ListTile(
                title:
                Text(fireitem['itemId'] + ' ' + fireitem['itemName']),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '盤點前:' + ItemStatus[record['statusBefore']],
                      style: TextStyle(
                          color: record['statusBefore'] == 0
                              ? Colors.grey
                              : Colors.red),
                    ),
                    Text(
                      '盤點後:' +
                          (record['statusBefore'] == record['statusAfter']
                              ? '狀態無異'
                              : ItemStatus[record['statusAfter']]),
                      style: TextStyle(
                          color: record['statusAfter'] ==
                              record['statusBefore']
                              ? Colors.grey
                              : Colors.red),
                    ),
                  ],
                ),
              ));

      },
      itemCount: suggestions.length,
    );
  }
}
