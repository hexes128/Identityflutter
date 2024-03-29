import 'dart:convert';


import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:future_progress_dialog/future_progress_dialog.dart';
import 'GlobalVariable.dart' as GV;
import 'package:http/http.dart' as http;

class addplace extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return addplacestate();
  }
}

class addplacestate extends State<addplace> with WidgetsBindingObserver {
  var placecontroller = TextEditingController();
  List<TextField> arealist = [];
  List<TextEditingController> controllerlist = [];

  @override
  void initState() {
    WidgetsBinding.instance!.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
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

  Future<String?> sendInventory() async {
    var access_token = GV.info!['accessToken'];

    try {
      var response = await http.post(
          Uri(
              scheme: 'http',
              host: '140.133.78.140',
              port: 81,
              path: 'Item/addplace'),
          headers: {
            "Authorization": "Bearer $access_token",
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, dynamic>{
            'placeName': placecontroller.text,
            'priorityList': arealist
                .map((e) => <String, dynamic>{
                      'subArea': e.controller!.text,
                      'priorityNum': arealist.indexOf(e) + 1
                    })
                .toList()
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
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: placecontroller,
          decoration: InputDecoration(
            fillColor: Colors.white,
            filled: true,
            hintText: '輸入地點',
          ),
        ),
        actions: [
          IconButton(
              onPressed: () {
                setState(() {
                  var controller = TextEditingController();
                  controllerlist.add(controller);
                  arealist.add(
                    TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        fillColor: Colors.white,
                        filled: true,
                        hintText:
                            '輸入區域 ${controllerlist.indexOf(controller) + 1}',
                      ),
                    ),
                  );
                });
              },
              icon: Icon(Icons.add)),
          IconButton(
              onPressed: () {
                if (placecontroller.text.isEmpty) {
                  Fluttertoast.showToast(
                      msg: '未填寫地點',
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.CENTER,
                      timeInSecForIosWeb: 1,
                      backgroundColor: Colors.red,
                      textColor: Colors.white,
                      fontSize: 16.0);
                  return;
                }
                if (arealist.length > 0) {
                  if (arealist
                          .map((e) => e.controller!.text)
                          .where((e) => e.isEmpty)
                          .length >
                      0) {
                    Fluttertoast.showToast(
                        msg: '尚有區域未填寫',
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
                      title: Text('確認新增' + placecontroller.text + '?'),
                      content: Container(
                          width: double.maxFinite,
                          child: ListView.builder(
                              itemCount: arealist.length,
                              shrinkWrap: true,
                              itemBuilder: (BuildContext context, int index) {
                                return Card(
                                  child: ListTile(
                                    title:
                                        Text(arealist[index].controller!.text),
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
                              builder: (context) => FutureProgressDialog(
                                  sendInventory().then((value) {
                                    Fluttertoast.showToast(
                                        msg: value==null?'':value,
                                        toastLength: Toast.LENGTH_SHORT,
                                        gravity: ToastGravity.CENTER,
                                        timeInSecForIosWeb: 1,
                                        backgroundColor: Colors.red,
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
                      msg: '尚未新增區域',
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.CENTER,
                      timeInSecForIosWeb: 1,
                      backgroundColor: Colors.red,
                      textColor: Colors.white,
                      fontSize: 16.0);
                  return;
                }
              },
              icon: Icon(Icons.cloud_upload)),
        ],
      ),
      body: ListView.builder(
        shrinkWrap: true,
        itemCount: arealist.length,
        itemBuilder: (context, index) {
          return Card(
              child: ListTile(
            onTap: () {
              print(arealist[index].controller!.text);
            },
            subtitle: TextField(
              controller: controllerlist[index],
              decoration: InputDecoration(
                fillColor: Colors.white,
                filled: true,
                hintText: '輸入區域 ${index + 1}',
              ),
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                setState(() {
                  arealist.removeAt(index);
                  controllerlist.removeAt(index);
                });
              },
            ),
          ));
        },
      ),
    );
  }
}
