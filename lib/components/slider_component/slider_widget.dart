import 'package:flutter/material.dart';
import 'package:motu_simple_control_panel/utils/db_operations.dart';
import 'custom_slider_thumb_circle.dart';
import 'package:http/http.dart' as http;


class SliderWidget extends StatefulWidget {
  final double sliderHeight;
  final double min;
  final double max;
  final fullWidth;
  double value;
  String apiUrl;

  SliderWidget({
    this.sliderHeight = 48,
    this.max = 10,
    this.min = 0,
    this.fullWidth = false,
    this.value = 0,
    this.apiUrl
  });

  @override
  _SliderWidgetState createState() => _SliderWidgetState();
}

class _SliderWidgetState extends State<SliderWidget> {

  void setVolume(double value) async {
    var url = Uri.parse(widget.apiUrl);
    double percentage = sliderValueToPercentage(value);
    http.Response response = await http.patch(url, body: {'json': '{"value":"$percentage"}'});
  }

  @override
  Widget build(BuildContext context) {
    double paddingFactor = .2;

    if (this.widget.fullWidth) paddingFactor = .3;

    return Container(
      width: this.widget.fullWidth ? double.infinity : (this.widget.sliderHeight) * 5.5,
      height: (this.widget.sliderHeight),
      decoration: new BoxDecoration(
        borderRadius: new BorderRadius.all(
          Radius.circular((this.widget.sliderHeight * .5)),
        ),
        gradient: new LinearGradient(
            colors: [
              const Color(0xFF212121),
              const Color(0xFF282828),
            ],
            begin: const FractionalOffset(0.0, 0.0),
            end: const FractionalOffset(1.0, 1.00),
            stops: [0.0, 1.0],
            tileMode: TileMode.clamp),
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
                      }),
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
  }
}