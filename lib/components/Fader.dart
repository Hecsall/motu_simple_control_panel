import 'dart:math';
import 'package:flutter/material.dart';
import 'package:motu_simple_control_panel/utils/db_operations.dart';
import 'package:http/http.dart' as http;

import 'package:motu_simple_control_panel/components/fader_components/custom_slider_thumb_circle.dart';

import 'fader_components/FaderTrackShape.dart';


class Fader extends StatefulWidget {
  final double sliderHeight;
  final double min;
  final double max;
  double value;
  String apiUrl;

  Fader({
    this.sliderHeight = 48,
    this.max = 10,
    this.min = 0,
    this.value = 0,
    this.apiUrl
  });

  @override
  _FaderState createState() => _FaderState();
}

class _FaderState extends State<Fader> {

  void setVolume(double value) async {
    var url = Uri.parse(widget.apiUrl);
    double percentage = sliderValueToPercentage(value);
    await http.patch(url, body: {'json': '{"value":"$percentage"}'});
  }

  @override
  Widget build(BuildContext context) {

    Widget slider = Slider(
      value: widget.value,
      divisions: 24,

      onChanged: (value) {
        setVolume(value);
        setState(() {
          widget.value = value;
        });
      },
    );

    return SizedBox(
        width: 100,
        child:  Column(
          children: [
            SizedBox(
              height: this.widget.sliderHeight,
              child: RotatedBox(
                quarterTurns: 3,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Color(0xFFFF0000),
                    inactiveTrackColor: Color(0XFF111111),
                    trackHeight: 5,
                    trackShape: FaderTrackShape(),
                    thumbShape: CustomSliderThumbCircle(
                      thumbRadius: 15,
                    ),
                    overlayColor: Colors.white.withOpacity(.1),
                    // activeTickMarkColor: Colors.white,
                    // inactiveTickMarkColor: Colors.white.withOpacity(.4),
                    tickMarkShape: SliderTickMarkShape.noTickMark
                  ),
                  child: slider,
                ),
              ),
            ),

            SizedBox(height: 5,),

            // Slider Value
            Text(
                ((percentageToDb(sliderValueToPercentage(this.widget.value)) * pow(10.0, 1)).round().toDouble() / pow(10.0, 1)).toString() + ' dB',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                )
            )

        ],
      )
    );

    /*
    return Container(
      width: this.widget.fullWidth ? double.infinity : (this.widget.sliderHeight) * 5.5,
      height: (this.widget.sliderHeight),
      decoration: new BoxDecoration(
        borderRadius: new BorderRadius.all(
          Radius.circular((this.widget.sliderHeight * .5)),
        ),
        color: Colors.blue
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(this.widget.sliderHeight * paddingFactor,
            2, this.widget.sliderHeight * paddingFactor, 2),
        child: Row(
          children: <Widget>[
            Text(
              'dB', // '${this.widget.min}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: this.widget.sliderHeight * .35,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            SizedBox(
              width: this.widget.sliderHeight * .1,
            ),
            Expanded(
              child: Center(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.white.withOpacity(1),
                    inactiveTrackColor: Colors.white.withOpacity(.5),

                    trackHeight: 0.0,
                    thumbShape: CustomSliderThumbCircle(
                      thumbRadius: this.widget.sliderHeight * .5,
                      min: this.widget.min,
                      max: this.widget.max,
                    ),
                    overlayColor: Colors.white.withOpacity(.4),
                    activeTickMarkColor: Colors.white,
                    inactiveTickMarkColor: Colors.white.withOpacity(.4),
                    tickMarkShape: RoundSliderTickMarkShape(tickMarkRadius: 3, )
                  ),
                  child: Slider(
                      value: widget.value,
                      divisions: 24,
                      onChanged: (value) {
                        setVolume(value);
                        setState(() {
                          widget.value = value;
                        });
                      },
                    ),
                ),

              ),
            ),
            SizedBox(
              width: this.widget.sliderHeight * .1,
            ),

            // Text(
            //   '${this.widget.max}',
            //   textAlign: TextAlign.center,
            //   style: TextStyle(
            //     fontSize: this.widget.sliderHeight * .3,
            //     fontWeight: FontWeight.w700,
            //     color: Colors.white,
            //   ),
            // ),

          ],
        ),
      ),
    );
  */
  }
}