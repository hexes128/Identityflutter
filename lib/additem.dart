import 'dart:convert';

import 'package:direct_select_flutter/direct_select_item.dart';
import 'package:direct_select_flutter/direct_select_list.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:future_progress_dialog/future_progress_dialog.dart';
import 'GlobalVariable.dart' as GV;
import 'package:http/http.dart' as http;

class additemform extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return additemstate();
  }
}

class additemstate extends State<additemform> with WidgetsBindingObserver {
  @override
  void initState() {
    WidgetsBinding.instance!.addObserver(this);
    super.initState();
    futureList = _callApi();
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

  Future<List<dynamic>?> _callApi() async {
    var access_token = GV.info!['accessToken'];

    try {
      var response = await http.get(
          Uri(
              scheme: 'http',
              host: '140.133.78.140',
              port: 81,
              path: 'Item/placeinfo'),
          headers: {"Authorization": "Bearer $access_token"});
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {}
    } on Error catch (e) {
      throw Exception('123');
    }
  }

  var namecontroller = TextEditingController();

  Future<String?> sendnewitem() async {
    var access_token = GV.info!['accessToken'];

    try {
      var response = await http.post(
          Uri(
              scheme: 'http',
              host: '140.133.78.140',
              port: 81,
              path: 'Item/additem'),
          headers: {
            "Authorization": "Bearer $access_token",
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(itemlist.map((e) {
            return {
              'ItemName': e.namecontroller.text,
              'postscript':
                  e.addpostscript! ? e.postscriptcontroller.text : '',
              'StoreId': Arealist![e.areaindex]['storeId']
            };
          }).toList()));

      if (response.statusCode == 200) {
        return response.body;
      } else {

      }
    } on Error catch (e) {
      throw Exception('123');
    }
  }

  List<dynamic>? PlaceList;
  List<dynamic>? Arealist;
  List<iteminput> itemlist = [];
  String? Areavalue;

  int Placeindex = 0;
  int Areaindex = 0;
  var areacontroller = FixedExtentScrollController();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>?>(
      future: futureList,
      builder: (BuildContext context, AsyncSnapshot<List<dynamic>?> snapshot) {
        if (snapshot.hasData) {
          PlaceList = snapshot.data;
          Arealist = PlaceList![Placeindex]['priorityList'];

          Arealist!.sort((a, b) => a['priorityNum'].compareTo(b['priorityNum']));
          return Scaffold(
              appBar: AppBar(
                  title: CupertinoPicker(
                    children: PlaceList!.map(
                        (e) => Center(child: Text(e['placeName']))).toList(),
                    itemExtent: 50,
                    onSelectedItemChanged: (int index) {
                      setState(() {
                        Placeindex = index;
                        itemlist.forEach((e) {
                          e.areaindex = 0;
                        });
                      });
                    },
                  ),
                  actions: [
                    IconButton(
                        onPressed: () {
                          setState(() {
                            itemlist.add(iteminput());
                          });
                        },
                        icon: Icon(Icons.add)),
                    IconButton(
                        onPressed: () {
                          if (itemlist.length > 0) {
                            if (itemlist
                                    .map((e) => e.namecontroller.text)
                                    .where((e) => e.isEmpty)
                                    .length >
                                0) {
                              Fluttertoast.showToast(
                                  msg: '尚有設備名稱未填寫',
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.CENTER,
                                  timeInSecForIosWeb: 1,
                                  backgroundColor: Colors.red,
                                  textColor: Colors.white,
                                  fontSize: 16.0);
                              return;
                            }
                            showDialog<String>(
                              context: context,
                              builder: (BuildContext context) => AlertDialog(
                                title: Text('確認以下設備?'),
                                content: Container(
                                    width: double.maxFinite,
                                    child: ListView.builder(
                                        itemCount: itemlist.length,
                                        shrinkWrap: true,
                                        itemBuilder:
                                            (BuildContext context, int index) {
                                          return Card(
                                            child: ListTile(
                                              title: Text(itemlist[index]
                                                  .namecontroller
                                                  .text+' '+Arealist![
                                              itemlist[index].areaindex]
                                              ['subArea']),
                                              subtitle: Text(itemlist[index].addpostscript!?'備註:'+itemlist[index].postscriptcontroller.text:''),
                                            ),
                                          );
                                        })),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () {
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
                                                sendnewitem().then((value) {
                                                  Fluttertoast.showToast(
                                                      msg: value==null?'':value,
                                                      toastLength:
                                                          Toast.LENGTH_SHORT,
                                                      gravity:
                                                          ToastGravity.CENTER,
                                                      timeInSecForIosWeb: 1,
                                                      backgroundColor:
                                                          Colors.red,
                                                      textColor: Colors.white,
                                                      fontSize: 16.0);
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
                                msg: '尚未新增設備',
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.CENTER,
                                timeInSecForIosWeb: 1,
                                backgroundColor: Colors.red,
                                textColor: Colors.white,
                                fontSize: 16.0);
                            return;
                          }
                        },
                        icon: Icon(Icons.cloud_upload))
                  ]),
              body: ListView(
                children: itemlist.map((controllers) {
                  return Dismissible(
                      onDismissed: (direction) {
                        setState(() {
                          itemlist.remove(controllers);
                        });
                      },
                      key: UniqueKey(),
                      child: Card(
                        key: UniqueKey(),
                        child: Row(children: [
                          Expanded(
                            child: Column(
                                children: controllers.addpostscript!
                                    ? [
                                        TextField(
                                            controller:
                                                controllers.namecontroller,
                                            decoration: InputDecoration(
                                              fillColor: Colors.white,
                                              filled: true,
                                              hintText: '輸入設備名稱',
                                            )),
                                        TextField(
                                            keyboardType:
                                                TextInputType.multiline,
                                            maxLines: null,
                                            controller: controllers
                                                .postscriptcontroller,
                                            decoration: InputDecoration(
                                              fillColor: Colors.white,
                                              filled: true,
                                              hintText: '輸入備註',
                                            )),
                                      ]
                                    : [
                                        TextField(
                                            controller:
                                                controllers.namecontroller,
                                            decoration: InputDecoration(
                                              fillColor: Colors.white,
                                              filled: true,
                                              hintText: '輸入設備名稱',
                                            ))
                                      ]),
                            flex: 5,
                          ),
                          Expanded(
                            child: Column(children: [
                              Text('存放區'),
                              DropdownButton<String>(
                                value: Arealist![controllers.areaindex]
                                    ['subArea'],
                                iconSize: 24,
                                elevation: 16,
                                style:
                                    const TextStyle(color: Colors.deepPurple),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    controllers.areaindex =
                                        Arealist!.map((e) => e['subArea'])
                                            .toList()
                                            .indexOf(newValue);
                                  });
                                },
                                items:
                                    Arealist!.map((e) => e['subArea'].toString())
                                        .map<DropdownMenuItem<String>>(
                                            (String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                              )
                            ]),
                            flex: 3,
                          ),
                          Expanded(
                            child: Column(children: [
                              Text('新增備註'),
                              Checkbox(
                                checkColor: Colors.white,
                                value: controllers.addpostscript,
                                onChanged: (bool? value) {
                                  setState(() {
                                    controllers.addpostscript = value;
                                  });
                                },
                              )
                            ]),
                            flex: 2,
                          ),

                        ]),
                      ));
                }).toList(),
              ));
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

class iteminput {
  TextEditingController namecontroller = TextEditingController();
  TextEditingController postscriptcontroller = TextEditingController();
  FixedExtentScrollController scrollController = FixedExtentScrollController();

  int areaindex = 0;
  bool? addpostscript = false;
}
