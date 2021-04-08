import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:developer';

import './slider_component/slider_widget.dart';
import 'utils/db_operations.dart';


// MOTU interface URL (keep the /datastore, it's the API)
const String API_URL = 'http://localhost:1280/0001f2fffe012d80/datastore';


class ApiPolling {
  ApiPolling() {
    fetchApi();
    Timer.periodic(Duration(seconds: 15), (timer) {
      fetchApi();
    });
  }

  var apiETag = "0";
  var datastore = {};
  final _controller = StreamController<Map<String, dynamic>>();

  void fetchApi() async {
    // API request. Sending the ETag is needed to get only values that changed between requests
    var url = Uri.parse(API_URL);
    http.Response response = await http.get(url, headers:{ 'If-None-Match': apiETag });
    log("ApiPolling status code: ${response.statusCode}");

    // 304 means no updates since last time you checked, so return the data we already have
    if (response.statusCode == 304) {
      return;
    }
    final parsed = jsonDecode(response.body);

    // Update stored ETag that later will be sent to the API for updates check
    apiETag = response.headers['etag'];

    // Merge incoming updates into datastore overwriting existing matching keys
    Map<String, dynamic> combinedMap = {
      ...datastore,
      ...parsed
    };
    datastore = combinedMap;

    // Push the
    _controller.sink.add(combinedMap);
    return;
  }

  Stream<Map<String, dynamic>> get stream => _controller.stream;
}


void main() {
  runApp(MOTUControlPanel());
}


class MOTUControlPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MainPage(
          title: 'Flutter Demo Home Page',
      ),
    );
  }
}


class MainPage extends StatefulWidget {
  MainPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MainPageState createState() => _MainPageState();
}


class _MainPageState extends State<MainPage> {
  Stream mystream;



  @override
  void initState() {
    super.initState();
    mystream = ApiPolling().stream;
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
            stream: mystream,
            builder: (BuildContext context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
              List<Widget> children;
              if (snapshot.hasError) {
                children = [
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
                    children = const [];
                    break;
                  case ConnectionState.waiting:
                    children = const [
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
                    children = [
                      const Icon(
                        Icons.check_circle_outline,
                        color: Colors.green,
                        size: 60,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text("ACTIVE - ${snapshot.data['mix/chan/2/matrix/mute']}"),
                        // child: Text("ACTIVE - ${snapshot.data}"),
                      )
                    ];
                    break;
                  case ConnectionState.done:
                    children = [
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