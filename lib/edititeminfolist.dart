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
              host: '192.168.10.152',
              port: 3000,
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

  Future<String> sendInventory(List<dynamic> iteminfo) async {
    var access_token = GV.tokenResponse.accessToken;

    try {
      var response = await http.post(
          Uri(
              scheme: 'http',
              host: '192.168.10.152',
              port: 3000,
              path: 'Item/Inventory'),
          headers: {
            "Authorization": "Bearer $access_token",
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, dynamic>{
            'UserId': GV.userinfo.name,
            'PlaceId': PlaceList[Placeindex]['placeId'],
            'InventoryItemList': iteminfo
          }));

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
              actions: [

                PopupMenuButton(
                  icon: Icon(Icons.more_vert),
                  itemBuilder: (BuildContext context) => <PopupMenuEntry>[
                    // PopupMenuItem(
                    //   child: ListTile(
                    //     onTap: () {
                    //       Navigator.pop(context);
                    //       showDialog<String>(
                    //         context: context,
                    //         builder: (BuildContext context) => AlertDialog(
                    //           title: Text('請選擇地點'),
                    //           content: Container(
                    //             width: double.maxFinite,
                    //             child: ListView.builder(
                    //               shrinkWrap: true,
                    //               itemCount: PlaceList.length,
                    //               itemBuilder: (context, index) {
                    //                 return Card(
                    //                     child: ListTile(
                    //                   onTap: () {
                    //                     setState(() {
                    //                       Placeindex = index;
                    //                       Areaindex = 0;
                    //                       tabController.animateTo(0);
                    //                     });
                    //
                    //                     Navigator.pop(context);
                    //                   },
                    //                   title: Text(PlaceList[index]
                    //                           ['placeName'] +
                    //                       (PlaceList[index]['todaysend']
                    //                           ? '(已完成)'
                    //                           : '')),
                    //                   subtitle: Placeindex == index
                    //                       ? Text('當前選擇')
                    //                       : null,
                    //                 ));
                    //               },
                    //             ),
                    //           ),
                    //         ),
                    //       );
                    //     },
                    //     leading: Icon(Icons.switch_left),
                    //     title: Text('切換地點'),
                    //   ),
                    // ),
                    PopupMenuItem(
                      child: ListTile(
                        onTap: () {
                          Navigator.pop(context);
                          showDialog<String>(
                            context: context,
                            builder: (BuildContext context) => AlertDialog(
                              title: Text(
                                  '${PlaceList[Placeindex]['placeName']} ${AreaList[Areaindex]['subArea']}'),
                              content: const Text('將會清除本區勾選'),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text('取消'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      ItemList.forEach((e) {
                                        if (e['presentStatus'] == 0) {
                                          e['inventoryStatus'] = 5;
                                        }
                                      });
                                    });
                                    Navigator.pop(context);
                                  },
                                  child: const Text('確定'),
                                ),
                              ],
                            ),
                          );
                        },
                        leading: Icon(Icons.delete_forever),
                        title: Text('本區重新盤點'),
                      ),
                    ),
                    PopupMenuItem(
                      child: ListTile(
                        onTap: () {
                          Navigator.pop(context);
                          if (PlaceList[Placeindex]['todaysend']) {
                            Fluttertoast.showToast(
                                msg: PlaceList[Placeindex]['placeName'] +
                                    '已完成盤點',
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.CENTER,
                                timeInSecForIosWeb: 1,
                                backgroundColor: Colors.red,
                                textColor: Colors.white,
                                fontSize: 16.0);
                            return;
                          }
                          List<dynamic> groupItemList =
                          AreaList.map((e) => e['fireitemList'])
                              .expand((e) => e)
                              .toList();

                          List<dynamic> sendItemList = [];

                          if (groupItemList
                              .where((e) => e['inventoryStatus'] == 5)
                              .length ==
                              0) {
                            groupItemList.forEach((e) {
                              sendItemList.add({
                                'ItemId': e['itemId'],
                                'StatusBefore': e['presentStatus'],
                                'StatusAfter': e['inventoryStatus']
                              });
                            });

                            showDialog<String>(
                              context: context,
                              builder: (BuildContext context) =>
                                  AlertDialog(
                                    title: Text(
                                        PlaceList[Placeindex]['placeName']),
                                    content: Text('確認送出盤點紀錄?'),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () {
                                          print(jsonEncode(sendItemList));
                                          Navigator.pop(
                                            context,
                                          );
                                        },
                                        child: Text('取消'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(
                                            context,
                                          );
                                          showDialog(
                                            context: context,
                                            builder: (context) =>
                                                FutureProgressDialog(
                                                    sendInventory(sendItemList)
                                                        .then((value) {
                                                      Fluttertoast.showToast(
                                                          msg: '成功新增' +
                                                              value +
                                                              '筆紀錄',
                                                          toastLength: Toast
                                                              .LENGTH_SHORT,
                                                          gravity: ToastGravity
                                                              .CENTER,
                                                          timeInSecForIosWeb: 1,
                                                          backgroundColor:
                                                          Colors.red,
                                                          textColor:
                                                          Colors.white,
                                                          fontSize: 16.0);
                                                      PlaceList[Placeindex]
                                                      ['todaysend'] = true;
                                                    }),
                                                    message: Text('資料處理中，請稍後')),
                                          );
                                        },
                                        child: const Text('確定'),
                                      ),
                                    ],
                                  ),
                            );
                          } else {
                            Fluttertoast.showToast(
                                msg: '尚有物品未盤點，請確認後再送出',
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.CENTER,
                                timeInSecForIosWeb: 1,
                                backgroundColor: Colors.red,
                                textColor: Colors.white,
                                fontSize: 16.0);
                          }
                        },
                        leading: Icon(Icons.cloud_upload),
                        title: Text(
                            '送出${PlaceList[Placeindex]['placeName']}盤點'),
                      ),
                    ),
                    PopupMenuDivider(),
                    PopupMenuItem(
                      onTap: () => setState(() {
                        // Ddefaultshow = !Ddefaultshow;
                      }),
                      child: ListTile(
                        leading: Icon(Icons.settings_display),
                        title: Text('變更顯示模式'),
                      ),
                    ),
                  ],
                ),
              ],
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
