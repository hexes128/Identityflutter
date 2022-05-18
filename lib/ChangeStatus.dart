import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:identityflutter/GlobalVariable.dart' as GV;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_switch/flutter_switch.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:future_progress_dialog/future_progress_dialog.dart';

class ChangeStatus extends StatefulWidget {
  ChangeStatus({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => ChangeStatusState();
}

class ChangeStatusState extends State<ChangeStatus>
    with TickerProviderStateMixin , WidgetsBindingObserver  {


  Future<List<dynamic>?> _callApi() async {
    var access_token =GV.info!['accessToken'];

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
    WidgetsBinding.instance!.addObserver(this);
  }
  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if(state.index==0){
      if(     DateTime.parse(GV.info!['accessTokenExpirationDateTime']!).difference(DateTime.now()).inSeconds<GV.settimeout){
        GV.timeout=true;
        Navigator.of(context).popUntil((route) =>route.isFirst
        );
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

  Future<bool> _onWillPop() async {
    return (await showDialog(
          context: context,
          builder: (context) => new AlertDialog(
            title: new Text('退出'),
            content: new Text('狀態將會清空，確定是否退出?'),
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
        ) ) ??
        false;
  }

  Future<String?> sendInventory(List<dynamic> iteminfo) async {
    var access_token =GV.info!['accessToken'];

    try {
      var response = await http.post(
          Uri(
              scheme: 'http',
              host: '140.133.78.140',
              port: 81,
              path: 'Item/ChangeStatus'),
          headers: {
            "Authorization": "Bearer $access_token",
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(iteminfo));

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
                  title: CupertinoPicker(
                    children: PlaceList!.map(
                        (e) => Center(child: Text(e['placeName']))).toList(),
                    itemExtent: 50,
                    onSelectedItemChanged: (int index) {
                      setState(() {
                        Placeindex = index;
                      });
                    },
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(Icons.cloud_upload),
                      onPressed: () {
                        if (PlaceList![Placeindex]['todaysend']) {
                          Fluttertoast.showToast(
                              msg: PlaceList![Placeindex]['placeName'] +
                                  '請退出後重新進入',
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


                        List<dynamic> infoList = groupItemList.where((e) => e['inventoryStatus'] != 5).toList();
                        if (infoList.length != 0) {

print(GV.info!['name']);

                          List<dynamic> sendItemList = infoList.map((e) => {
                                    'ItemId': e['itemId'],
                                    'Beforechange': e['presentStatus'],
                                    'StatusCode': e['inventoryStatus'],
                                    'PlaceId': PlaceList![Placeindex]['placeId'],
                                    'UserName': GV.info!['name']
                                  }).toList();


                          showDialog<String>(
                            context: context,
                            builder: (BuildContext context) => AlertDialog(
                              title: Text(PlaceList![Placeindex]['placeName']),
                              content: Container(
                                  width: double.maxFinite,
                                  child: ListView.builder(
                                      itemCount: infoList.length,
                                      shrinkWrap: true,
                                      itemBuilder:
                                          (BuildContext context, int index) {
                                        return Card(
                                          child: ListTile(
                                            title: Text(infoList[index]['itemId']+'\n'+infoList[index]['itemName']),
                                            subtitle: Text('更動前:'+ItemStatus[infoList[index]['presentStatus']] +'\n更動後:'+ItemStatus[infoList[index]['inventoryStatus']] ),
                                          ),
                                        );
                                      })),
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
                                                    msg: '成功新增' + (value==null?'':value) + '筆紀錄',
                                                    toastLength:
                                                        Toast.LENGTH_SHORT,
                                                    gravity:
                                                        ToastGravity.CENTER,
                                                    timeInSecForIosWeb: 1,
                                                    backgroundColor: Colors.red,
                                                    textColor: Colors.white,
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
                              msg: '未更動任何器材',
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.CENTER,
                              timeInSecForIosWeb: 1,
                              backgroundColor: Colors.red,
                              textColor: Colors.white,
                              fontSize: 16.0);
                        }
                      },
                    ),
                  ],
                ),
                body: Row(
                  children: [
                    Expanded(
                        flex: 1,
                        child: Column(children: [
                          Container(
                            color: Colors.red,
                            child: Center(child: Text('更動前')),
                            width: double.infinity,
                          ),
                          Expanded(
                            child: ListView.builder(
                                itemCount: ItemList!.where(
                                    (e) => e['inventoryStatus'] == 5).length,
                                itemBuilder: (context, index) {
                                  var notchecklist = ItemList!.where(
                                          (e) => e['inventoryStatus'] == 5)
                                      .toList();
                                  var Fireitem = notchecklist[index];
                                  return Card(
                                    child: ListTile(
                                      title: Text(Fireitem['itemId'] +
                                          ' ' +
                                          Fireitem['itemName']),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '更動前:' +
                                                ItemStatus[
                                                    Fireitem['presentStatus']],
                                            style: TextStyle(
                                                color:
                                                    Fireitem['presentStatus'] ==
                                                            0
                                                        ? Colors.grey
                                                        : Colors.red),
                                          ),
                                        ],
                                      ),
                                      onTap: () {
                                        showDialog<void>(
                                          context: context,
                                          barrierDismissible: false,
                                          // user must tap button!
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                                title: Text(Fireitem['itemId'] +
                                                    ' ' +
                                                    Fireitem['itemName']),
                                                content: SizedBox(
                                                    width: double.maxFinite,
                                                    child: ListView.builder(
                                                        shrinkWrap: true,
                                                        itemCount:
                                                            ItemStatus.length,
                                                        itemBuilder:
                                                            (context, index) {
                                                          return index < 5
                                                              ? Card(
                                                                  child:
                                                                      ListTile(
                                                                    enabled: index ==
                                                                                0 &&
                                                                            Fireitem['presentStatus'] !=
                                                                                0 ||
                                                                        index !=
                                                                                0 &&
                                                                            Fireitem['presentStatus'] ==
                                                                                0,
                                                                    title: Text(
                                                                        ItemStatus[
                                                                            index]),
                                                                    onTap: () {
                                                                      setState(
                                                                          () {
                                                                        Fireitem['inventoryStatus'] =
                                                                            index;
                                                                      });
                                                                      Navigator.pop(
                                                                          context);
                                                                    },
                                                                  ),
                                                                )
                                                              : Container();
                                                        })));
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
                              child: Center(child: Text('更動後')),
                              width: double.infinity,
                            ),
                            Expanded(
                              child: ListView.builder(
                                  itemCount: ItemList!.where(
                                      (e) => e['inventoryStatus'] != 5).length,
                                  itemBuilder: (context, index) {
                                    var checklist = ItemList!.where(
                                            (e) => e['inventoryStatus'] != 5)
                                        .toList();
                                    var Fireitem = checklist[index];

                                    return Card(
                                      child: ListTile(
                                        title: Text(Fireitem['itemId'] +
                                            ' ' +
                                            Fireitem['itemName']),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '更動前:' +
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
                                              '更動後:' +
                                                  (ItemStatus[Fireitem[
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
                                            Fireitem['inventoryStatus'] = 5;
                                          });
                                        },
                                      ),
                                    );
                                  }),
                            )
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
                                  '(${e['fireitemList'].where((x) => x['inventoryStatus'] != 5).length})'))
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
