import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:desktop_window/desktop_window.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:developer';
import 'dart:io' show Platform;

import 'package:motu_simple_control_panel/components/slider_component/slider_widget.dart';
import 'package:motu_simple_control_panel/utils/db_operations.dart';
import 'package:motu_simple_control_panel/components/roundToggleButton.dart';
import 'package:motu_simple_control_panel/components/circleToggleButton.dart';


class ApiPolling {
  String apiBaseUrl;

  ApiPolling(String userApiUrl) {
    this.apiBaseUrl = userApiUrl;
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
    var url = Uri.parse(apiBaseUrl);
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


void setWindow() async {
  // Set initial window size
  await DesktopWindow.setWindowSize(Size(800, 461));
  // Disable resizing
  await DesktopWindow.setMinWindowSize(Size(800,461));
  await DesktopWindow.setMaxWindowSize(Size(800,461));
}


void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    setWindow();
  }

  runApp(MOTUControlPanel());
}


class MOTUControlPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MOTU Control Panel',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
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

  SharedPreferences _prefs;
  String apiBaseUrl;

  getSharedPreferences() async {
    return await SharedPreferences.getInstance();
  }

  Future<void> _showMyDialog(SharedPreferences prefs) async {
    final myController = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Insert your MOTU interface API URL'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('It should look like this:'),
                Text('http://localhost:1280/some-characters/datastore'),
                TextField(
                  controller: myController,
                  decoration: const InputDecoration(
                    hintText: 'URL',
                  ),
                ),

              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Save'),
              onPressed: () {
                if (myController.text.length > 0) {
                  prefs.setString('apiBaseUrl', myController.text);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  // This function will switch on or off only parameters that
  // accept 0.0 or 1.0 as values (Reverb, Mute, Deafen)
  void toggleBoolean(String apiEndpoint, double currentValue) async {
    log('Toggle boolean parameter');
    double newValue = 0.0;
    if (currentValue == 0.0) {
      newValue = 1.0;
    }
    var url = Uri.parse(apiBaseUrl + '/' + apiEndpoint);
    http.Response response = await http.patch(url, body: {'json': '{"value":"$newValue"}'});
    apiPollingInstance.forceUpdate();
  }

  @override
  void initState() {
    super.initState();

    // Get App preferences
    getSharedPreferences().then((prefs) async {
      _prefs = prefs;

      if (prefs.getString('apiBaseUrl') == null) {
        log('Missing apiBaseUrl, request to user...');

        await _showMyDialog(prefs).then((value) {
          apiBaseUrl = prefs.getString('apiBaseUrl');
          setState(() {
            apiPollingInstance = ApiPolling(apiBaseUrl);
            apiPollingStream = apiPollingInstance.stream;
          });
        });
      } else {
        apiBaseUrl = prefs.getString('apiBaseUrl');
        setState(() {
          apiPollingInstance = ApiPolling(apiBaseUrl);
          apiPollingStream = apiPollingInstance.stream;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Color(0xFF0D0D0D),
        padding: EdgeInsets.fromLTRB(40.0, 30, 40.0, 40),
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
                        Text(
                          'Mic',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white
                          ),),
                        SizedBox(width: 14,),
                        CircleToggleButton(
                          label: "",
                          icon: Icons.mic_off,
                          activeColor: Colors.red,
                          inactiveColor: Color(0xFF0D0D0D),
                          active: snapshot.data['mix/chan/1/matrix/mute'] == 1.0 ? true : false,
                          onPressed: () {toggleBoolean('mix/chan/1/matrix/mute', snapshot.data['mix/chan/1/matrix/mute']);},
                        ),
                        SizedBox(width: 14,),
                        RoundToggleButton(
                          label: "Reverb",
                          icon: Icons.animation,
                          activeColor: Colors.white,
                          inactiveColor: Color(0xFF0D0D0D),
                          active: snapshot.data['mix/reverb/0/reverb/enable'] == 1.0 ? true : false,
                          onPressed: () {toggleBoolean('mix/reverb/0/reverb/enable', snapshot.data['mix/reverb/0/reverb/enable']);},
                        )
                      ],
                    ),
                    SizedBox(height: 8),
                    // ==========
                    // MIC VOLUME
                    // ==========
                    SizedBox(
                      width: 700,
                        child:  SliderWidget(
                          sliderHeight: 38,
                          max: faderMax,
                          min: faderMin,
                          fullWidth: true,
                          value: percentageToSliderValue(snapshot.data['mix/chan/1/matrix/fader']),
                          apiUrl: apiBaseUrl +'/'+ 'mix/chan/1/matrix/fader'
                      )
                    ),
                    SizedBox(width: 10, height: 35),


                    // ==========
                    // PC AUDIO BUTTONS
                    // ==========
                    Row(
                      children: [
                        Text(
                          'PC Audio',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white
                          ),),
                        SizedBox(width: 14,),
                        CircleToggleButton(
                          label: "",
                          icon: Icons.headset_off,
                          activeColor: Colors.red,
                          inactiveColor: Color(0xFF0D0D0D),
                          active: snapshot.data['mix/chan/20/matrix/mute'] == 1.0 ? true : false,
                          onPressed: () {toggleBoolean('mix/chan/20/matrix/mute', snapshot.data['mix/chan/20/matrix/mute']);},
                        ),
                        SizedBox(width: 14,),
                        RoundToggleButton(
                          label: "Comms",
                          icon: Icons.arrow_right_alt,
                          activeColor: Colors.white,
                          inactiveColor: Color(0xFF0D0D0D),
                          active: snapshot.data['mix/chan/20/matrix/aux/0/send'] > 0.0 ? true : false,
                          onPressed: () {toggleBoolean('mix/chan/20/matrix/aux/0/send', snapshot.data['mix/chan/20/matrix/aux/0/send']);},
                        )
                      ],
                    ),
                    SizedBox(height: 8),
                    // ==========
                    // PC AUDIO VOLUME
                    // ==========
                    SizedBox(
                        width: 700,
                        child:  SliderWidget(
                            sliderHeight: 38,
                            max: faderMax,
                            min: faderMin,
                            fullWidth: true,
                            value: percentageToSliderValue(snapshot.data['mix/chan/20/matrix/fader']),
                            apiUrl: apiBaseUrl +'/'+ 'mix/chan/20/matrix/fader'
                        )
                    ),
                    SizedBox(width: 10, height: 35),


                    // ==========
                    // CHAT BUTTONS
                    // ==========
                    Row(
                      children: [
                        Text(
                          'Chat',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white
                          ),),
                        SizedBox(width: 14,),
                        CircleToggleButton(
                          label: "",
                          icon: Icons.headset_off,
                          activeColor: Colors.red,
                          inactiveColor: Color(0xFF0D0D0D),
                          active: snapshot.data['mix/chan/24/matrix/mute'] == 1.0 ? true : false,
                          onPressed: () {toggleBoolean('mix/chan/24/matrix/mute', snapshot.data['mix/chan/24/matrix/mute']);},
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    // ==========
                    // CHAT VOLUME
                    // ==========
                    SizedBox(
                        width: 700,
                        child:  SliderWidget(
                            sliderHeight: 38,
                            max: faderMax,
                            min: faderMin,
                            fullWidth: true,
                            value: percentageToSliderValue(snapshot.data['mix/chan/24/matrix/fader']),
                            apiUrl: apiBaseUrl +'/'+ 'mix/chan/24/matrix/fader'
                        )
                    ),

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
                  mainAxisSize: MainAxisSize.min,
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