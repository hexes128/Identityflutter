import 'dart:async';
import 'dart:convert';
import 'package:identityflutter/ChangeStatus.dart';
import 'package:identityflutter/Inventorydate.dart';
import 'package:identityflutter/StatusChangerecord.dart';
import 'package:identityflutter/additem.dart';
import 'package:identityflutter/addplace.dart';

import 'Inventorylist.dart';
import 'editinforecord.dart';
import 'edititeminfolist.dart';
import 'twst.dart';
import 'dart:io';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:openid_client/openid_client_io.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'Dashboard.dart';
import 'GlobalVariable.dart' as GV;
import 'package:future_progress_dialog/future_progress_dialog.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '消防設備管理系統 登入',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final storage = new FlutterSecureStorage();

  int _selectedIndex = 0;

  var arr = [
    ['個人資料', '隊員管理'],
    ['設備盤點', '設備狀態異動', '新增設備', '編輯設備資訊','新增地點'],
    ['盤點紀錄', '狀態異動紀錄', '資訊編輯紀錄', '寄出盤點碼(長按)']
  ];

  _auth() async {
    var uri = new Uri(scheme: "http", host: '140.133.78.44', port: 82);
    try {
      var issuer = await Issuer.discover(uri);
      var client = new Client(issuer, "flutter");

      var authenticator = new Authenticator(client,
          scopes: ['profile', 'openid', 'IdentityServerApi', 'API', 'email'],
          port: 4000,
          urlLancher: urlLauncher);

      var c = await authenticator.authorize();

      try {
        var userinfo = await c.getUserInfo();
        var tokenresponse = await c.getTokenResponse();
        print(tokenresponse.accessToken);
        await storage.write(
            key: 'TokenResponse', value: jsonEncode(tokenresponse));
        await storage.write(key: 'UserInfo', value: jsonEncode(userinfo));
        var logouturl = c
            .generateLogoutUrl(
                redirectUri: Uri(scheme: 'http', host: 'localhost', port: 4000))
            .toString(); //獲取登出網址
        await storage.write(key: 'logouturl', value: logouturl);
        setState(() {});
        //登入成功並獲取userinfo
      } catch (e) {
        //取消登入
      }
    } catch (error) {
      //超時

    }
    closeWebView();
  }

  Future<void> _logout() async {
    var logouturl = await storage.read(key: 'logouturl');
    if (await canLaunch(logouturl)) {
      await launch(logouturl, forceWebView: true, enableJavaScript: true);
      Future.delayed(Duration(milliseconds: 500));

      await storage.deleteAll();

      setState(() {});
    } else {
      throw 'Could not launch $logouturl';
    }
  }

  urlLauncher(String url) async {
    if (await canLaunch(url)) {
      await launch(url, forceWebView: true, enableJavaScript: true);
    } else {
      throw 'Could not launch $url';
    }
  }
  Future<String> sendemail() async {
    var access_token = GV.tokenResponse.accessToken;
print(GV.userinfo.email);
    try {
      var response = await http.get(
          Uri(
              scheme: 'http',
              host: '140.133.78.44',
              port: 81,
              path: 'Item/generatecodewithoutsave',queryParameters: <String,String>{'email':GV.userinfo.email}),
          headers: {"Authorization": "Bearer $access_token"});
      if (response.statusCode == 200) {
        return  '123';
      } else {
        print('${response.statusCode}');
      }
    } on Error catch (e) {
      throw Exception('123');
    }
    return ('123');
  }

  Future<String> _callApi() async {
    var access_token = GV.tokenResponse.accessToken;

    try {
      var response = await http.get(
          Uri(
              scheme: 'http',
              host: '140.133.78.44',
              port: 81,
              path: 'Item/GetItem'),
          headers: {"Authorization": "Bearer $access_token"});
      if (response.statusCode == 200) {
        return response.body;
      } else {}
    } on Error catch (e) {
      throw Exception('123');
    }
  }


