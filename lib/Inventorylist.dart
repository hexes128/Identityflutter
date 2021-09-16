import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:identityflutter/GlobalVariable.dart' as GV;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:developer';
import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class InventoryList extends StatefulWidget {
  InventoryList({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => InventoryListState();
}

class InventoryListState extends State<InventoryList>
    with TickerProviderStateMixin {
  bool showcamera = false;
  Barcode result;
  QRViewController controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller.pauseCamera();
    }
    controller.resumeCamera();
  }

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
  bool allChecked = false;
  List<dynamic> PlaceList;
  List<dynamic> AreaList;
  List<dynamic> ItemList;
  int Areaindex = 0;
  int Placeindex = 0;
  var status = ['正常', '借出', '報修', '停用'];
  TabController tabController;

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
                    switch (index) {
                      case (0):
                        {
                          setState(() {
                            showcamera = true;
                          });

                          break;
                        }
                      case (1):
                        {
                          setState(() {
                            showcamera = false;
                          });
                        }
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
            body: Column(
              children: [
                showcamera
                    ? Expanded(flex: 1, child: _buildQrView(context))
                    : Container(),
                Expanded(
                    flex: 4,
                    child: ListView.builder(
                        itemCount: ItemList.length,
                        itemBuilder: (context, index) {
                          var Fireitem = ItemList[index];
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
                            title: Text(Fireitem['itemId'] +
                                ' ' +
                                Fireitem['itemName']),
                            subtitle: Text(
                                '當前狀態:' + status[Fireitem['presentStasus']]),
                            onTap: () => {
                              setState(() {
                                Fireitem['ischeck'] = !Fireitem['ischeck'];
                              })
                            },
                          );
                        }))
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

  Widget _buildQrView(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 100.0
        : 200.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) async {
      await controller.pauseCamera();

      try{
        var Fireitem = ItemList.firstWhere((x)=>x['itemId']==scanData.code);
        if(! Fireitem['ischeck']){
          showDialog<String>(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: Text(scanData.code),
              content:  Text(Fireitem['itemName']),
              actions: <Widget>[
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context, 'Cancel');
                    await controller.resumeCamera();
                  },
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () async {
                    setState(() {
                      Fireitem['ischeck']= true;
                    });
                    Navigator.pop(context);
                    await controller.resumeCamera();
                  },
                  child: const Text('確定'),
                ),
              ],
            ),
          );

        }
        else{

          showDialog<String>(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: Text('重複掃描'),
              content:  Text(Fireitem['itemId']+' 已經勾選'),
              actions: <Widget>[
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await controller.resumeCamera();
                  },
                  child: const Text('確定'),
                ),

              ],
            ),
          );

        }
      }
      on Error catch(e){
        showDialog<String>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text('查無此id'),
            content:  Text('請確認地點區域是否選擇正確'),
            actions: <Widget>[
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await controller.resumeCamera();
                },
                child: const Text('確定'),
              ),

            ],
          ),
        );

      }




    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('no Permission')),
      );
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
