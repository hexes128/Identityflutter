import 'dart:async';
import 'dart:convert';

import 'package:identityflutter/ChangeStatus.dart';
import 'package:identityflutter/Inventorydate.dart';
import 'package:identityflutter/StatusChangerecord.dart';
import 'package:identityflutter/UserInfopage.dart';
import 'package:identityflutter/additem.dart';
import 'package:identityflutter/addplace.dart';
import 'Inventorylist.dart';
import 'editinforecord.dart';
import 'edititeminfolist.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

import 'package:fluttertoast/fluttertoast.dart';

import 'package:carousel_slider/carousel_slider.dart';
import 'GlobalVariable.dart' as GV;
import 'package:future_progress_dialog/future_progress_dialog.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_appauth/flutter_appauth.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
bool backfrombroswer =false;

initialtimeoutcheck()async{
var expired = await storage.read(key: 'accessTokenExpirationDateTime');

  if( expired!=null && DateTime.parse(expired).difference(DateTime.now()).inSeconds<GV.settimeout){
    var idtoken = await storage.read(key: 'idToken');
    showDialog<String>(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('登入時間逾時 請重新登入'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              _logout(idtoken);
              Navigator.pop(
                context,
              );
            },
            child: Text('確定'),
          ),
        ],
      ),

    );
  }
}

  @override
  initState() {
initialtimeoutcheck();
    WidgetsBinding.instance.addObserver(this);
    super.initState();

  }

  @override
  void dispose() {

    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {

    setState(() {

    });
    if(state.index==0){

      if(backfrombroswer){
        backfrombroswer=false;
        return;
      }

      if( GV.info!=null && DateTime.parse(GV.info['accessTokenExpirationDateTime']).difference(DateTime.now()).inSeconds<GV.settimeout){
print(DateTime.parse(GV.info['accessTokenExpirationDateTime']).difference(DateTime.now()).inSeconds);
        showDialog<String>(
          barrierDismissible: false,
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text('登入時間逾時 請重新登入'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  _logout(GV.info['idToken']);
                  Navigator.pop(
                    context,
                  );
                },
                child: Text('確定'),
              ),
            ],
          ),

        );
      }

    }
  }

  final storage = new FlutterSecureStorage();
  final FlutterAppAuth _appAuth = FlutterAppAuth();

  int _selectedIndex = 0;

  var arr = [
    ['個人資料'],
    ['設備盤點', '設備狀態異動', '新增設備', '編輯設備資訊', '新增地點'],
    ['盤點紀錄', '狀態異動紀錄', '資訊編輯紀錄', '寄出盤點碼(長按)']
  ];

  Future<void> _signInWithAutoCodeExchange() async {
    try {
      final AuthorizationTokenResponse result =
          await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          'flutter',
          'com.firedepartment.apps.flutter2:/oauth2redirect',
          serviceConfiguration: AuthorizationServiceConfiguration(
            authorizationEndpoint: 'http://140.133.78.140:82/connect/authorize',
            tokenEndpoint: 'http://140.133.78.140:82/connect/token',
            endSessionEndpoint: 'http://140.133.78.140:82/connect/endsession',
          ),
          scopes: [
            'profile',
            'openid',
            'API',
            'email',
            'phone',
            'address',
            'offline_access'
          ],
          allowInsecureConnections: true,
          preferEphemeralSession: true,
          promptValues: ['login'],
        ),
      );

      if (result != null) {

        final http.Response httpResponse = await http.get(
            Uri.parse('http://140.133.78.140:82/connect/userinfo'),
            headers: <String, String>{
              'Authorization': 'Bearer ${result.accessToken}'
            });
        if (httpResponse.statusCode == 200) {
          var userinfo = jsonDecode(httpResponse.body);
print(result.accessToken +'\n'+'accesstoken');
print(result.idToken+'\n'+'idtoken');
          await storage.deleteAll();
          await storage.write(key: 'name', value: userinfo['name']);
          await storage.write(key: 'email', value: userinfo['email']);
          await storage.write(key: 'phone_number', value: userinfo['phone_number']);
          await storage.write(key: 'US_VISA', value: userinfo['address']);
          await storage.write(key: 'accessToken', value: result.accessToken);
          await storage.write(key: 'refreshToken', value: result.refreshToken);
          await storage.write(
              key: 'accessTokenExpirationDateTime',
              value: result.accessTokenExpirationDateTime.toString());

          await storage.write(key: 'idToken', value: result.idToken);
          setState(() {

          });
        }
      }
    } catch (_) {
      backfrombroswer =false;
    }
  }

  Future<void> _logout(String idtoken) async {
    try {
      // await storage.deleteAll();
backfrombroswer =true;

EndSessionResponse result =      await _appAuth.endSession(EndSessionRequest(
          idTokenHint: idtoken,
          postLogoutRedirectUrl:
              'com.firedepartment.apps.flutter2:/oauth2redirect',
          serviceConfiguration: AuthorizationServiceConfiguration(
            authorizationEndpoint: 'http://140.133.78.140:82/connect/authorize',
            tokenEndpoint: 'http://140.133.78.140:82/connect/token',
            endSessionEndpoint: 'http://140.133.78.140:82/connect/endsession',
          )));

if(result!=null){
  await storage.deleteAll();

}

      setState(() {

      });
_signInWithAutoCodeExchange();
    } catch (e) {
      backfrombroswer =false;
    }
  }



  Future<String> sendemail() async {
    var access_token = GV.info['accessToken'];

    try {
      var response = await http.get(
          Uri(
              scheme: 'http',
              host: '140.133.78.140',
              port: 81,
              path: 'Item/generatecodewithoutsave',
              queryParameters: <String, String>{'email': GV.info['email']}),
          headers: {"Authorization": "Bearer $access_token"});
      if (response.statusCode == 200) {
        return '123';
      } else {
        print('${response.statusCode}');
      }
    } on Error catch (e) {

    }
    return ('123');
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
    return
      FutureBuilder<Map<String, String>>(
        future: storage.readAll(),
        initialData:null,
        builder: (BuildContext context, AsyncSnapshot<Map<String, String>> snapshot) {
          if (snapshot.hasData&& snapshot.data.isNotEmpty) {
            var selectfeature = arr[_selectedIndex];
            GV.info = snapshot.data;
            return Scaffold(
              appBar: AppBar(actions: [
                IconButton(
                    onPressed: () {
                      _logout(snapshot.data['idToken']);
                    },
                    icon: Icon(Icons.logout))
              ], title:
              ListTile(title: Text('歡迎 ${GV.info['name']}'),subtitle:
                Text('登入剩餘時間:'+(DateTime.parse(GV.info['accessTokenExpirationDateTime']).difference(DateTime.now()).inMinutes-10).toString()+'分鐘'))
             ),
              body:
              GridView.builder(
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
                        MaterialPageRoute route;
                        switch (selectfeature[index]) {
                          case ('個人資料'):
                            {
                              route = MaterialPageRoute(
                                  builder: (context) => userinfo());

                              break;
                            }
                          case ('設備盤點'):
                            {
                              route = MaterialPageRoute(
                                  builder: (context) => InventoryList());
                              break;
                            }
                          case ('盤點紀錄'):
                            {
                              route = MaterialPageRoute(
                                  builder: (context) => InventoryRecord());
                              break;
                            }
                          case ('設備狀態異動'):
                            {
                              route = MaterialPageRoute(
                                  builder: (context) => ChangeStatus());

                              break;
                            }
                          case ('狀態異動紀錄'):
                            {
                              route = MaterialPageRoute(
                                  builder: (context) => StatusRecord());

                              break;
                            }
                          case ('新增設備'):
                            {
                              route = MaterialPageRoute(
                                  builder: (context) => additemform());

                              break;
                            }
                          case ('新增設備'):
                            {
                              route = MaterialPageRoute(
                                  builder: (context) => additemform());

                              break;
                            }

                          case ('編輯設備資訊'):
                            {
                              route = MaterialPageRoute(
                                  builder: (context) => editinfolist());

                              break;
                            }

                          case ('新增地點'):
                            {
                              route = MaterialPageRoute(
                                  builder: (context) => addplace());

                              break;
                            }
                          case ('資訊編輯紀錄'):
                            {
                              route = MaterialPageRoute(
                                  builder: (context) => EditinfoRecord());

                              break;
                            }
                        }

                        Navigator.of(context).push(route).then((value) {
                          setState(() {

                          });
                          if(  DateTime.parse(GV.info['accessTokenExpirationDateTime']).difference(DateTime.now()).inSeconds<GV.settimeout){
                            showDialog<String>(
                              barrierDismissible: false,
                              context: context,
                              builder: (BuildContext context) => AlertDialog(
                                title: Text('登入時間逾時 請重新登入'),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () {
                                      _logout(GV.info['idToken']);
                                      Navigator.pop(
                                        context,
                                      );
                                    },
                                    child: Text('確定'),
                                  ),
                                ],
                              ),

                            );
                          }
                        });
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
                onTap: (int index) async {


                  setState(() {
                    _selectedIndex = index;
                  });
                },
              ),
            );
          } else {
            GV.info=null;
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
                          _signInWithAutoCodeExchange();
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
