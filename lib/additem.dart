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
          body: jsonEncode(<String, dynamic>{
            'ItemName': namecontroller.text,
            'StoreId': Arealist[Areaindex]['storeId'],
            'UserId': GV.userinfo.subject
          }));

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

  String Areavalue;

  int Placeindex = 0;
  int Areaindex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('新增設備'),
      ),
      body: Column(
        children: [
          Flexible(
            child: Column(
              children: [
                TextField(
                  controller: namecontroller,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(), hintText: '設備名稱'),
                ),
                FutureBuilder<List<dynamic>>(
                  future: futureList,
                  builder: (BuildContext context,
                      AsyncSnapshot<List<dynamic>> snapshot) {
                    if (snapshot.hasData) {
                      PlaceList = snapshot.data;
                      Arealist = PlaceList[Placeindex]['priorityList'];

                      return Row(children: [
                        Expanded(
                          child: Text('存放地'),
                          flex: 1,
                        ),
                      

                        Expanded(
                          child: DropdownButton<String>(
                              value: PlaceList[Placeindex]['placeName'],
                              iconSize: 24,
                              elevation: 16,
                              onChanged: (String value) {
                                setState(() {
                                  Placeindex =
                                      PlaceList.map((e) => e['placeName'])
                                          .toList()
                                          .indexOf(value);
                                });
                              },
                              items: PlaceList.map(
                                      (e) => e['placeName'].toString())
                                  .map<DropdownMenuItem<String>>(
                                      (String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList()),
                          flex: 2,
                        ),
                        Expanded(
                          child: DropdownButton<String>(
                              value: Arealist[Areaindex]['subArea'],
                              icon: const Icon(Icons.arrow_downward),
                              iconSize: 24,
                              elevation: 16,
                              style: const TextStyle(color: Colors.deepPurple),
                              underline: Container(
                                height: 2,
                                color: Colors.deepPurpleAccent,
                              ),
                              onChanged: (String value) {
                                setState(() {
                                  Areaindex = Arealist.map((e) => e['subArea'])
                                      .toList()
                                      .indexOf(value);
                                });
                              },
                              items:
                                  Arealist.map((e) => e['subArea'].toString())
                                      .map<DropdownMenuItem<String>>(
                                          (String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList()),
                          flex: 2,
                        ),
                      ]);
                    } else if (snapshot.hasError) {
                      return Text('錯誤');
                    } else {
                      return Text('123');
                    }
                  },
                ),
              ],
            ),
            flex: 2,
          ),
          Flexible(
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 20.0),
              height: 50,
              width: 250,
              decoration: BoxDecoration(
                  color: Colors.blue, borderRadius: BorderRadius.circular(20)),
              child: FlatButton(
                onPressed: () {
                  if (namecontroller.text.trim().isEmpty) {
                    Fluttertoast.showToast(
                        msg: '名稱不可空白',
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.CENTER,
                        timeInSecForIosWeb: 1,
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                        fontSize: 16.0);
                    return;
                  }
                  showDialog(
                    context: context,
                    builder: (context) => FutureProgressDialog(
                        sendnewitem().then((value) {
                          Fluttertoast.showToast(
                              msg: '成功新增' + value + '筆紀錄',
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.CENTER,
                              timeInSecForIosWeb: 1,
                              backgroundColor: Colors.red,
                              textColor: Colors.white,
                              fontSize: 16.0);
                          PlaceList[Placeindex]['todaysend'] = true;
                        }),
                        message: Text('資料處理中，請稍後')),
                  );
                },
                child: Text(
                  '送出',
                  style: TextStyle(color: Colors.white, fontSize: 25),
                ),
              ),
            ),
            flex: 1,
          )
        ],
      ),
    );
  }
}
