import 'dart:async';
import 'dart:convert';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/cupertino.dart';
import 'package:flutter_blue/flutter_blue.dart';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:identityflutter/GlobalVariable.dart' as GV;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:identityflutter/scanpage.dart';
import 'package:scan/scan.dart';
import 'package:flutter_switch/flutter_switch.dart';

import 'package:future_progress_dialog/future_progress_dialog.dart';

class InventoryList extends StatefulWidget {
  InventoryList({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => InventoryListState();
}

class InventoryListState extends State<InventoryList>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  ScanController scanController = ScanController();

  Future<List<dynamic>?> _callApi() async {
    var access_token = GV.info!['accessToken'];

    try {
      var response = await http.get(
          Uri(
              scheme: 'http',
              host: '140.133.78.140',
              port: 81,
              path: 'Item/GetItem'),
          headers: {"Authorization": "Bearer $access_token"});
      if (response.statusCode == 200) {
        var a = response.body;
        return jsonDecode(response.body);
      } else {
        print('${response.statusCode}');
      }
    } on Error catch (e) {
      throw Exception('123');
    }
  }

  @override
  void initState() {
    super.initState();
    futureList = _callApi();
    tabController = TabController(length: 0, vsync: this);
    WidgetsBinding.instance!.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    SubscriptionList.forEach((element) {
      element.cancel();
    });
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state.index == 0) {
      if (DateTime.parse(GV.info!['accessTokenExpirationDateTime']!)
              .difference(DateTime.now())
              .inSeconds <
          GV.settimeout) {
        GV.timeout = true;
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  Future<List<dynamic>?>? futureList;

  List<dynamic>? PlaceList;
  List<dynamic>? AreaList;
  List<dynamic>? ItemList;
  int Areaindex = 0;
  int Placeindex = 0;
  var ItemStatus = ['正常', '借出', '報修', '遺失', '停用', '尚未盤點'];

  TabController? tabController;
  // bool showcamera = false;
  bool Ddefaultshow = true;
  List<BluetoothCharacteristic> CharacteristicList = [];
  List<StreamSubscription> SubscriptionList = [];

  Future<bool> _onWillPop() async {
    return (await (showDialog(
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
        ) as FutureOr<bool>?)) ??
        false;
  }

  Future<String> sendInventory(List<dynamic> iteminfo) async {
    var access_token = GV.info!['accessToken'];

    try {
      var response = await http.post(
          Uri(
              scheme: 'http',
              host: '140.133.78.140',
              port: 81,
              path: 'Item/Inventory'),
          headers: {
            "Authorization": "Bearer $access_token",
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, dynamic>{
            'UserName': GV.info!['name'],
            'PlaceId': PlaceList![Placeindex]['placeId'],
            'InventoryItemList': iteminfo
          }));
var a =jsonEncode(<String, dynamic>{
  'UserName': GV.info!['name'],
  'PlaceId': PlaceList![Placeindex]['placeId'],
  'InventoryItemList': iteminfo
});
var b=0;
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

  Future<void> discoverservice(BluetoothDevice device) async {
    try {
      await device.discoverServices();
    } catch (e) {}
  }

  Future<void> setnotify(BluetoothCharacteristic characteristic) async {
    if (!characteristic.isNotifying) {
      try {
        await characteristic.setNotifyValue(true);
        late String devicename;

        if (!CharacteristicList.map((e) => e.deviceId)
            .contains(characteristic.deviceId)) {
          StreamSubscription subscription =
              characteristic.value.listen((event) {
            String id='';
            print(event);
            AreaList!.forEach((element) {
              try {
                id = latin1.decode(event).toString().trim();

                List<dynamic> itemlist = element['fireitemList'];
                var Fireitem = itemlist.singleWhere((e) => e['itemId'] == id,
                    orElse: () => null);
                if (Fireitem != null) {
                  print(Fireitem['itemName']);
                  if (Fireitem['presentStatus'] == 0) {
                    if (Fireitem['inventoryStatus'] == 5) {
                      FlutterBlue.instance.connectedDevices.then((value) {
                        BluetoothDevice? device = value.singleWhereOrNull(
                            (x) => x.id == characteristic.deviceId);
                        if(device!=null){
                          devicename=device.name;
                        }
                        Fluttertoast.showToast(
                            msg: devicename+'\n'+Fireitem['itemId']+'('+Fireitem['itemName']+')'+'\n'+element['subArea'],
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.CENTER,
                            timeInSecForIosWeb: 1,
                            backgroundColor: Colors.red,
                            textColor: Colors.white,
                            fontSize: 16.0);
                        setState(() {
                          Fireitem['inventoryStatus'] = 0;
                        });
                      });

                    }
                  }
                }
              } catch (e) {
                print(e);
              }
            });
          });
          CharacteristicList.add(characteristic);
          SubscriptionList.add(subscription);
        }
      } catch (e) {}
    }
  }

  processBLEdata(String id) {}

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        child: FutureBuilder<List<dynamic>?>(
          future: futureList,
          builder:
              (BuildContext context, AsyncSnapshot<List<dynamic>?> snapshot) {
            if (snapshot.hasData) {
              PlaceList = snapshot.data;
              AreaList = PlaceList![Placeindex]['priorityList'];
              AreaList!.sort(
                  (a, b) => a['priorityNum'].compareTo(b['priorityNum']));
              ItemList = AreaList![Areaindex]['fireitemList'];

              tabController = TabController(
                  length: AreaList!.length,
                  vsync: this,
                  initialIndex: Areaindex);
              tabController!.addListener(() {
                if (tabController!.indexIsChanging) {
                  setState(() {
                    Areaindex = tabController!.index;
                  });
                }
              });
              return Scaffold(
                appBar: AppBar(
                  title: Row(
                    children: [
                      Expanded(
                        child: CupertinoPicker(
                          children: PlaceList!.map(
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
                        child: Text(AreaList![Areaindex]['subArea']),
                      )
                    ],
                  ),
                  actions: [
                    IconButton(
                        onPressed: () {
                          Navigator.push(
                            //從登入push到第二個
                            context,
                            new MaterialPageRoute(
                                builder: (context) => scanpage()),
                          ).then((value) {
                            setState(() {});
                          });
                        },
                        icon: Icon(Icons.bluetooth)),
                    // FlutterSwitch(
                    //   width: 60.0,
                    //   height: 30.0,
                    //   toggleSize: 20.0,
                    //   value: showcamera,
                    //   borderRadius: 30.0,
                    //   padding: 2.0,
                    //   toggleColor: Colors.black,
                    //   activeColor: Colors.red,
                    //   showOnOff: true,
                    //   activeIcon: Icon(
                    //     Icons.camera_alt,
                    //   ),
                    //   inactiveIcon: Icon(
                    //     Icons.camera_alt,
                    //     color: Color(0xFFFFDF5D),
                    //   ),
                    //   onToggle: (val) {
                    //     setState(() {
                    //       showcamera = val;
                    //     });
                    //   },
                    // ),
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
                                  title: Text(
                                      '${PlaceList![Placeindex]['placeName']} ${AreaList![Areaindex]['subArea']}'),
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
                                          ItemList!.forEach((e) {
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
                              if (PlaceList![Placeindex]['todaysend']) {
                                Fluttertoast.showToast(
                                    msg: PlaceList![Placeindex]['placeName'] +
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
                                  AreaList!.map((e) => e['fireitemList'])
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
                                        PlaceList![Placeindex]['placeName']),
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
                                                      PlaceList![Placeindex]
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
                                '送出${PlaceList![Placeindex]['placeName']}盤點'),
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
                    StreamBuilder<List<BluetoothDevice>>(
                            stream: Stream.periodic(const Duration(seconds: 1))
                                .asyncMap((_) => FlutterBlue.instance.connectedDevices),
                            initialData: [],
                            builder: (c, snapshot) {
                              return Column(
                                children: snapshot.data!.map((d) {
                                  return ListTile(
                                    title: Text(d.name),
                                    subtitle: Text(d.id.toString()),
                                    trailing:
                                        StreamBuilder<BluetoothDeviceState>(
                                      stream: d.state,
                                      initialData:
                                          BluetoothDeviceState.disconnected,
                                      builder: (c, snapshot) {
                                        if (snapshot.data ==
                                            BluetoothDeviceState.connected) {
                                          return StreamBuilder<
                                              List<BluetoothService>>(
                                            stream: d.services,
                                            initialData: [],
                                            builder: (c, snapshot) {
                                              if (snapshot.hasData &&
                                                  snapshot.data!.isNotEmpty) {
                                                BluetoothService service = snapshot
                                                    .data!
                                                    .singleWhere((e) =>
                                                        e.uuid.toString() ==
                                                        '0000ffe0-0000-1000-8000-00805f9b34fb');

                                                BluetoothCharacteristic chara =
                                                    service.characteristics
                                                        .singleWhere((e) =>
                                                            e.uuid.toString() ==
                                                            '0000ffe1-0000-1000-8000-00805f9b34fb');
                                                setnotify(chara);

                                                return RaisedButton(
                                                  child: const Text('中斷連線'),
                                                  onPressed: () async {
                                                    await d.disconnect();
                                                  },
                                                );
                                              }
                                              discoverservice(d);
                                              return const IconButton(
                                                icon: SizedBox(
                                                  child:
                                                      CircularProgressIndicator(
                                                    valueColor:
                                                        AlwaysStoppedAnimation(
                                                            Colors.grey),
                                                  ),
                                                  width: 18.0,
                                                  height: 18.0,
                                                ),
                                                onPressed: null,
                                              );
                                            },
                                          );
                                        } else {
                                          return RaisedButton(
                                            child: const Text('重新連線'),
                                            onPressed: () async {
                                              await d
                                                  .connect(
                                                      timeout: const Duration(
                                                          seconds: 5),
                                                      autoConnect: false)
                                                  .then((value) =>
                                                      setState(() {}));
                                            },
                                          );
                                        }
                                      },
                                    ),
                                  );
                                }).toList(),
                              );
                            }),
                    // showcamera
                    //     ? Expanded(
                    //         flex: 3,
                    //         child: Container(
                    //           width: double.infinity, // custom wrap size
                    //           height: 250,
                    //           child: ScanView(
                    //             controller: scanController,
                    //             scanAreaScale: 0.9,
                    //             scanLineColor: Colors.green.shade400,
                    //             onCapture: (data) {
                    //               var Fireitrm;
                    //               bool showcancel = false;
                    //               bool isnormal = false;
                    //               String itemId = '';
                    //               String hintmessage = '';
                    //
                    //               try {
                    //                 Fireitrm = ItemList.singleWhere(
                    //                     (e) => e['itemId'] == data);
                    //                 itemId = Fireitrm['itemId'];
                    //                 if (Fireitrm['presentStatus'] == 0) {
                    //                   if (Fireitrm['inventoryStatus'] == 0) {
                    //                     showcancel = true;
                    //                     isnormal = true;
                    //                     hintmessage = Fireitrm['itemName'];
                    //                   } else {
                    //                     hintmessage = '此設備已勾選';
                    //                   }
                    //                 } else {
                    //                   hintmessage = '借出/報修中，無法盤點';
                    //                 }
                    //               } on Error catch (e) {
                    //                 hintmessage = '查無此設備，請確認地點區域是否正確';
                    //               } finally {
                    //                 showDialog<String>(
                    //                   context: context,
                    //                   builder: (BuildContext context) =>
                    //                       AlertDialog(
                    //                     title: Text(itemId),
                    //                     content: Text(hintmessage),
                    //                     actions: <Widget>[
                    //                       Visibility(
                    //                           visible: showcancel,
                    //                           child: TextButton(
                    //                             onPressed: () {
                    //                               Navigator.pop(
                    //                                 context,
                    //                               );
                    //
                    //                               scanController.resume();
                    //                             },
                    //                             child: Text('取消'),
                    //                           )),
                    //                       TextButton(
                    //                         onPressed: () {
                    //                           setState(() {
                    //                             if (isnormal) {
                    //                               Fireitrm['inventoryStatus'] =
                    //                                   1;
                    //                             }
                    //                           });
                    //                           Navigator.pop(
                    //                             context,
                    //                           );
                    //                           scanController.resume();
                    //                         },
                    //                         child: const Text('確定'),
                    //                       ),
                    //                     ],
                    //                   ),
                    //                 );
                    //               }
                    //             },
                    //           ),
                    //         ),
                    //       )
                    //     :

                    Expanded(
                        flex: 7,
                        child: Ddefaultshow
                            ? ListView.builder(
                                itemCount: ItemList!.length,
                                itemBuilder: (context, index) {
                                  var Fireitem = ItemList![index];
                                  if (Fireitem['presentStatus'] != 0) {
                                    Fireitem['inventoryStatus'] =
                                        Fireitem['presentStatus'];
                                  }

                                  return Card(
                                      child: ListTile(
                                    leading: Checkbox(
                                      onChanged: (bool? val) {},
                                      checkColor: Colors.white,
                                      activeColor:
                                          Fireitem['presentStatus'] != 0
                                              ? Colors.grey
                                              : Colors.blue,
                                      value: Fireitem['inventoryStatus'] != 5,
                                    ),
                                    title: Text(Fireitem['itemId'] +
                                        ' ' +
                                        Fireitem['itemName']),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '盤點前:' +
                                              ItemStatus[
                                                  Fireitem['presentStatus']],
                                          style: TextStyle(
                                              color:
                                                  Fireitem['presentStatus'] == 0
                                                      ? Colors.grey
                                                      : Colors.red),
                                        ),
                                        Text(
                                          '盤點後:' +
                                              (Fireitem['inventoryStatus'] ==
                                                      Fireitem['presentStatus']
                                                  ? '狀態無異'
                                                  : ItemStatus[Fireitem[
                                                      'inventoryStatus']]),
                                          style: TextStyle(
                                              color: Fireitem['inventoryStatus'] ==
                                                          0 ||
                                                      Fireitem[
                                                              'inventoryStatus'] ==
                                                          5
                                                  ? Colors.grey
                                                  : Colors.red),
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      if (Fireitem['presentStatus'] != 0) {
                                        Fluttertoast.showToast(
                                            msg: '設備異常 無法勾選',
                                            toastLength: Toast.LENGTH_SHORT,
                                            gravity: ToastGravity.CENTER,
                                            timeInSecForIosWeb: 1,
                                            backgroundColor: Colors.red,
                                            textColor: Colors.white,
                                            fontSize: 16.0);
                                        return;
                                      }

                                      setState(() {
                                        switch (Fireitem['inventoryStatus']) {
                                          case (0):
                                            {
                                              Fireitem['inventoryStatus'] = 5;
                                              break;
                                            }
                                          case (5):
                                            {
                                              Fireitem['inventoryStatus'] = 0;
                                              break;
                                            }
                                        }
                                      });
                                    },
                                    onLongPress: Fireitem['presentStatus'] == 0
                                        ? () {
                                            showDialog<void>(
                                              context: context,
                                              barrierDismissible: false,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: Text(
                                                      Fireitem['itemId'] +
                                                          ' ' +
                                                          Fireitem['itemName']),
                                                  content:
                                                      SingleChildScrollView(
                                                    child: ListBody(
                                                      children: <Widget>[
                                                        Text(Fireitem[
                                                                    'postscript'] ==
                                                                null
                                                            ? '無'
                                                            : Fireitem[
                                                                'postscript']),
                                                      ],
                                                    ),
                                                  ),
                                                  actions: Fireitem[
                                                              'inventoryStatus'] ==
                                                          5
                                                      ? [
                                                          TextButton(
                                                              onPressed: () {
                                                                Navigator.pop(
                                                                    context);
                                                              },
                                                              child:
                                                                  Text('確定')),
                                                          TextButton(
                                                              onPressed: () {
                                                                setState(() {
                                                                  Fireitem[
                                                                      'inventoryStatus'] = 2;
                                                                  Navigator.pop(
                                                                      context);
                                                                });
                                                              },
                                                              child:
                                                                  Text('報修')),
                                                          TextButton(
                                                              onPressed: () {
                                                                setState(() {
                                                                  Fireitem[
                                                                      'inventoryStatus'] = 3;
                                                                  Navigator.pop(
                                                                      context);
                                                                });
                                                              },
                                                              child: Text('遺失'))
                                                        ]
                                                      : [
                                                          TextButton(
                                                              onPressed: () {
                                                                Navigator.pop(
                                                                    context);
                                                              },
                                                              child:
                                                                  Text('確定')),
                                                          TextButton(
                                                              onPressed: () {
                                                                setState(() {
                                                                  Fireitem[
                                                                      'inventoryStatus'] = 5;
                                                                  Navigator.pop(
                                                                      context);
                                                                });
                                                              },
                                                              child: Text('復原'))
                                                        ],
                                                );
                                              },
                                            );
                                          }
                                        : null,
                                  ));
                                })
                            : Row(
                                children: [
                                  Expanded(
                                      flex: 1,
                                      child: Column(children: [
                                        Container(
                                          color: Colors.red,
                                          child: Center(child: Text('未盤點')),
                                          width: double.infinity,
                                        ),
                                        Expanded(
                                          child: ListView.builder(
                                              itemCount: ItemList!.where((e) =>
                                                  e['inventoryStatus'] == 5 &&
                                                  e['presentStatus'] ==
                                                      0).length,
                                              itemBuilder: (context, index) {
                                                var notchecklist =
                                                    ItemList!.where((e) =>
                                                        e['inventoryStatus'] ==
                                                            5 &&
                                                        e['presentStatus'] ==
                                                            0).toList();
                                                var Fireitem =
                                                    notchecklist[index];
                                                return Card(
                                                  child: ListTile(
                                                    title: Text(Fireitem[
                                                            'itemId'] +
                                                        ' ' +
                                                        Fireitem['itemName']),
                                                    subtitle: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          '盤點前:' +
                                                              ItemStatus[Fireitem[
                                                                  'presentStatus']],
                                                          style: TextStyle(
                                                              color: Fireitem[
                                                                          'presentStatus'] ==
                                                                      0
                                                                  ? Colors.grey
                                                                  : Colors.red),
                                                        ),
                                                        Text(
                                                          '盤點後:' +
                                                              (Fireitem['inventoryStatus'] ==
                                                                      Fireitem[
                                                                          'presentStatus']
                                                                  ? '狀態無異'
                                                                  : ItemStatus[
                                                                      Fireitem[
                                                                          'inventoryStatus']]),
                                                          style: TextStyle(
                                                              color: Fireitem['inventoryStatus'] ==
                                                                          0 ||
                                                                      Fireitem[
                                                                              'inventoryStatus'] ==
                                                                          5
                                                                  ? Colors.grey
                                                                  : Colors.red),
                                                        ),
                                                      ],
                                                    ),
                                                    onTap: () {
                                                      setState(() {
                                                        Fireitem[
                                                            'inventoryStatus'] = 0;
                                                      });
                                                    },
                                                    onLongPress: () {
                                                      showDialog<void>(
                                                        context: context,
                                                        barrierDismissible:
                                                            false,
                                                        builder: (BuildContext
                                                            context) {
                                                          return AlertDialog(
                                                            title: Text(Fireitem[
                                                                    'itemId'] +
                                                                ' ' +
                                                                Fireitem[
                                                                    'itemName']),
                                                            content:
                                                                SingleChildScrollView(
                                                              child: ListBody(
                                                                children: <
                                                                    Widget>[
                                                                  Text(Fireitem[
                                                                              'postscript'] ==
                                                                          null
                                                                      ? '無'
                                                                      : Fireitem[
                                                                          'postscript']),
                                                                ],
                                                              ),
                                                            ),
                                                            actions: Fireitem[
                                                                        'inventoryStatus'] ==
                                                                    5
                                                                ? [
                                                                    TextButton(
                                                                        onPressed:
                                                                            () {
                                                                          Navigator.pop(
                                                                              context);
                                                                        },
                                                                        child: Text(
                                                                            '確定')),
                                                                    TextButton(
                                                                        onPressed:
                                                                            () {
                                                                          setState(
                                                                              () {
                                                                            Fireitem['inventoryStatus'] =
                                                                                2;
                                                                            Navigator.pop(context);
                                                                          });
                                                                        },
                                                                        child: Text(
                                                                            '報修')),
                                                                    TextButton(
                                                                        onPressed:
                                                                            () {
                                                                          setState(
                                                                              () {
                                                                            Fireitem['inventoryStatus'] =
                                                                                3;
                                                                            Navigator.pop(context);
                                                                          });
                                                                        },
                                                                        child: Text(
                                                                            '遺失'))
                                                                  ]
                                                                : [
                                                                    TextButton(
                                                                        onPressed:
                                                                            () {
                                                                          Navigator.pop(
                                                                              context);
                                                                        },
                                                                        child: Text(
                                                                            '確定')),
                                                                    TextButton(
                                                                        onPressed:
                                                                            () {
                                                                          setState(
                                                                              () {
                                                                            Fireitem['inventoryStatus'] =
                                                                                5;
                                                                            Navigator.pop(context);
                                                                          });
                                                                        },
                                                                        child: Text(
                                                                            '復原'))
                                                                  ],
                                                          );
                                                        },
                                                      );
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
                                            color: Colors.lightGreenAccent,
                                            child: Center(child: Text('已盤點')),
                                            width: double.infinity,
                                          ),
                                          Expanded(
                                            child: ListView.builder(
                                                itemCount: ItemList!.where((e) =>
                                                    e['presentStatus'] != 0 ||
                                                    e['inventoryStatus'] !=
                                                        5).length,
                                                itemBuilder: (context, index) {
                                                  var checklist =
                                                      ItemList!.where((e) =>
                                                          e['presentStatus'] !=
                                                              0 ||
                                                          e['inventoryStatus'] !=
                                                              5).toList();
                                                  var Fireitem =
                                                      checklist[index];
                                                  if (Fireitem[
                                                          'presentStatus'] !=
                                                      0) {
                                                    Fireitem[
                                                            'inventoryStatus'] =
                                                        Fireitem[
                                                            'presentStatus'];
                                                  }

                                                  return Card(
                                                    child: ListTile(
                                                      enabled: Fireitem[
                                                              'presentStatus'] ==
                                                          0,
                                                      title: Text(Fireitem[
                                                              'itemId'] +
                                                          ' ' +
                                                          Fireitem['itemName']),
                                                      subtitle: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            '盤點前:' +
                                                                ItemStatus[Fireitem[
                                                                    'presentStatus']],
                                                            style: TextStyle(
                                                                color: Fireitem[
                                                                            'presentStatus'] ==
                                                                        0
                                                                    ? Colors
                                                                        .grey
                                                                    : Colors
                                                                        .red),
                                                          ),
                                                          Text(
                                                            '盤點後:' +
                                                                (Fireitem['inventoryStatus'] ==
                                                                        Fireitem[
                                                                            'presentStatus']
                                                                    ? '狀態無異'
                                                                    : ItemStatus[
                                                                        Fireitem[
                                                                            'inventoryStatus']]),
                                                            style: TextStyle(
                                                                color: Fireitem['inventoryStatus'] ==
                                                                            0 ||
                                                                        Fireitem['inventoryStatus'] ==
                                                                            5
                                                                    ? Colors
                                                                        .grey
                                                                    : Colors
                                                                        .red),
                                                          ),
                                                        ],
                                                      ),
                                                      onTap: () {
                                                        setState(() {
                                                          switch (Fireitem[
                                                              'inventoryStatus']) {
                                                            case (0):
                                                              {
                                                                Fireitem[
                                                                    'inventoryStatus'] = 5;
                                                                break;
                                                              }
                                                            case (5):
                                                              {
                                                                Fireitem[
                                                                    'inventoryStatus'] = 0;
                                                                break;
                                                              }
                                                          }
                                                        });
                                                      },
                                                      onLongPress: () {
                                                        showDialog<void>(
                                                          context: context,
                                                          barrierDismissible:
                                                              false,
                                                          builder: (BuildContext
                                                              context) {
                                                            return AlertDialog(
                                                              title: Text(Fireitem[
                                                                      'itemId'] +
                                                                  ' ' +
                                                                  Fireitem[
                                                                      'itemName']),
                                                              content:
                                                                  SingleChildScrollView(
                                                                child: ListBody(
                                                                  children: <
                                                                      Widget>[
                                                                    Text(Fireitem['postscript'] ==
                                                                            null
                                                                        ? '無'
                                                                        : Fireitem[
                                                                            'postscript']),
                                                                  ],
                                                                ),
                                                              ),
                                                              actions: [
                                                                TextButton(
                                                                    onPressed:
                                                                        () {
                                                                      Navigator.pop(
                                                                          context);
                                                                    },
                                                                    child: Text(
                                                                        '確定')),
                                                                TextButton(
                                                                    onPressed:
                                                                        () {
                                                                      setState(
                                                                          () {
                                                                        Fireitem[
                                                                            'inventoryStatus'] = 5;
                                                                        Navigator.pop(
                                                                            context);
                                                                      });
                                                                    },
                                                                    child: Text(
                                                                        '復原'))
                                                              ],
                                                            );
                                                          },
                                                        );
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
                      tabs: AreaList!.map((e) => Tab(
                              text: e['subArea'] +
                                  ' ' +
                                  '(${e['fireitemList'].where((x) => x['inventoryStatus'] != 5 || x['presentStatus'] != 0).length}/${e['fireitemList'].length})'))
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
        ),
        onWillPop: _onWillPop);
  }
}