Future<bool> readtoken() async{

    var token = await storage.read(key: 'TokenResponse');
    if(token ==null){
      return false;
    }

}
  @override
  Widget build(BuildContext context) {
    var images = [
      'images/A.jpg',
      'images/1.jpg',
      'images/2.jpg',
      'images/3.jpg',
      'images/4.jpg',
      'images/5.jpg',
      'images/6.jpg',
      'images/7.jpg',
      'images/8.jpg'
    ];
    return FutureBuilder<String>(
        future: storage.read(key: 'TokenResponse'),
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (snapshot.hasData) {
            var selectfeature = arr[_selectedIndex];
            GV.tokenResponse = TokenResponse.fromJson(jsonDecode(snapshot.data));

            return Scaffold(
              appBar: AppBar(
                  actions: [
                    IconButton(
                        onPressed: () {
                          _logout();
                        },
                        icon: Icon(Icons.logout))
                  ],
                  title: FutureBuilder<String>(
                      future: storage.read(key: 'UserInfo'),
                      builder: (BuildContext context,
                          AsyncSnapshot<String> snapshot) {
                        if (snapshot.hasData) {
                          GV.userinfo =
                              UserInfo.fromJson(jsonDecode(snapshot.data));
                          return Text('歡迎 ${GV.userinfo.name}');
                        } else {
                          return Text('讀取中');
                        }
                      })),
              body: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, childAspectRatio: 2.5),
                  itemCount: selectfeature.length,
                  itemBuilder: (BuildContext context, int index) {

                    return GestureDetector(
                      child: Card(
                        color: Colors.amber,
                        child: Center(child: Text(selectfeature[index])),
                      ),
                      onTap: () {
                        switch (selectfeature[index]) {
                          case ('設備盤點'):
                            {
                              Navigator.push(
                                //從登入push到第二個
                                context,
                                new MaterialPageRoute(
                                    builder: (context) => InventoryList()),
                              );
                              break;
                            }
                          case ('盤點紀錄'):
                            {
                              Navigator.push(
                                //從登入push到第二個
                                context,
                                new MaterialPageRoute(
                                    builder: (context) => InventoryRecord()),
                              );
                              break;
                            }
                          case ('設備狀態異動'):
                            {
                              Navigator.push(
                                //從登入push到第二個
                                context,
                                new MaterialPageRoute(
                                    builder: (context) => ChangeStatus()),
                              );
                              break;
                            }
                          case ('狀態異動紀錄'):
                            {
                              Navigator.push(
                                //從登入push到第二個
                                context,
                                new MaterialPageRoute(
                                    builder: (context) => StatusRecord()),
                              );
                              break;
                            }
                          case ('新增設備'):
                            {
                              Navigator.push(
                                //從登入push到第二個
                                context,
                                new MaterialPageRoute(
                                    builder: (context) => additemform()),
                              );
                              break;
                            }
                          case ('新增設備'):
                            {
                              Navigator.push(
                                //從登入push到第二個
                                context,
                                new MaterialPageRoute(
                                    builder: (context) => additemform()),
                              );
                              break;
                            }

                          case('編輯設備資訊'):{
                            Navigator.push(
                              //從登入push到第二個
                              context,
                              new MaterialPageRoute(
                                  builder: (context) => editinfolist()),
                            );
                            break;


                          }


                          case('新增地點'):{
                            Navigator.push(
                              //從登入push到第二個
                              context,
                              new MaterialPageRoute(
                                  builder: (context) => addplace()),
                            );
                            break;
                          }
                          case('資訊編輯紀錄'):{
                            Navigator.push(
                              //從登入push到第二個
                              context,
                              new MaterialPageRoute(
                                  builder: (context) => EditinfoRecord()),
                            );
                            break;


                          }
                        }
                      },
                      onLongPress: () {
                        if (selectfeature[index] == '寄出盤點碼(長按)') {
                          showDialog(
                            context: context,
                            builder: (context) => FutureProgressDialog(
                                sendemail().then((value) {
                                  Fluttertoast.showToast(
                                      msg: '寄送成功，請至信箱查看',
                                      toastLength: Toast.LENGTH_SHORT,
                                      gravity: ToastGravity.CENTER,
                                      timeInSecForIosWeb: 1,
                                      backgroundColor: Colors.red,
                                      textColor: Colors.white,
                                      fontSize: 16.0);

                                }),
                                message: Text('資料處理中，請稍後')),
                          );
                        }
                      },
                    );
                  }),
              bottomNavigationBar: BottomNavigationBar(
                items: const <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: Icon(Icons.account_box),
                    label: '人員管理',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.inventory_outlined),
                    label: '設備管理',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.history_outlined),
                    label: '紀錄查詢',
                  ),
                ],
                currentIndex: _selectedIndex,
                selectedItemColor: Colors.amber[800],
                onTap: (int index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
              ),
            );
          } else {
            return Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                title: Text("消防設備管理應用-登入"),
              ),
              body: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(top: 50.0),
                      child: Center(
                        child: Container(
                            width: 1000,
                            height: 300,
                            child: CarouselSlider.builder(
                              itemCount: images.length,
                              options: CarouselOptions(
                                  initialPage: 0,
                                  enlargeCenterPage: true,
                                  autoPlay: true,
                                  autoPlayInterval: Duration(seconds: 3)),
                              itemBuilder: (BuildContext context, int itemIndex,
                                      int pageViewIndex) =>
                                  Container(
                                child: Image.asset(images[itemIndex]),
                              ),
                            )
                            // child: Image.asset('images/1.jpg')
                            ),
                      ),
                    ),
                    SizedBox(
                      height: 100,
                    ),
                    Container(
                      margin: EdgeInsets.symmetric(vertical: 20.0),
                      height: 50,
                      width: 250,
                      decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(20)),
                      child: FlatButton(
                        onPressed: () {
                          _auth();
                        },
                        child: Text(
                          '登入',
                          style: TextStyle(color: Colors.white, fontSize: 25),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        });
  }
}
