import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'controllers.dart' as GV;

class scanpage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return scanstate();
  }
}

class scanstate extends State<scanpage> {
  setnotify(BluetoothCharacteristic chara) async {
    if (!chara.isNotifying) {
      await chara.setNotifyValue(true);

      chara.value.listen((event) {
        print(event);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BluetoothState>(
        stream: FlutterBlue.instance.state,
        initialData: BluetoothState.unknown,
        builder: (c, snapshot) {
          final state = snapshot.data;
          if (state == BluetoothState.on) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('搜尋裝置'),
              ),
              body: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    FutureBuilder<List<BluetoothDevice>>(
                        future: FlutterBlue.instance.connectedDevices,
                        initialData: [],
                        builder: (c, snapshot) {
                          return Column(
                            children: snapshot.data!.map((d) {
                              return ListTile(
                                title: Text(d.name),
                                subtitle: Text(d.id.toString()),
                                trailing: StreamBuilder<BluetoothDeviceState>(
                                  stream: d.state,
                                  initialData:
                                      BluetoothDeviceState.disconnected,
                                  builder: (c, snapshot) {
                                    if (snapshot.data ==
                                        BluetoothDeviceState.connected) {
                                      return FutureBuilder<
                                          List<BluetoothService>>(
                                        future: d.discoverServices(),
                                        initialData: [],
                                        builder: (c, snapshot) {
                                          if (snapshot.data!.isNotEmpty) {
                                            BluetoothService service = snapshot
                                                .data!
                                                .singleWhere((e) =>
                                                    e.uuid.toString() ==
                                                    '0000ffe0-0000-1000-8000-00805f9b34fb');

                                            BluetoothCharacteristic chara = service
                                                .characteristics
                                                .singleWhere((e) =>
                                                    e.uuid.toString() ==
                                                    '0000ffe1-0000-1000-8000-00805f9b34fb');

                                            return FutureBuilder<bool>(
                                                initialData: false,
                                                future:
                                                    chara.setNotifyValue(true),
                                                builder: (c, snapshot) {
                                                  if (snapshot.data!) {
                                                    return StreamBuilder<
                                                            List<int>>(
                                                        stream: chara.value,
                                                        builder: (c, snapshot) {
                                                          print(snapshot.data);
                                                          return RaisedButton(
                                                            child: const Text(
                                                                '中斷連線'),
                                                            onPressed:
                                                                () async {
                                                              await d
                                                                  .disconnect();
                                                            },
                                                          );
                                                        });
                                                  }
                                                  return const Text('啟用特徵通知');
                                                });
                                          }
                                          return const IconButton(
                                            icon: SizedBox(
                                              child: CircularProgressIndicator(
                                                valueColor:
                                                    AlwaysStoppedAnimation(
                                                        Colors.grey),
                                              ),
                                              width: 18.0,
                                              height: 18.0,
                                            ),
                                            onPressed: null,
                                          );
                                        },
                                      );
                                    } else {
                                      return RaisedButton(
                                        child: const Text('重新連線'),
                                        onPressed: () async {
                                          await d
                                              .connect(
                                                  timeout: const Duration(
                                                      seconds: 5),
                                                  autoConnect: false)
                                              .then((value) => setState(() {}));
                                        },
                                      );
                                    }
                                  },
                                ),
                              );
                            }).toList(),
                          );
                        }),
                    StreamBuilder<List<ScanResult>>(
                        stream: FlutterBlue.instance.scanResults,
                        initialData: [],
                        builder: (c, snapshot) {
                          // snapshot.data!.sort((a,b)=>b.advertisementData.connectable?1:-1);
                          // snapshot.data!.sort((a,b)=>a.device.name.compareTo(b.device.name));
                          return Column(
                            children: snapshot.data!
                                .where((e) => e.advertisementData.connectable)
                                .map((e) => ListTile(
                                    title: Text(e.device.name),
                                    trailing: RaisedButton(
                                      child: const Text('連線'),
                                      onPressed: () async {
                                        try {
                                          await e.device
                                              .connect(
                                                  timeout: const Duration(
                                                      seconds: 5),
                                                  autoConnect: false)
                                              .then((value) => setState(() {}));
                                        } catch (e) {
                                          print(e.toString());
                                        }
                                      },
                                    )))
                                .toList(),
                          );
                        }),
                  ],
                ),
              ),
              floatingActionButton: StreamBuilder<bool>(
                stream: FlutterBlue.instance.isScanning,
                initialData: false,
                builder: (c, snapshot) {
                  if (snapshot.data!) {
                    return FloatingActionButton(
                      child: Icon(Icons.stop),
                      onPressed: () => FlutterBlue.instance.stopScan(),
                      backgroundColor: Colors.red,
                    );
                  } else {
                    return FloatingActionButton(
                        child: Icon(Icons.search),
                        onPressed: () => FlutterBlue.instance
                            .startScan(timeout: Duration(seconds: 3)));
                  }
                },
              ),
            );
          }
          return BluetoothOffScreen(state: state);
        });
  }
}

class BluetoothOffScreen extends StatelessWidget {
  const BluetoothOffScreen({Key? key, this.state}) : super(key: key);

  final BluetoothState? state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.bluetooth_disabled,
              size: 200.0,
              color: Colors.white54,
            ),
            Text(
              'Bluetooth Adapter is ${state != null ? state.toString().substring(15) : 'not available'}.',
            ),
          ],
        ),
      ),
    );
  }
}
