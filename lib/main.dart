import 'dart:async';
import 'dart:convert';
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
  var logouturl;

  Future<int> _auth() async {
    var uri = new Uri(scheme: "http", host: "140.133.78.44", port: 82);
    try {
      var issuer = await Issuer.discover(uri);
      var client = new Client(issuer, "flutter");

      var authenticator = new Authenticator(client,
          scopes: ['profile', 'openid', 'IdentityServerApi', 'API', 'email'],
          port: 4000,
          urlLancher: urlLauncher);

      var c = await authenticator.authorize();

      GV.tokenResponse = await c.getTokenResponse();

      try {
        GV.userinfo = await c.getUserInfo();
        Credential credential = client.createCredential(
            accessToken: GV.tokenResponse.accessToken,
            idToken: GV.tokenResponse.idToken.toCompactSerialization());
        logouturl = credential
            .generateLogoutUrl(
                redirectUri: Uri(scheme: 'http', host: 'localhost', port: 4000))
            .toString(); //獲取登出網址
          return 0; //登入成功並獲取userinfo
      } catch (e) {
       return 1; //取消登入
      }


    } catch (error) {

      return 2; //超時

    }
  }

  Future<void> _logout() async {
    if (await canLaunch(logouturl)) {
      await launch(logouturl, forceWebView: true, enableJavaScript: true);
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
                  color: Colors.blue, borderRadius: BorderRadius.circular(20)),
              child: FlatButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => FutureProgressDialog(
                        _auth().then((value) {
                          closeWebView();

                          switch(value){
                            case(0):{
                              Fluttertoast.showToast(
                                  msg: '已取消登入',
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.BOTTOM,
                                  timeInSecForIosWeb: 1,
                                  backgroundColor: Colors.blue,
                                  textColor: Colors.white,
                                  fontSize: 16.0);
                              Navigator.push(  //從登入push到第二個
                                context,
                                new MaterialPageRoute(builder: (context) => Dashboard()),
                              );
                              break;
                            }
                            case(1):{
                              Fluttertoast.showToast(
                                  msg: '已取消登入',
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.BOTTOM,
                                  timeInSecForIosWeb: 1,
                                  backgroundColor: Colors.blue,
                                  textColor: Colors.white,
                                  fontSize: 16.0);
                              break;
                            }
                            case(2):{
                              Fluttertoast.showToast(
                                  msg: '連線超時，請檢查網路狀況，或是與開發者聯絡',
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.BOTTOM,
                                  timeInSecForIosWeb: 1,
                                  backgroundColor: Colors.blue,
                                  textColor: Colors.white,
                                  fontSize: 16.0);
                              break;
                            }

                          }

                        }
                          ),
                        message: Text('資料處理中，請稍後')),
                  );
                },
                child: Text(
                  '登入',
                  style: TextStyle(color: Colors.white, fontSize: 25),
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(vertical: 20.0),
              height: 50,
              width: 250,
              decoration: BoxDecoration(
                  color: Colors.blue, borderRadius: BorderRadius.circular(20)),
              child: FlatButton(
                onPressed: () {
                  _logout();
                  Timer(const Duration(seconds: 1), () {
                    print('Closing WebView after 5 seconds...');
                    closeWebView();
                  });
                },
                child: Text(
                  '登出',
                  style: TextStyle(color: Colors.white, fontSize: 25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
