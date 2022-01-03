import 'package:flutter/material.dart';

import 'GlobalVariable.dart' as GV;

import 'package:intl/intl.dart';

class userinfo extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return userinfostate();
  }
}

class userinfostate extends State<userinfo> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: Text('個人資訊'),
        ),
        body: SingleChildScrollView(
            child: Column(
          children: [
            Card(
              child: ListTile(
                title: Text('姓名'),
                subtitle: Text(GV.info['name']==null?'':GV.info['name']),
              ),
            ),
            Card(
              child: ListTile(
                title: Text('電話'),
                subtitle: Text(GV.info['phone_number']==null?'':GV.info['phone_number']),
              ),
            ),
            Card(
              child: ListTile(
                title: Text('信箱'),
                subtitle: Text(GV.info['email']==null?'':GV.info['email']),
              ),
            ),
            Card(
                child: ListTile(
                    title: Text('美簽到期日'),
                    subtitle: Text(GV.info['US_VISA']==null?'': DateFormat('yyyy-MM-dd')
                        .format(DateTime.parse(GV.info['US_VISA']))))),
            Card(
              child: ListTile(
                title: Text('美簽剩餘天數'),
                subtitle: Text(GV.info['US_VISA']==null?'': DateTime.parse(GV.info['US_VISA'])
                    .difference(DateTime.now())
                    .inDays
                    .toString()),
              ),
            ),
          ],
        )));
  }
}
