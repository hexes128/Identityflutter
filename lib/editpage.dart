import 'dart:convert';

import 'package:direct_select_flutter/direct_select_item.dart';
import 'package:direct_select_flutter/direct_select_list.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:future_progress_dialog/future_progress_dialog.dart';
import 'GlobalVariable.dart' as GV;
import 'package:http/http.dart' as http;

class editietm extends StatefulWidget {
  editietm({Key? key, this.Fireitem, this.initialplace, this.initialarea})
      : super(key: key);
  dynamic Fireitem;
  int? initialplace;
  int? initialarea;

  @override
  State<StatefulWidget> createState() {
    return editstate();
  }
}

class editstate extends State<editietm> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    futureList = _callApi();
    namecontroller = TextEditingController(text: widget.Fireitem['itemName']);
    postscriptcontroller =
        TextEditingController(text: widget.Fireitem['postscript']);
    Areaindex = widget.initialarea;
    Placeindex = widget.initialplace;
    areacontroller =
        FixedExtentScrollController(initialItem: widget.initialarea!);
    placecontroller =
        FixedExtentScrollController(initialItem: widget.initialplace!);
    WidgetsBinding.instance!.addObserver(this);
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

  TextEditingController? namecontroller;
  TextEditingController? postscriptcontroller;

  Future<String?> sendnewitem() async {
    var access_token = GV.info!['accessToken'];

    print(
        '${PlaceList![widget.initialplace!]['priorityList'][widget.initialarea]['storeId']}');
    print(
        '${PlaceList![placecontroller!.selectedItem]['priorityList'][areacontroller!.selectedItem]['storeId']}');
print( jsonEncode(<String, dynamic>{
  'itemid': widget.Fireitem['itemId'],
  'oldname': widget.Fireitem['itemName'],
  'newname': namecontroller!.text,
  'oldstore': PlaceList![widget.initialplace!]['priorityList']
  [widget.initialarea]['storeId'],
  'newstore': PlaceList![placecontroller!.selectedItem]['priorityList']
  [areacontroller!.selectedItem]['storeId'],
  'UserName': GV.info!['name'],
  'oldpostscript':   widget.Fireitem['postscript']==null?'':   widget.Fireitem['postscript'],
  'newpostscript':postscriptcontroller!.text.trim()
}));
    try {
      var response = await http.post(
          Uri(
              scheme: 'http',
              host: '140.133.78.140',
              port: 81,
              path: 'Item/editinfo'),
          headers: {
            "Authorization": "Bearer $access_token",
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, dynamic>{
            'itemid': widget.Fireitem['itemId'],
            'oldname': widget.Fireitem['itemName'],
            'newname': namecontroller!.text,
            'oldstore': PlaceList![widget.initialplace!]['priorityList']
                [widget.initialarea]['storeId'],
            'newstore': PlaceList![placecontroller!.selectedItem]['priorityList']
                [areacontroller!.selectedItem]['storeId'],
            'UserName': GV.info!['name'],
            'oldpostscript':   widget.Fireitem['postscript']==null?'':   widget.Fireitem['postscript'],
            'newpostscript':postscriptcontroller!.text.trim()
          }));

      if (response.statusCode == 200) {
        return response.body;
      } else {}
    } on Error catch (e) {
     print(e.toString());
    }
  }

  List<dynamic>? PlaceList;
  List<dynamic>? Arealist;

  int? Placeindex;

  int? Areaindex;

  FixedExtentScrollController? areacontroller;

  FixedExtentScrollController? placecontroller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: Text('編輯器材資訊'),
        ),
        body: SingleChildScrollView(
            child: Column(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Text(widget.Fireitem['itemId']),
                    TextField(
                      controller: namecontroller,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(), hintText: '器材名稱'),
                    ),
                    TextField(
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      controller: postscriptcontroller,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(), hintText: '備註'),
                    ),
                    Padding(
                      padding: EdgeInsets.all(16.0),
                    ),
                    FutureBuilder<List<dynamic>?>(
                      future: futureList,
                      builder: (BuildContext context,
                          AsyncSnapshot<List<dynamic>?> snapshot) {
                        if (snapshot.hasData) {
                          PlaceList = snapshot.data;
                          Arealist = PlaceList![Placeindex!]['priorityList'];
                          var a = 0;
                          Arealist!.sort((a, b) =>
                              a['priorityNum'].compareTo(b['priorityNum']));
                          return Row(children: [
                            Expanded(
                              child: Text('存放地'),
                              flex: 1,
                            ),
                            Expanded(
                              child: Center(
                                child: CupertinoPicker(
                                  scrollController: placecontroller,
                                  children: PlaceList!.map((e) =>
                                          Center(child: Text(e['placeName'])))
                                      .toList(),
                                  itemExtent: 50,
                                  onSelectedItemChanged: (int index) {
                                    setState(() {
                                      print('${areacontroller!.selectedItem}');
                                      Placeindex = index;

                                      areacontroller!.jumpTo(0);
                                    });
                                  },
                                ),
                              ),
                              flex: 2,
                            ),
                            Expanded(
                              child: Center(
                                child: CupertinoPicker(
                                  scrollController: areacontroller,
                                  children: Arealist!.map((e) {
                                    print(e['subArea']);
                                    return Center(child: Text(e['subArea']));
                                  }).toList(),
                                  itemExtent: 50,
                                  onSelectedItemChanged: (int index) {
                                    setState(() {
                                      Areaindex = index;
                                    });
                                  },
                                ),
                              ),
                              flex: 2,
                            ),
                          ]);
                        } else if (snapshot.hasError) {
                          return Text('錯誤');
                        } else {
                          return Text('讀取資料中');
                        }
                      },
                    ),
                  ],
                ),
                Column(
                  children: [
                    Container(
                      margin: EdgeInsets.symmetric(vertical: 20.0),
                      height: 50,
                      width: 250,
                      decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(20)),
                      child: FlatButton(
                        onPressed: () async {
                          await placecontroller!.animateToItem(
                              widget.initialplace!,
                              duration: Duration(milliseconds: 200),
                              curve: Curves.ease);
                          await areacontroller!.animateToItem(widget.initialarea!,
                              duration: Duration(milliseconds: 200),
                              curve: Curves.ease);
                          setState(() {
                            namecontroller = TextEditingController(
                                text: widget.Fireitem['itemName']);
                            postscriptcontroller = TextEditingController(
                                text: widget.Fireitem['postscript']);
                            Areaindex = widget.initialarea;
                            Placeindex = widget.initialplace;

                          });
                        },
                        child: Text(
                          '復原',
                          style: TextStyle(color: Colors.white, fontSize: 25),
                        ),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.symmetric(vertical: 20.0),
                      height: 50,
                      width: 250,
                      decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(20)),
                      child: FlatButton(
                        onPressed: () async {
                          if (namecontroller!.text.trim().isEmpty) {
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
                          print(postscriptcontroller!.text.trim());
                          print(widget.Fireitem['postscript']);
                          if (Areaindex == widget.initialarea &&
                              Placeindex == widget.initialplace &&
                              namecontroller!.text.trim() ==
                                  widget.Fireitem['itemName'] &&
                              widget.Fireitem['postscript'].toString().trim() ==
                                  postscriptcontroller!.text.trim()) {
                            Fluttertoast.showToast(
                                msg: '無任何更動',
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.CENTER,
                                timeInSecForIosWeb: 1,
                                backgroundColor: Colors.red,
                                textColor: Colors.white,
                                fontSize: 16.0);
                            return;
                          }

                          if (placecontroller!.selectedItem !=
                              widget.initialplace) {
                            bool? keepgo = false;
                            await showDialog<bool>(
                              barrierDismissible: false,
                              context: context,
                              builder: (BuildContext context) => AlertDialog(
                                title: Text('警告'),
                                content: Text('更改器材地點將會刪除本器材先前相關紀錄\n確定更改?'),
                                actions: <Widget>[
                                  FlatButton(
                                      child: Text('Cancel'),
                                      onPressed: () {
                                        Navigator.pop(context, false);
                                      }),
                                  FlatButton(
                                      child: Text('Ok'),
                                      onPressed: () {
                                        Navigator.pop(context, true);
                                      })
                                ],
                              ),
                            ).then((value) {
                              keepgo = value;
                            });
                            if (!keepgo!) {
                              return;
                            }
                          }
                          bool? keepgo = false;
                          await showDialog<bool>(
                            barrierDismissible: false,
                            context: context,
                            builder: (BuildContext context) => AlertDialog(
                              title: Text('確定送出以下變更?'),
                              content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Card(
                                        child: ListTile(
                                      title: Text('更動前'),
                                      subtitle: Text('器材名稱:' +
                                          widget.Fireitem['itemName'] +
                                          '\n地點:' +
                                          PlaceList![widget.initialplace!]
                                              ['placeName'] +
                                          '\n區域:' +
                                          PlaceList![widget.initialplace!]
                                                  ['priorityList']
                                              [widget.initialarea]['subArea'] +
                                          '\n備註:' +
                                          (widget.Fireitem['postscript']==null?'': widget.Fireitem['postscript'])),
                                    )),
                                    Card(
                                        child: ListTile(
                                      title: Text('更動後'),
                                      subtitle: Text('器材名稱:' +
                                          namecontroller!.text +
                                          '\n地點:' +
                                          PlaceList![placecontroller!
                                              .selectedItem]['placeName'] +
                                          '\n區域:' +
                                          PlaceList![placecontroller!
                                                          .selectedItem]
                                                      ['priorityList']
                                                  [areacontroller!.selectedItem]
                                              ['subArea'] +
                                          '\n備註:' +
                                          postscriptcontroller!.text.trim()),
                                    ))
                                  ]),
                              actions: <Widget>[
                                FlatButton(
                                    child: Text('Cancel'),
                                    onPressed: () {
                                      Navigator.pop(context, false);
                                    }),
                                FlatButton(
                                    child: Text('Ok'),
                                    onPressed: () {
                                      Navigator.pop(context, true);
                                    })
                              ],
                            ),
                          ).then((value) {
                            keepgo = value;
                          });
                          if (!keepgo!) {
                            return;
                          }

                          showDialog(
                            context: context,
                            builder: (context) => FutureProgressDialog(
                                sendnewitem().then((value) {
                                  Fluttertoast.showToast(
                                      msg: value==null?'':value,
                                      toastLength: Toast.LENGTH_SHORT,
                                      gravity: ToastGravity.CENTER,
                                      timeInSecForIosWeb: 1,
                                      backgroundColor: Colors.red,
                                      textColor: Colors.white,
                                      fontSize: 16.0);
                                  PlaceList![Placeindex!]['todaysend'] = true;
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
                  ],
                ),
              ],
            )
          ],
        )));
  }
}
