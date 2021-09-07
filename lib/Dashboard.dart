import 'package:flutter/material.dart';
import 'package:identityflutter/Inventorylist.dart';
import 'GlobalVariable.dart' as GV;

class Dashboard extends StatefulWidget {
  const Dashboard({Key key}) : super(key: key);

  @override
  State<Dashboard> createState() => DashboardState();

}


class DashboardState extends State<Dashboard> {

  int _selectedIndex = 0;
  static const TextStyle optionStyle =
  TextStyle(fontSize: 30, fontWeight: FontWeight.bold);
var arr =[['個人資料','隊員管理'],['設備盤點','設備借出','設備報修','新增設備','設備停用'],['盤點紀錄','報修/借出紀錄','新增/停用紀錄','全部紀錄匯出']];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {

    var selectfeature =arr[_selectedIndex];
    bool shouldPop = true;
    return WillPopScope (
      onWillPop: () async {
        return true;
      },
      child:Scaffold(
        appBar: AppBar(
          title:  Text(  '歡迎 ${GV.userinfo.name}'),
        ),
        body:  GridView.builder(
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
                  switch(selectfeature[index]){
                    case('設備盤點'):{
                      Navigator.push(  //從登入push到第二個
                        context,
                        new MaterialPageRoute(builder: (context) => InventoryList()),
                      );
                      break;
                    }
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
              icon: Icon(Icons.inventory_outlined ),
              label: '設備管理',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              label: '紀錄查詢',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.amber[800],
          onTap: _onItemTapped,
        ),
      ),
    );


  }
}
