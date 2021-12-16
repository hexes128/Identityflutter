import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:identityflutter/GlobalVariable.dart' as GV;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:scan/scan.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:future_progress_dialog/future_progress_dialog.dart';

import 'editpage.dart';

class editinfolist extends StatefulWidget {
  editinfolist({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => editinfostate();
}

class editinfostate extends State<editinfolist>
    with TickerProviderStateMixin {
  ScanController scanController = ScanController();

  Future<List<dynamic>> _callApi() async {
    var access_token = GV.tokenResponse.accessToken;

    try {
      var response = await http.get(
          Uri(
              scheme: 'http',
              host: '140.133.78.140',
              port: 81,
              path: 'Item/GetItem'),
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
    tabController = TabController(length: 0, vsync: this);
  }

  Future<List<dynamic>> futureList;

  List<dynamic> PlaceList;
  List<dynamic> AreaList;
  List<dynamic> ItemList;
  int Areaindex = 0;
  int Placeindex = 0;
  var ItemStatus = ['正常', '借出', '報修', '遺失', '停用', '尚未盤點'];

  TabController tabController;

  // bool Ddefaultshow = true;

  Future<bool> _onWillPop() async {
    return (await showDialog(
      context: context,
      builder: (context) => new AlertDialog(
        title: new Text('退出盤點'),
        content: new Text('盤點狀態將會清空，確定是否退出?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: new Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: new Text('確定'),
          ),
        ],
      ),
    )) ??
        false;
  }



  @override
  Widget build(BuildContext context) {
    return   FutureBuilder<List<dynamic>>(
      future: futureList,
      builder:
          (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.hasData) {
          PlaceList = snapshot.data;
          AreaList = PlaceList[Placeindex]['priorityList'];
          AreaList.sort(
                  (a, b) => a['priorityNum'].compareTo(b['priorityNum']));
          ItemList = AreaList[Areaindex]['fireitemList'];

          tabController = TabController(
              length: AreaList.length,
              vsync: this,
              initialIndex: Areaindex);
          tabController.addListener(() {
            if (tabController.indexIsChanging) {
              setState(() {
                Areaindex = tabController.index;
              });
            }
          });
          return Scaffold(
            appBar: AppBar(
              title: Row(
                children: [
                  Expanded(
                    child: CupertinoPicker(
                      children: PlaceList.map(
                              (e) => Center(child: Text(e['placeName'])))
                          .toList(),
                      itemExtent: 50,
                      onSelectedItemChanged: (int index) {
                        setState(() {
                          Placeindex = index;
                          Areaindex = 0;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: Text(
                        AreaList[Areaindex]['subArea'] ),
                  )
                ],
              ),
           
            ),
            body:

            ListView.builder(
                itemCount: ItemList.length,
                itemBuilder: (context, index) {
                  var Fireitem = ItemList[index];
                  if (Fireitem['presentStatus'] != 0) {
                    Fireitem['inventoryStatus'] =
                    Fireitem['presentStatus'];
                  }

                  return Card(
                      child: ListTile(
                        enabled: Fireitem['presentStatus'] == 0,

                        title: Text(Fireitem['itemId'] +
                            ' ' +
                            Fireitem['itemName']),
                        subtitle: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              '當前狀態:' +
                                  ItemStatus[
                                  Fireitem['presentStatus']],
                              style: TextStyle(
                                  color:
                                  Fireitem['presentStatus'] == 0
                                      ? Colors.grey
                                      : Colors.red),
                            ),

                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            //從登入push到第二個
                            context,
                            new MaterialPageRoute(
                                builder: (context) => editietm(Fireitem:Fireitem ,initialplace: Placeindex,initialarea: Areaindex,)),
                          ).then((value) {
                            setState(() {
                              futureList=_callApi();
                            });
                          });
                        },

                      ));
                }),
            bottomNavigationBar: Material(
              color: Theme.of(context).primaryColor,
              child: TabBar(
                  controller: tabController,
                  indicatorColor: Colors.black,
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.white,
                  isScrollable: true,
                  tabs: AreaList.map((e) => Tab(
                      text: e['subArea'] +
                          ' ' +
                          '(${e['fireitemList'].length})'))
                      .toList()),
            ),
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
