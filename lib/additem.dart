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

class additemstate extends State<additemform> {
  @override
  void initState() {
    super.initState();
    futureList = _callApi();
  }

  Future<List<dynamic>> futureList;

  Future<List<dynamic>> _callApi() async {
    var access_token = GV.tokenResponse.accessToken;

    try {
      var response = await http.get(
          Uri(
              scheme: 'http',
              host: '192.168.10.152',
              port: 3000,
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

  Future<String> sendnewitem() async {
    var access_token = GV.tokenResponse.accessToken;

    try {
      var response = await http.post(
          Uri(
              scheme: 'http',
              host: '192.168.10.152',
              port: 3000,
              path: 'Item/additem'),
          headers: {
            "Authorization": "Bearer $access_token",
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(
              itemlist.map((e) {

                return { 'ItemName':e.namecontroller.text,
                  'StoreId':Arealist[e.scrollController.selectedItem]['storeId']};

              }).toList()

          ));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        print(jsonEncode(<String, dynamic>{
          'ItemName': namecontroller.text,
          'StoreId': Arealist[Areaindex]['storeId'],
          'UserId': GV.userinfo.subject
        }));
      }
    } on Error catch (e) {
      throw Exception('123');
    }
  }

  List<dynamic> PlaceList;
  List<dynamic> Arealist;
  List<iteminput> itemlist = [];
  String Areavalue;

  int Placeindex = 0;
  int Areaindex = 0;
  var areacontroller = FixedExtentScrollController();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: futureList,
      builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.hasData) {
          PlaceList = snapshot.data;
          Arealist = PlaceList[Placeindex]['priorityList'];

          Arealist.sort((a, b) =>
              a['priorityNum'].compareTo(b['priorityNum']));
          return Scaffold(
              appBar: AppBar(
                  title: CupertinoPicker(

                    children: PlaceList.map(
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
                        onPressed: () {
                          setState(() {
                            itemlist.add(iteminput());
                          });
                        },
                        icon: Icon(Icons.add)),

                    IconButton(
                        onPressed: () {

                          if (itemlist.length > 0) {
                            if (itemlist.map((e) => e.namecontroller.text).where((e) => e.isEmpty).length > 0) {
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
                                        itemBuilder: (BuildContext context, int index) {
                                          return Card(
                                            child: ListTile(
                                              title:
                                              Text(itemlist[index].namecontroller.text),
                                              subtitle:

                                              Text(  Arealist[itemlist[index].scrollController.selectedItem]['subArea'])
                                            ,
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
                                                sendnewitem()
                                                    .then((value) {
                                                  Fluttertoast.showToast(
                                                      msg: value,
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
                  return

                    Card(
                    child: Row(children: [
                      Expanded( child: TextField(
                          controller: controllers.namecontroller,
                          decoration: InputDecoration(
                            fillColor: Colors.white,
                            filled: true,
                            hintText: '輸入設備名稱',
                          )),flex: 7,),
                      Expanded(child: CupertinoPicker(
                        scrollController: controllers.scrollController,
                        children: Arealist.map(
                                (e) => Center(child: Text(e['subArea']))).toList(),
                        itemExtent: 50,
                        onSelectedItemChanged: (int index) {
                          setState(() {

                          });
                        },
                      ),flex: 2,),
                      Expanded(child:    IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            itemlist.remove(controllers);

                          });
                        },
                      ),flex:1 ),



                    ]),
                  );
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
class iteminput{

 TextEditingController namecontroller = TextEditingController();
 FixedExtentScrollController scrollController =FixedExtentScrollController() ;

}
