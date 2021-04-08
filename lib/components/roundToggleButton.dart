import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class RoundToggleButton extends StatelessWidget {
  RoundToggleButton({
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

      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 6, 20, 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: active ? inactiveColor : activeColor,
            ),
            SizedBox(
                width: 10.0,
            ),
            Text(
              this.label,
              maxLines: 1,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                  color: active ? inactiveColor : activeColor
              ),
            ),
          ],
        ),
      ),
      onPressed: onPressed,
      shape: StadiumBorder(
        side: BorderSide(
            width: 2.0,
            color: activeColor
        ),
      ),
    );
  }
}
