import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:identityflutter/GlobalVariable.dart' as GV;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class InventoryList extends StatefulWidget {
  InventoryList({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => InventoryListState();
}

class InventoryListState extends State<InventoryList> {


  Future<List<dynamic>> _callApi() async {
    var access_token = GV.tokenResponse.accessToken;

    try {
      var response = await http
          .get(Uri(scheme: 'http', host: '192.168.10.152', port: 81, path: 'Item/GetItem'), headers: {"Authorization": "Bearer $access_token"});
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
PlaceList=_callApi();
  }
Future<List<dynamic>>PlaceList;
  bool allChecked = false;
List<dynamic> AreaList;

 int Placeindex =0;
var status =['正常','借出','報修','停用'];
  @override
  Widget build(BuildContext context) {

    return FutureBuilder<List<dynamic>>(
        future:PlaceList, // a previously-obtained Future<String> or null

        builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {

          if (snapshot.hasData) {
AreaList= snapshot.data[Placeindex]['priorityList'];
AreaList.sort((a,b)=>a['priorityNum'] .compareTo(a['priorityNum']) );

            return DefaultTabController(
              initialIndex: 0,
              length:AreaList.length,
              child:

              Scaffold(
                appBar: AppBar(
                  title: Text('設備清單 '+snapshot.data[Placeindex]['placeName']),
                  actions: [PopupMenuButton(
                    onSelected: (int index){
                      setState(() {
                        Placeindex=index;
                      });
                    },
                    icon: Icon(Icons.more_vert),
                    itemBuilder: (BuildContext context) =>
                    snapshot.data.map((e) => PopupMenuItem(child: Text(e['placeName']),value: snapshot.data.indexOf(e),)).toList()
                    // <PopupMenuEntry>[
                    //
                    //   const PopupMenuItem(child: Text('Item A')),
                    //
                    // ],
                  ),],

                ),
                body: TabBarView(
                    children:

                 AreaList.map((e) =>ListView.builder(
                   itemCount: e['fireitemList'].length,
                   itemBuilder: (context, index) {
                     var Fireitem = e['fireitemList'][index];
                     return ListTile(
                       leading: Checkbox(
                         checkColor: Colors.white,
                         value: Fireitem['ischeck'],
                         onChanged: (bool value) {
                           setState(() {
                             Fireitem['ischeck'] = value;
                           });
                         },
                       ) ,
                       title:
                       Text(Fireitem['itemId'] + ' ' + Fireitem['itemName']),
                       subtitle:
                       Text('當前狀態:' + status[Fireitem['presentStasus']]),
                       onTap: () => {
                         setState(() {
                           Fireitem['ischeck'] =! Fireitem['ischeck'] ;
                         })
                       },

                     );
                   },
                 ) ).toList()


                ),
                bottomNavigationBar:    new Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                     Material(
                      color: Theme.of(context).primaryColor,
                      child:  TabBar(
                        indicatorColor: Colors.black,

                       labelColor: Colors.black,
                      unselectedLabelColor: Colors.white,
                        isScrollable: true,
                        tabs:AreaList.map((e) => Tab(text: e['subArea'])).toList()
                      ),
                    ),

                     BottomNavigationBar(

                      currentIndex: Placeindex,
                      onTap: (int index) {
                        setState(() {
                          Placeindex = index;
                        });
                      },
                      items:
                        snapshot.data.map((e) =>

                            BottomNavigationBarItem(
                              icon: new Icon(Icons.location_on),
                              title: new Text(   e['placeName']),
                            )
                     ).toList()

                    ),
                  ],
                ),
              ),
            );
          } else if (snapshot.hasError) {
         return Text('錯誤');
          } else {
            return Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(20.0),
                child:

                Center(child:    Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[

                    Text(
                      '資料讀取中',
                      style: Theme.of(context).textTheme.headline6,
                    ),
                    CircularProgressIndicator(


                    ),
                  ],
                ),)

              ),
            );
          }

        },
      );



  }
}



class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

const List<String> tabNames = const<String>[
  'foo', 'bar', 'baz', 'quox', 'quuz', 'corge', 'grault', 'garply', 'waldo'
];

class _MyHomePageState extends State<MyHomePage> {

  int _screen = 0;

  @override
  Widget build(BuildContext context) {
    return new DefaultTabController(
      length: tabNames.length,
      child: new Scaffold(
        appBar: new AppBar(
          title: new Text('Navigation example'),
        ),
        body: new TabBarView(
          children: new List<Widget>.generate(tabNames.length, (int index) {
            switch (_screen) {
              case 0: return new Center(
                child: new Text('First screen, ${tabNames[index]}'),
              );
              case 1: return new Center(
                child: new Text('Second screen'),
              );
            }
          }),
        ),
        bottomNavigationBar:

        new Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            new AnimatedCrossFade(
              firstChild: new Material(
                color: Theme
                    .of(context)
                    .primaryColor,
                child: new TabBar(
                  isScrollable: true,
                  tabs: new List.generate(tabNames.length, (index) {
                    return new Tab(text: tabNames[index].toUpperCase());
                  }),
                ),
              ),
              secondChild: new Container(),
              crossFadeState: _screen == 0
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              duration: const Duration(milliseconds: 300),
            ),
            new BottomNavigationBar(
              currentIndex: _screen,
              onTap: (int index) {
                setState(() {
                  _screen = index;
                });
              },
              items: [
                new BottomNavigationBarItem(
                  icon: new Icon(Icons.airplanemode_active),
                  title: new Text('Airplane'),
                ),
                new BottomNavigationBarItem(
                  icon: new Icon(Icons.motorcycle),
                  title: new Text('Motorcycle'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
