import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:developer';

import './slider_component/slider_widget.dart';
import 'utils/db_operations.dart';
import 'package:motu_simple_control_panel/components/roundToggleButton.dart';
import 'package:motu_simple_control_panel/components/circleToggleButton.dart';


// MOTU interface URL (keep the /datastore, it's the API)
const String API_URL = 'http://localhost:1280/0001f2fffe012d80/datastore';


class ApiPolling {
  ApiPolling() {
    fetchApi();
    Timer.periodic(Duration(seconds: 15), (timer) {
      fetchApi();
    });
  }

  forceUpdate() {
    log('Forcing Stream Update');
    fetchApi();
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
      title: 'MOTU Control Panel',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MainPage(
          title: 'MOTU Control Panel',
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
  ApiPolling apiPollingInstance;
  Stream apiPollingStream;

  // This function will switch on or off only parameters that
  // accept 0.0 or 1.0 as values (Reverb, Mute, Deafen)
  void toggleBoolean(String apiEndpoint, double currentValue) async {
    print('Toggle boolean parameter');
    double newValue = 0.0;
    if (currentValue == 0.0) {
      newValue = 1.0;
    }
    var url = Uri.parse(API_URL + '/' + apiEndpoint);
    http.Response response = await http.patch(url, body: {'json': '{"value":"$newValue"}'});
    apiPollingInstance.forceUpdate();
  }

  void _sliderValueFromApi(String apiEndpoint) async {

  }

  @override
  void initState() {
    super.initState();
    apiPollingInstance = ApiPolling();
    apiPollingStream = apiPollingInstance.stream;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text(widget.title),
      // ),
      body: Container(
        padding: EdgeInsets.all(40.0),
        child: StreamBuilder<Map<String, dynamic>>(
          stream: apiPollingStream,
          builder: (BuildContext context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
            List<Widget> children;
            if (snapshot.hasError) {
              children = [
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text('Error: ${snapshot.error}'),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Stack trace: ${snapshot.stackTrace}'),
                ),
              ];
            }
            else {
              switch (snapshot.connectionState) {
                case ConnectionState.none:
                  children = [];
                  break;
                case ConnectionState.waiting:
                  children = [
                    SizedBox(
                      child: CircularProgressIndicator(),
                      width: 60,
                      height: 60,
                    )
                  ];
                  break;
                case ConnectionState.active:
                  children = [
                    // ==========
                    // MIC BUTTONS
                    // ==========
                    Row(
                      children: [
                        Text('Mic', style: Theme.of(context).textTheme.headline5,),
                        SizedBox(width: 14,),
                        CircleToggleButton(
                          label: "",
                          icon: Icons.mic_off,
                          activeColor: Colors.red,
                          inactiveColor: Colors.white,
                          active: snapshot.data['mix/chan/1/matrix/mute'] == 1.0 ? true : false,
                          onPressed: () {toggleBoolean('mix/chan/1/matrix/mute', snapshot.data['mix/chan/1/matrix/mute']);},
                        ),
                        SizedBox(width: 14,),
                        RoundToggleButton(
                          label: "Reverb",
                          icon: Icons.animation,
                          activeColor: Colors.black,
                          inactiveColor: Colors.white,
                          active: snapshot.data['mix/reverb/0/reverb/enable'] == 1.0 ? true : false,
                          onPressed: () {toggleBoolean('mix/reverb/0/reverb/enable', snapshot.data['mix/reverb/0/reverb/enable']);},
                        )
                      ],
                    ),
                    SizedBox(height: 10,),
                    // ==========
                    // MIC VOLUME
                    // ==========
                    SizedBox(
                      width: 700,
                        child:  SliderWidget(
                          sliderHeight: 48,
                          max: faderMax,
                          min: faderMin,
                          fullWidth: true,
                          value: percentageToSliderValue(snapshot.data['mix/chan/1/matrix/fader']),
                          apiUrl: API_URL +'/'+ 'mix/chan/1/matrix/fader'
                      )
                    ),



                    SizedBox(width: 10, height: 35),

                  ];
                  break;
                case ConnectionState.done:
                // Since we are Long Polling, connection will never be "done".
                  children = [];
                  break;
              }
            }

            return Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children,
                ),
              ],
            );
          },
        ),
      ),


    );
  }
}