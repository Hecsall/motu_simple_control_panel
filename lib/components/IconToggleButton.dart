import 'package:flutter/material.dart';
import 'package:icon_shadow/icon_shadow.dart';


class IconToggleButton extends StatelessWidget {
  IconToggleButton({
    @required this.label,
    @required this.icon,
    @required this.activeColor,
    @required this.activeBlurColor,
    @required this.inactiveColor,
    @required this.active,
    @required this.onPressed
  });
  final String label;
  final icon;
  final activeColor;
  final activeBlurColor;
  final inactiveColor;
  final bool active;
  final GestureTapCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: IconShadowWidget(
          Icon(
            icon,
            color: active ? activeColor : inactiveColor,
            size: 28,
          ),
          shadowColor: activeBlurColor,
          showShadow: active ? true : false
      ),
      iconSize: 28,
      hoverColor: Color(0x00FFFFFF),
      splashColor: Color(0x00FFFFFF),
      highlightColor: Color(0x00FFFFFF),
      onPressed: onPressed,
    );
  }
}
