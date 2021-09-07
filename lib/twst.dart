import 'package:flutter/material.dart';



/// This is the stateful widget that the main application instantiates.
class abc extends StatefulWidget {
  const abc({Key key}) : super(key: key);

  @override
  State<abc> createState() => _MyStatefulWidgetState();
}

/// This is the private State class that goes with MyStatefulWidget.
class _MyStatefulWidgetState extends State<abc> {
  bool shouldPop = true;
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return shouldPop;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter WillPopScope demo'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              OutlinedButton(
                child: const Text('Push'),
                onPressed: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) {
                        return const abc();
                      },
                    ),
                  );
                },
              ),
              OutlinedButton(
                child: Text('shouldPop: $shouldPop'),
                onPressed: () {
                  setState(
                        () {
                      shouldPop = !shouldPop;
                    },
                  );
                },
              ),
              const Text('Push to a new screen, then tap on shouldPop '
                  'button to toggle its value. Press the back '
                  'button in the appBar to check its behaviour '
                  'for different values of shouldPop'),
            ],
          ),
        ),
      ),
    );
  }
}
