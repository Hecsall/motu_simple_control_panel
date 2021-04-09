import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CircleToggleButton extends StatelessWidget {
  CircleToggleButton({
    @required this.label,
    @required this.icon,
    @required this.activeColor,
    @required this.inactiveColor,
    @required this.active,
    @required this.onPressed
  });
  final String label;
  final icon;
  final activeColor;
  final inactiveColor;
  final bool active;
  final GestureTapCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return RawMaterialButton(
      fillColor: active ? activeColor : inactiveColor,
      splashColor: active ? inactiveColor : activeColor,
      elevation: 0,
      constraints: BoxConstraints(
        minHeight: 30,
        minWidth: 10
      ),

      child: Padding(
        padding: EdgeInsets.fromLTRB(6, 6, 6, 6),
        child: Icon(
          icon,
          color: active ? inactiveColor : activeColor,
          size: 18.0,
        ),
      ),
      onPressed: onPressed,
      shape: CircleBorder(
        side: BorderSide(
            width: 2.0,
            color: activeColor
        ),
      ),
    );
  }
}
