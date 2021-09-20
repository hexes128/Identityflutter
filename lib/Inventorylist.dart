import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:identityflutter/GlobalVariable.dart' as GV;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:scan/scan.dart';
import 'package:flutter_switch/flutter_switch.dart';

class InventoryList extends StatefulWidget {
  InventoryList({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => InventoryListState();
}

class InventoryListState extends State<InventoryList>
    with TickerProviderStateMixin {
  ScanController scanController = ScanController();

  Future<List<dynamic>> _callApi() async {
    var access_token = GV.tokenResponse.accessToken;

    try {
      var response = await http.get(
          Uri(
              scheme: 'http',
              host: '192.168.10.152',
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
  bool allChecked = false;
  List<dynamic> PlaceList;
  List<dynamic> AreaList;
  List<dynamic> ItemList;
  int Areaindex = 0;
  int Placeindex = 0;
  var status = ['正常', '借出', '報修', '停用'];
  TabController tabController;
  bool showcamera = false;
  bool Ddefaultshow = true;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: futureList,
      builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.hasData) {
          PlaceList = snapshot.data;
          AreaList = PlaceList[Placeindex]['priorityList'];
          AreaList.sort((a, b) => a['priorityNum'].compareTo(b['priorityNum']));
          ItemList = AreaList[Areaindex]['fireitemList'];

          tabController = TabController(
              length: AreaList.length, vsync: this, initialIndex: Areaindex);
          tabController.addListener(() {
            if (tabController.indexIsChanging) {
              setState(() {
                Areaindex = tabController.index;
              });
            }
          });
          return Scaffold(
            appBar: AppBar(
              title: Text(PlaceList[Placeindex]['placeName'] +
                  '(' +
                  AreaList[Areaindex]['subArea'] +
                  ')'),
              actions: [
                FlutterSwitch(
                  width: 60.0,
                  height: 30.0,
                  toggleSize: 20.0,
                  value: showcamera,
                  borderRadius: 30.0,
                  padding: 2.0,
                  toggleColor: Colors.black,
                  activeColor: Colors.red,
                  showOnOff: true,
                  activeIcon: Icon(
                    Icons.camera_alt,
                  ),
                  inactiveIcon: Icon(
                    Icons.camera_alt,
                    color: Color(0xFFFFDF5D),
                  ),
                  onToggle: (val) {
                    setState(() {
                      showcamera = val;
                    });
                  },
                ),
                PopupMenuButton(
                  icon: Icon(Icons.more_vert),
                  itemBuilder: (BuildContext context) => <PopupMenuEntry>[
              

                    PopupMenuItem(
                      onTap: () => setState(() {
                        Ddefaultshow = !Ddefaultshow;
                      }),
                      child: ListTile(
                        leading: Icon(Icons.settings_display),
                        title: Text('變更顯示模式'),
                      ),
                    ),
                    PopupMenuItem(

                      child: ListTile(
                        onTap: () {
                          Navigator.pop(context);
                            showDialog<String>(
                          context: context,
                          builder: (BuildContext context) => AlertDialog(
                            title:  Text('${PlaceList[Placeindex]['placeName']} ${AreaList[Areaindex]['subArea']}'),
                            content: const Text('將會清除本區勾選'),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () {



                                  Navigator.pop(context);},
                                child: const Text('取消'),
                              ),
                              TextButton(
                                onPressed: () { setState(() {
                                  ItemList.forEach((e) {e['ischeck']=false; });
                                });
                                  Navigator.pop(context);},
                                child: const Text('確定'),
                              ),
                            ],
                          ),
                        );},
                        leading: Icon(Icons.delete_forever),
                        title: Text('本區重新盤點'),
                      ),
                    ),
                    PopupMenuItem(
                      child: ListTile(
                        leading: Icon(Icons.cloud_upload),
                        title: Text('送出盤點'),
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(child: Text('Item A')),
                    const PopupMenuItem(child: Text('Item B')),
                  ],
                ),
              ],
            ),
            body: Column(
              children: [
                showcamera
                    ? Expanded(
                        flex: 3,
                        child: Container(
                          width: double.infinity, // custom wrap size
                          height: 250,
                          child: ScanView(
                            controller: scanController,
                            scanAreaScale: 0.9,
                            scanLineColor: Colors.green.shade400,
                            onCapture: (data) {
                              try {
                                var Fireitrm = ItemList.singleWhere(
                                    (e) => e['itemId'] == data);

                                if (!Fireitrm['ischeck']) {
                                  showDialog<String>(
                                    context: context,
                                    builder: (BuildContext context) =>
                                        AlertDialog(
                                      title: Text(data),
                                      content: Text(Fireitrm['itemName']),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(
                                              context,
                                            );

                                            scanController.resume();
                                          },
                                          child: const Text('取消'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            setState(() {
                                              Fireitrm['ischeck'] = true;
                                            });
                                            Navigator.pop(
                                              context,
                                            );
                                            scanController.resume();
                                          },
                                          child: const Text('確定'),
                                        ),
                                      ],
                                    ),
                                  );
                                } else {
                                  showDialog<String>(
                                    context: context,
                                    builder: (BuildContext context) =>
                                        AlertDialog(
                                      title: Text(data),
                                      content: const Text('此物品已經勾選'),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(
                                              context,
                                            );
                                            scanController.resume();
                                          },
                                          child: const Text('確定'),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              } on Error catch (e) {
                                showDialog<String>(
                                  context: context,
                                  builder: (BuildContext context) =>
                                      AlertDialog(
                                    title: Text(data),
                                    content: Text('查無此id 請確認地點區域是否選擇正確'),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(
                                            context,
                                          );
                                          scanController.resume();
                                        },
                                        child: const Text('確定'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      )
                    : Container(),
                Expanded(
                    flex: 7,
                    child: Ddefaultshow
                        ? ListView.builder(
                            itemCount: ItemList.length,
                            itemBuilder: (context, index) {
                              var Fireitem = ItemList[index];
                              return ListTile(
                                leading: Checkbox(
                                  checkColor: Colors.white,
                                  value: Fireitem['ischeck'],
                                  onChanged: (bool value) {
                                    setState(() {
                                      Fireitem['ischeck'] = value;
                                    });
                                  },
                                ),
                                title: Text(Fireitem['itemId'] +
                                    ' ' +
                                    Fireitem['itemName']),
                                subtitle: Text('當前狀態:' +
                                    status[Fireitem['presentStasus']]),
                                onTap: () => {
                                  setState(() {
                                    Fireitem['ischeck'] = !Fireitem['ischeck'];
                                  })
                                },
                              );
                            })
                        : Row(
                            children: [
                              Expanded(
                                  flex: 1,
                                  child: Column(children: [
                                    Container(
                                      color: Colors.lightGreenAccent,
                                      child: Center(child: Text('未盤點')),
                                      width: double.infinity,
                                    ),
                                    Expanded(
                                      child: ListView.builder(
                                          itemCount: ItemList.where(
                                              (e) => !e['ischeck']).length,
                                          itemBuilder: (context, index) {
                                            var notchecklist = ItemList.where(
                                                (e) => !e['ischeck']).toList();
                                            var Fireitem = notchecklist[index];
                                            return ListTile(
                                              // leading: Checkbox(
                                              //   checkColor: Colors.white,
                                              //   value: Fireitem['ischeck'],
                                              //   onChanged: (bool value) {
                                              //     setState(() {
                                              //       Fireitem['ischeck'] = value;
                                              //     });
                                              //   },
                                              // ),
                                              title: Text(Fireitem['itemId'] +
                                                  ' ' +
                                                  Fireitem['itemName']),
                                              subtitle: Text('當前狀態:' +
                                                  status[Fireitem[
                                                      'presentStasus']]),
                                              onTap: () => {
                                                setState(() {
                                                  Fireitem['ischeck'] =
                                                      !Fireitem['ischeck'];
                                                })
                                              },
                                            );
                                          }),
                                    ),
                                  ])),
                              VerticalDivider(
                                thickness: 1,
                              ),
                              Expanded(
                                  flex: 1,
                                  child: Column(
                                    children: [
                                      Container(
                                        color: Colors.red,
                                        child: Center(child: Text('已盤點')),
                                        width: double.infinity,
                                      ),
                                      Expanded(
                                        child: ListView.builder(
                                            itemCount: ItemList.where(
                                                (e) => e['ischeck']).length,
                                            itemBuilder: (context, index) {
                                              var checklist = ItemList.where(
                                                  (e) => e['ischeck']).toList();
                                              var Fireitem = checklist[index];
                                              return ListTile(
                                                // leading: Checkbox(
                                                //   checkColor: Colors.white,
                                                //   value: Fireitem['ischeck'],
                                                //   onChanged: (bool value) {
                                                //     setState(() {
                                                //       Fireitem['ischeck'] = value;
                                                //     });
                                                //   },
                                                // ),
                                                title: Text(Fireitem['itemId'] +
                                                    ' ' +
                                                    Fireitem['itemName']),
                                                subtitle: Text('當前狀態:' +
                                                    status[Fireitem[
                                                        'presentStasus']]),
                                                onTap: () => {
                                                  setState(() {
                                                    Fireitem['ischeck'] =
                                                        !Fireitem['ischeck'];
                                                  })
                                                },
                                              );
                                            }),
                                      )
                                    ],
                                  ))
                            ],
                          ))
              ],
            ),
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
                              '(${e['fireitemList'].where((x) => x['ischeck'] == true).length}/${e['fireitemList'].length})'))
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
