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
      constraints: BoxConstraints(
        minHeight: 30
      ),

      child: Padding(
        padding: EdgeInsets.fromLTRB(18, 0, 20, 0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: active ? inactiveColor : activeColor,
              size: 18.0,
            ),
            SizedBox(
                width: 10.0,
            ),
            Text(
              this.label,
              maxLines: 1,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: active ? inactiveColor : activeColor,
                fontSize: 13,
                height: 1
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
