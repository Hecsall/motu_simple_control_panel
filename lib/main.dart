import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import './slider_component/slider_widget.dart';
import 'utils/db_operations.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(
          title: 'Flutter Demo Home Page',
      ),
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

  Map<String, dynamic> datastore = {};
  String apiETag;

  Future<Map<String, dynamic>> fetchApi() async {
    var url = Uri.parse('http://localhost:1280/0001f2fffe012d80/datastore');
    http.Response response = await http.get(url, headers:{ 'If-None-Match': apiETag });
    print(response.statusCode);
    if (response.statusCode == 304) {
      return datastore;
    }
    final parsed = jsonDecode(response.body);

    apiETag = response.headers['etag'];

    // Merge incoming updates into datastore overwriting existing keys
    List mapList = [datastore, parsed];
    Map<String, dynamic> combinedMap = mapList.reduce( (map1, map2) => map1..addAll(map2) );
    datastore = combinedMap;
    return combinedMap;
  }

  Stream<Map<String, dynamic>> apiUpdateStream() async* {
    yield* Stream.periodic(Duration(seconds: 15), (_) {
      return fetchApi();
    }).asyncMap((value) async => await value);
  }

  double _getMicVolume(fader) {
    double percentage = datastore[fader] != null ? datastore[fader] : 0.5;
    return percentageToSliderValue(percentage);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          StreamBuilder<Map<String, dynamic>>(
            stream: apiUpdateStream(),
            builder: (BuildContext context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
              List<Widget> children;
              if (snapshot.hasError) {
                children = <Widget>[
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 60,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text('Error: ${snapshot.error}'),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('Stack trace: ${snapshot.stackTrace}'),
                  ),
                ];
              } else {
                switch (snapshot.connectionState) {
                  case ConnectionState.none:
                    children = const <Widget>[];
                    break;
                  case ConnectionState.waiting:
                    children = const <Widget>[
                      SizedBox(
                        child: CircularProgressIndicator(),
                        width: 60,
                        height: 60,
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Text('Waiting...'),
                      )
                    ];
                    break;
                  case ConnectionState.active:
                    children = <Widget>[
                      const Icon(
                        Icons.check_circle_outline,
                        color: Colors.green,
                        size: 60,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text("ACTIVE - ${snapshot.data['mix/chan/1/matrix/mute']}"),
                        // child: Text("ACTIVE - ${snapshot.data}"),
                      )
                    ];
                    break;
                  case ConnectionState.done:
                    children = <Widget>[
                      const Icon(
                        Icons.info,
                        color: Colors.blue,
                        size: 60,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text('${snapshot.data} (closed)'),
                      )
                    ];
                    break;
                }
              }

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: children,
              );
            },
          )
        ],
      ),


    );
  }
}