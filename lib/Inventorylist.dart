import 'dart:async';
import 'dart:convert';
import 'package:identityflutter/GlobalVariable.dart' as GV;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class InventoryList extends StatefulWidget {
  InventoryList({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => InventoryListState();
}

class InventoryListState extends State<InventoryList> {
  List<dynamic> EquipmentLiST = [];
  List<dynamic> PlaceList = [];

  Future<List<dynamic>> _callApi(Uri uri) async {
    var access_token = GV.tokenResponse.accessToken;

    try {
      var response = await http
          .get(uri, headers: {"Authorization": "Bearer $access_token"});
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('123');
      }
    } on Error catch (e) {
      print('Error: $e');
    }
  }

  @override
  void initState() {
    super.initState();

    this
        ._callApi(Uri(
            scheme: 'http',
            host: '192.168.10.152',
            port: 81,
            path: 'Item/GetItem'))
        .then((value) => setState(() {
              EquipmentLiST = value;
            }));
  }

  bool allChecked = false;


  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 0,
      length: EquipmentLiST.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text('設備清單'),
          bottom: TabBar(
              tabs:
                  EquipmentLiST.map((e) => Tab(text: e['placeName'])).toList()),
        ),
        body: TabBarView(
            children: EquipmentLiST.map((e) => ListView.builder(
                  itemCount: (e['priorityList'] as List).length,
                  itemBuilder: (context, index) {
                    var status = ['正常', '借出', '報修', '停用'];
                    List<dynamic> AreaList = e['priorityList'];

                    AreaList.sort(
                        (a, b) => a['priorityNum'].compareTo(b['priorityNum']));
                    var Area = AreaList[index];
                    List fireitemList = Area['fireitemList'];
                    return ExpansionTile(
                        title: Text(
                            ' ${Area['subArea']}(${fireitemList.where((x) => x['ischeck'] == true).length}/${fireitemList.length})'),
                        leading:  Checkbox(
                          checkColor: Colors.white,
                          activeColor: Colors.red,
                          value: fireitemList
                              .where((x) => !x['ischeck'])
                              .toList()
                              .length ==
                              0,
                          onChanged: (bool value) {
                            setState(() {
                              allChecked = value;
                              fireitemList.forEach((e) {
                                e['ischeck'] = allChecked;
                              });
                            });
                          },
                        ),

                        backgroundColor: index.isOdd
                            ? Colors.limeAccent
                            : Colors.lightGreenAccent,
                        initiallyExpanded: false,

                        // 是否默认展开
                        children: fireitemList
                            .map((e) => Container(
                                margin: const EdgeInsets.all(1.0),
                                decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10)),
                                    border:
                                        Border.all(color: Colors.blueAccent)),
                                child: ListTile(
                                  leading: Checkbox(
                                    checkColor: Colors.white,
                                    value: e['ischeck'],
                                    onChanged: (bool value) {
                                      setState(() {
                                        e['ischeck'] = value;
                                      });
                                    },
                                  ) ,
                                  title:
                                      Text(e['itemId'] + ' ' + e['itemName']),
                                  subtitle:
                                      Text('狀態:' + status[e['presentStasus']]),
                                  onTap: () => {
                                    setState(() {
                                      e['ischeck'] = !e['ischeck'];
                                    })
                                  },

                                )))
                            .toList());
                  },
                )).toList()

            // <Widget>[
            //
            //
            //   for (var place in EquipmentLiST)
            //
            //     ListView.builder(
            //       itemCount: place['priorityList'].length,
            //       itemBuilder: (context, index) {
            //         var AreaLiST =place['priorityList'] ;
            //         var Area =AreaLiST[index];
            //         return
            //
            //
            //
            //           ListTile(
            //           title: Text( Area['subArea']),
            //         );
            //       },
            //     ),
            // ],
            ),
      ),
    );
    // return WillPopScope (
    //   onWillPop: () async {
    //     return false;
    //   },
    //   child:
    //   DefaultTabController(
    //     initialIndex: 0,
    //     length: EquipmentData == null ? 0 : EquipmentData.length,
    //     child: Scaffold(
    //       appBar: AppBar(
    //         title: Text('TabBar Widget'),
    //         bottom: TabBar(
    //           tabs: <Widget>[
    //             for (var title in EquipmentData) Tab(text: title['placeName'])
    //           ],
    //         ),
    //       ),
    //       body: TabBarView(
    //         children: <Widget>[
    //           for (var title in EquipmentData)
    //             Center(
    //               child: Text(title['placeName']),
    //             ),
    //         ],
    //       ),
    //     ),
    //   )
    // );
  }
}
