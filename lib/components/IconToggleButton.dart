import 'package:flutter/material.dart';
import 'package:decorated_icon/decorated_icon.dart';
import 'package:motu_simple_control_panel/utils/color_manipulation.dart';


class IconToggleButton extends StatelessWidget {
  IconToggleButton({
    required this.label,
    required this.icon,
    required this.activeColor,
    required this.inactiveColor,
    required this.active,
    required this.onPressed
  });
  final String label;
  final icon;
  final activeColor;
  final inactiveColor;
  final bool active;
  final GestureTapCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: DecoratedIcon(
        icon,
        color: active ? lighten(activeColor, 0.22) : inactiveColor,
        size: 26.0,
        shadows: [
          BoxShadow(
            blurRadius: active ? 8.0 : 0,
            color: activeColor,
          ),
        ],
      ),
      iconSize: 26,
      hoverColor: Color(0x00FFFFFF),
      splashColor: Color(0x00FFFFFF),
      highlightColor: Color(0x00FFFFFF),
      onPressed: onPressed,
    );
  }
}
