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
      home: MyHomePage(title: 'Flutter Demo Home Page'),
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
  String reverbStatus;
  String apiBase = 'http://localhost:1280/0001f2fffe012d80/datastore';


  Map<String, dynamic> datastore = {};

  List<dynamic> tracks = [
    {
      // Mic 2
      'name': 'Mic 2',
      'mute': 'mix/chan/1/matrix/mute',
      'volume': 'mix/chan/1/matrix/fader',
    },
    {
      // PC Chat
      'name': 'PC Chat',
      'mute': 'mix/chan/24/matrix/mute',
      'volume': 'mix/chan/24/matrix/fader',
    },
    {
      // Reverb
      'name': 'Reverb',
      'status': 'mix/reverb/0/reverb/enable',
      'volume': 'mix/reverb/0/matrix/fader'
    },
  ];

  Map<String, String> apiEndpoints = {
    'mic2Mute': 'mix/chan/1/matrix/mute',
    'reverb': 'mix/reverb/0/reverb/enable',
    'chatVolume': 'mix/chan/24/matrix/fader', // In percentage 0.5 -> -6db
  };

  _getDatastore(String ip) async {
    var url = Uri.parse(ip);
    http.Response response = await http.get(url);
    final parsed = jsonDecode(response.body);

    setState(() {
      datastore = parsed;
    });
  }

  double _getMicVolume(fader) {
    double percentage = datastore[fader] != null ? datastore[fader] : 0.5;
    return percentageToSliderValue(percentage);
  }

  @override
  void initState() {
    super.initState();
    _getDatastore(apiBase);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: tracks.map((track) {

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [

              Padding(
                padding: EdgeInsets.all(20),
                child: Text('Mute'),
              ),


              Expanded(
                child: SliderWidget(
                    sliderHeight: 48,
                    max: faderMax,
                    min: faderMin,
                    fullWidth: true,
                    value: _getMicVolume(track['volume']),
                    apiUrl: apiBase+'/'+track['volume']
                ),
              ),

              // Text('Reverb Status: $reverbStatus'),
            ],
          );

        }).toList(),
      ),


    );
  }
}

