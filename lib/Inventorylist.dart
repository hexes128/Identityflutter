import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:identityflutter/GlobalVariable.dart' as GV;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class InventoryList extends StatefulWidget {
  InventoryList({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => InventoryListState();
}

class InventoryListState extends State<InventoryList>
    with TickerProviderStateMixin {
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
    PlaceList = _callApi();
    tabController = TabController(length: 0, vsync: this);
  }

  Future<List<dynamic>> PlaceList;
  bool allChecked = false;
  List<dynamic> AreaList;
  int Areaindex = 0;
  int Placeindex = 0;
  var status = ['正常', '借出', '報修', '停用'];
  TabController tabController;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: PlaceList,
      builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.hasData) {
          AreaList = snapshot.data[Placeindex]['priorityList'];
          AreaList.sort((a, b) => a['priorityNum'].compareTo(b['priorityNum']));
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
              title: Text(snapshot.data[Placeindex]['placeName'] +
                  '(' +
                  AreaList[Areaindex]['subArea'] +
                  ')'),
              actions: [
                PopupMenuButton(
                    onSelected: (int index) {
                      if (Placeindex != index) {
                        setState(() {
                          Placeindex = index;
                          tabController.animateTo(0);
                        });
                      }
                    },
                    icon: Icon(Icons.sort),
                    itemBuilder: (BuildContext context) => snapshot.data
                        .map((e) => PopupMenuItem(
                              child: Text(e['placeName']),
                              value: snapshot.data.indexOf(e),
                            ))
                        .toList()),
                PopupMenuButton(
                  onSelected: (int index) {
                    if (Placeindex != index) {
                      setState(() {
                        Placeindex = index;
                        tabController.animateTo(0, curve: Curves.bounceIn);
                      });
                    }
                  },
                  icon: Icon(Icons.camera_alt),
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem(
                      value: 0,
                      child: Text('ON'),
                    ),
                    const PopupMenuItem(
                      value: 1,
                      child: Text('OFF'),
                    ),
                  ],
                ),
              ],
            ),
            body: ListView.builder(
                itemCount: AreaList[Areaindex]['fireitemList'].length,
                itemBuilder: (context, index) {
                  var Fireitem = AreaList[Areaindex]['fireitemList'][index];
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
                    title:
                        Text(Fireitem['itemId'] + ' ' + Fireitem['itemName']),
                    subtitle: Text('當前狀態:' + status[Fireitem['presentStasus']]),
                    onTap: () => {
                      setState(() {
                        Fireitem['ischeck'] = !Fireitem['ischeck'];
                      })
                    },
                  );
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


