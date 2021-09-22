import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:identityflutter/GlobalVariable.dart' as GV;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:scan/scan.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:fluttertoast/fluttertoast.dart';

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

  List<dynamic> PlaceList;
  List<dynamic> AreaList;
  List<dynamic> ItemList;
  int Areaindex = 0;
  int Placeindex = 0;
  var Presentstatus = ['正常', '報修', '借出', '停用'];
  var AfterInventory = ['未知', '與盤點前無異'];
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
                                          Areaindex = 0;
                                          tabController.animateTo(0);
                                        });

                                        Navigator.pop(context);
                                      },
                                      title:
                                          Text(PlaceList[index]['placeName']),
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
                                        if (e['presentStasus'] == 0) {
                                          e['inventoryStatus'] = 0;
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
                      onTap: () {
                        List<dynamic> InventoryItemList = [];
                        ItemList.forEach((e) {
                          InventoryItemList.add({
                            'ItemId': e['itemId'],
                            'StasusBefore': e['presentStasus'],
                            'StasusAfter': e['inventoryStatus']
                          });
                        });
                        print(jsonEncode(InventoryItemList));
                      },
                      child: ListTile(
                        leading: Icon(Icons.cloud_upload),
                        title:
                            Text('送出${PlaceList[Placeindex]['placeName']}盤點'),
                      ),
                    ),
                    PopupMenuDivider(),
                    PopupMenuItem(
                      onTap: () => setState(() {
                        Ddefaultshow = !Ddefaultshow;
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
                              var Fireitrm;
                              bool showcancel = false;
                              bool isnormal = false;
                              String itemId = '';
                              String hintmessage = '';

                              try {
                                Fireitrm = ItemList.singleWhere(
                                    (e) => e['itemId'] == data);
                                itemId = Fireitrm['itemId'];
                                if (Fireitrm['presentStasus'] == 0) {
                                  if (Fireitrm['inventoryStatus'] == 0) {
                                    showcancel = true;
                                    isnormal = true;
                                    hintmessage = Fireitrm['itemName'];
                                  } else {
                                    hintmessage = '此設備已勾選';
                                  }
                                } else {
                                  hintmessage = '借出/報修中，無法盤點';
                                }
                              } on Error catch (e) {
                                hintmessage = '查無此設備，請確認地點區域是否正確';
                              } finally {
                                showDialog<String>(
                                  context: context,
                                  builder: (BuildContext context) =>
                                      AlertDialog(
                                    title: Text(itemId),
                                    content: Text(hintmessage),
                                    actions: <Widget>[
                                      Visibility(
                                      visible:showcancel,
                                          child: TextButton(
                                        onPressed: () {
                                          Navigator.pop(
                                            context,
                                          );

                                          scanController.resume();
                                        },
                                        child: Text('取消'),
                                      )),
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            if (isnormal) {
                                              Fireitrm['inventoryStatus'] = 1;
                                            }
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
                              return Card(
                                  child: ListTile(
                                leading: Checkbox(
                                  onChanged: (bool val) {},
                                  checkColor: Colors.white,
                                  activeColor: Fireitem['presentStasus'] != 0
                                      ? Colors.grey
                                      : Colors.blue,
                                  value: Fireitem['inventoryStatus'] != 0,
                                ),
                                title: Text(Fireitem['itemId'] +
                                    ' ' +
                                    Fireitem['itemName']),
                                subtitle: Text('盤點前:' +
                                    Presentstatus[Fireitem['presentStasus']] +
                                    '\n' +
                                    '盤點後:' +
                                    AfterInventory[
                                        Fireitem['inventoryStatus']]),
                                onTap: () => {
                                  if (Fireitem['presentStasus'] == 0)
                                    {
                                      setState(() {
                                        if (Fireitem['inventoryStatus'] == 1) {
                                          Fireitem['inventoryStatus'] = 0;
                                        } else if (Fireitem[
                                                'inventoryStatus'] ==
                                            0) {
                                          Fireitem['inventoryStatus'] = 1;
                                        }
                                      })
                                    }
                                  else
                                    {
                                      Fluttertoast.showToast(
                                          msg: '借出/報修中，無法盤點',
                                          toastLength: Toast.LENGTH_SHORT,
                                          gravity: ToastGravity.CENTER,
                                          timeInSecForIosWeb: 1,
                                          backgroundColor: Colors.red,
                                          textColor: Colors.white,
                                          fontSize: 16.0)
                                    }
                                },
                              ));
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
                                          itemCount: ItemList.where((e) =>
                                              e['inventoryStatus'] == 0).length,
                                          itemBuilder: (context, index) {
                                            var notchecklist = ItemList.where(
                                                (e) =>
                                                    e['inventoryStatus'] ==
                                                    0).toList();
                                            var Fireitem = notchecklist[index];
                                            return Card(
                                              child: ListTile(
                                                title: Text(Fireitem['itemId'] +
                                                    ' ' +
                                                    Fireitem['itemName']),
                                                subtitle: Text('盤點前:' +
                                                    Presentstatus[Fireitem[
                                                        'presentStasus']] +
                                                    '\n' +
                                                    '盤點後:' +
                                                    AfterInventory[Fireitem[
                                                        'inventoryStatus']]),
                                                onTap: () => {
                                                  setState(() {
                                                    Fireitem[
                                                        'inventoryStatus'] = 1;
                                                  })
                                                },
                                              ),
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
                                            itemCount: ItemList.where((e) =>
                                                    e['inventoryStatus'] != 0)
                                                .length,
                                            itemBuilder: (context, index) {
                                              var checklist = ItemList.where(
                                                  (e) =>
                                                      e['inventoryStatus'] !=
                                                      0).toList();
                                              var Fireitem = checklist[index];

                                              return Card(
                                                child: ListTile(
                                                  title: Text(
                                                      Fireitem['itemId'] +
                                                          ' ' +
                                                          Fireitem['itemName']),
                                                  subtitle: Text('盤點前:' +
                                                      Presentstatus[Fireitem[
                                                          'presentStasus']] +
                                                      '\n' +
                                                      '盤點後:' +
                                                      AfterInventory[Fireitem[
                                                          'inventoryStatus']]),
                                                  onTap: () => {
                                                    setState(() {
                                                      Fireitem[
                                                          'inventoryStatus'] = 0;
                                                    })
                                                  },
                                                ),
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
                              '(${e['fireitemList'].where((x) => x['inventoryStatus'] != 0).length}/${e['fireitemList'].length})'))
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
