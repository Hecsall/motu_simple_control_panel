import 'dart:convert';
import 'dart:async';
import 'dart:developer';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:desktop_window/desktop_window.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_size/window_size.dart';

import 'package:motu_simple_control_panel/components/Fader.dart';
import 'package:motu_simple_control_panel/components/IconToggleButton.dart';
import 'package:motu_simple_control_panel/utils/db_operations.dart';


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

    // Push the updated datastore
    _controller.sink.add(combinedMap);
    return;
  }

  void closeStream() {
    _controller.close();
  }

  Stream<Map<String, dynamic>> get stream => _controller.stream;
}


void setWindow() async {
  // Set window title
  setWindowTitle("MOTU Simple Control Panel");
  // Set initial window size
  await DesktopWindow.setWindowSize(Size(500, 830));
  // // Disable resizing
  setWindowMinSize(const Size(500, 830));
  setWindowMaxSize(const Size(500, 830));
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
        primarySwatch: Colors.red,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Color(0xFF1F2022)
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

  String apiBaseUrl;

  getSharedPreferences() async {
    return await SharedPreferences.getInstance();
  }

  Future<void> _showMyDialog(SharedPreferences prefs) async {
    final myController = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
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
    await http.patch(url, body: {'json': '{"value":"$newValue"}'});
    apiPollingInstance.forceUpdate();
  }

  @override
  void initState() {
    super.initState();

    // Get App preferences
    getSharedPreferences().then((prefs) async {
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
  void dispose() {
    super.dispose();
    apiPollingInstance.closeStream();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.fromLTRB(40.0, 40.0, 40.0, 10),
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
                    ),
                    SizedBox(height: 20,),
                    Text('Connecting to MOTU', style: TextStyle(color: Colors.white),)
                  ];
                  break;
                case ConnectionState.active:
                  children = [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(0,0,0,40),
                          child: SvgPicture.asset(
                            'assets/motu-logo.svg',
                            width: 120,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // COL MIC 1
                        Column(
                          children: [
                            Text(
                              'Mic 1',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 10),
                            IconToggleButton(
                              label: "",
                              icon: Icons.mic_off,
                              activeColor: Color(0xFFFF0000),
                              inactiveColor: Color(0xFF939393),
                              active: snapshot.data['mix/chan/0/matrix/mute'] == 1.0 ? true : false,
                              onPressed: () {toggleBoolean('mix/chan/0/matrix/mute', snapshot.data['mix/chan/0/matrix/mute']);},
                            ),
                            Fader(
                              sliderHeight: 440,
                              max: faderMax,
                              min: faderMin,
                              value: percentageToSliderValue(snapshot.data['mix/chan/0/matrix/fader']),
                              apiUrl: apiBaseUrl +'/'+ 'mix/chan/0/matrix/fader'
                            ),

                          ],
                        ),

                        // COL MIC 2
                        Column(
                          children: [
                            Text(
                              'Mic 2',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 10),
                            IconToggleButton(
                              label: "",
                              icon: Icons.mic_off,
                              activeColor: Color(0xFFFF0000),
                              inactiveColor: Color(0xFF939393),
                              active: snapshot.data['mix/chan/1/matrix/mute'] == 1.0 ? true : false,
                              onPressed: () {toggleBoolean('mix/chan/1/matrix/mute', snapshot.data['mix/chan/1/matrix/mute']);},
                            ),
                            Fader(
                              sliderHeight: 440,
                              max: faderMax,
                              min: faderMin,
                              value: percentageToSliderValue(snapshot.data['mix/chan/1/matrix/fader']),
                              apiUrl: apiBaseUrl +'/'+ 'mix/chan/1/matrix/fader'
                            ),
                            SizedBox(height: 20),
                            IconToggleButton(
                              label: "",
                              icon: Icons.animation,
                              activeColor: Color(0xFFFFFFFF),
                              inactiveColor: Color(0xFF939393),
                              active: snapshot.data['mix/reverb/0/reverb/enable'] == 1.0 ? true : false,
                              onPressed: () {toggleBoolean('mix/reverb/0/reverb/enable', snapshot.data['mix/reverb/0/reverb/enable']);},
                            )
                          ],
                        ),

                        // COL PC AUDIO
                        Column(
                          children: [
                            Text(
                              'PC Audio',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 10),
                            IconToggleButton(
                              label: "",
                              icon: Icons.headset_off,
                              activeColor: Color(0xFFFF0000),
                              inactiveColor: Color(0xFF939393),
                              active: snapshot.data['mix/chan/20/matrix/mute'] == 1.0 ? true : false,
                              onPressed: () {toggleBoolean('mix/chan/20/matrix/mute', snapshot.data['mix/chan/20/matrix/mute']);},
                            ),
                            Fader(
                              sliderHeight: 440,
                              max: faderMax,
                              min: faderMin,
                              value: percentageToSliderValue(snapshot.data['mix/chan/20/matrix/fader']),
                              apiUrl: apiBaseUrl +'/'+ 'mix/chan/20/matrix/fader'
                            ),
                            SizedBox(height: 20),
                            IconToggleButton(
                              label: "",
                              icon: Icons.headset,
                              activeColor: Color(0xFFFFFFFF),
                              inactiveColor: Color(0xFF939393),
                              active: snapshot.data['mix/chan/20/matrix/main/0/send'] > 0.0 ? true : false,
                              onPressed: () {toggleBoolean('mix/chan/20/matrix/main/0/send', snapshot.data['mix/chan/20/matrix/main/0/send']);},
                            ),
                            IconToggleButton(
                              label: "",
                              icon: Icons.speaker,
                              activeColor: Color(0xFFFFFFFF),
                              inactiveColor: Color(0xFF939393),
                              active: snapshot.data['mix/chan/20/matrix/group/0/send'] > 0.0 ? true : false,
                              onPressed: () {toggleBoolean('mix/chan/20/matrix/group/0/send', snapshot.data['mix/chan/20/matrix/group/0/send']);},
                            ),
                            IconToggleButton(
                              label: "",
                              icon: Icons.arrow_right_alt,
                              activeColor: Color(0xFFFFFFFF),
                              inactiveColor: Color(0xFF939393),
                              active: snapshot.data['mix/chan/20/matrix/aux/0/send'] > 0.0 ? true : false,
                              onPressed: () {toggleBoolean('mix/chan/20/matrix/aux/0/send', snapshot.data['mix/chan/20/matrix/aux/0/send']);},
                            )

                          ],
                        ),

                        // COL CHAT
                        Column(
                          children: [
                            Text(
                              'Chat',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 10),
                            IconToggleButton(
                              label: "",
                              icon: Icons.headset_off,
                              activeColor: Color(0xFFFF0000),
                              inactiveColor: Color(0xFF939393),
                              active: snapshot.data['mix/chan/24/matrix/mute'] == 1.0 ? true : false,
                              onPressed: () {toggleBoolean('mix/chan/24/matrix/mute', snapshot.data['mix/chan/24/matrix/mute']);},
                            ),
                            Fader(
                              sliderHeight: 440,
                              max: faderMax,
                              min: faderMin,
                              value: percentageToSliderValue(snapshot.data['mix/chan/24/matrix/fader']),
                              apiUrl: apiBaseUrl +'/'+ 'mix/chan/24/matrix/fader'
                            ),
                            SizedBox(height:20),
                            IconToggleButton(
                              label: "Headphones",
                              icon: Icons.headset,
                              activeColor: Color(0xFFFFFFFF),
                              inactiveColor: Color(0xFF939393),
                              active: snapshot.data['mix/chan/24/matrix/main/0/send'] > 0.0 ? true : false,
                              onPressed: () {toggleBoolean('mix/chan/24/matrix/main/0/send', snapshot.data['mix/chan/24/matrix/main/0/send']);},
                            ),
                            IconToggleButton(
                              label: "Speaker",
                              icon: Icons.speaker,
                              activeColor: Color(0xFFFFFFFF),
                              inactiveColor: Color(0xFF939393),
                              active: snapshot.data['mix/chan/24/matrix/group/0/send'] > 0.0 ? true : false,
                              onPressed: () {toggleBoolean('mix/chan/24/matrix/group/0/send', snapshot.data['mix/chan/24/matrix/group/0/send']);},
                            ),
                          ],
                        ),
                      ],
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
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: children,
                  ),
                )
              ],
            );
          },
        ),
      ),


    );
  }
}