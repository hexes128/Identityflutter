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

class InventoryListState extends State<InventoryList>
    with TickerProviderStateMixin {
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
    PlaceList = _callApi();
    tabController = TabController(length: 0, vsync: this);
  }

  Future<List<dynamic>> PlaceList;
  bool allChecked = false;
  List<dynamic> AreaList;
  int Areaindex = 0;
  int Placeindex = 0;
  var status = ['正常', '借出', '報修', '停用'];
  TabController tabController;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: PlaceList,
      builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.hasData) {
          AreaList = snapshot.data[Placeindex]['priorityList'];
          AreaList.sort((a, b) => a['priorityNum'].compareTo(b['priorityNum']));
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
              title: Text(snapshot.data[Placeindex]['placeName'] +
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
                    if (Placeindex != index) {
                      setState(() {
                        Placeindex = index;
                        tabController.animateTo(0);
                      });
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
            body: TabBarView(
                controller: tabController,
                children: AreaList.map((e) => ListView.builder(
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
                          ),
                          title: Text(
                              Fireitem['itemId'] + ' ' + Fireitem['itemName']),
                          subtitle:
                              Text('當前狀態:' + status[Fireitem['presentStasus']]),
                          onTap: () => {
                            setState(() {
                              Fireitem['ischeck'] = !Fireitem['ischeck'];
                            })
                          },
                        );
                      },
                    )).toList()),
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
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

const List<String> tabNames = const <String>[
  'foo',
  'bar',
  'baz',
  'quox',
  'quuz',
  'corge',
  'grault',
  'garply',
  'waldo'
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
              case 0:
                return new Center(
                  child: new Text('First screen, ${tabNames[index]}'),
                );
              case 1:
                return new Center(
                  child: new Text('Second screen'),
                );
            }
          }),
        ),
        bottomNavigationBar: new Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            new AnimatedCrossFade(
              firstChild: new Material(
                color: Theme.of(context).primaryColor,
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
