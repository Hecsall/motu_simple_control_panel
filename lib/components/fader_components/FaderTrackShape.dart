import 'package:flutter/material.dart';
import 'package:motu_simple_control_panel/utils/color_manipulation.dart';


class FaderTrackShape extends SliderTrackShape with BaseSliderTrackShape {
  const FaderTrackShape();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double thumbWidth = sliderTheme.thumbShape!.getPreferredSize(true, isDiscrete).width;
    final double trackHeight = sliderTheme.trackHeight!;
    assert(thumbWidth >= 0);
    assert(trackHeight >= 0);
    assert(parentBox.size.width >= thumbWidth);
    assert(parentBox.size.height >= trackHeight);

    final double trackLeft = offset.dx + thumbWidth / 2;
    final double trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width - thumbWidth;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }

  @override
  void paint(
      PaintingContext context,
      Offset offset, {
        required RenderBox parentBox,
        required SliderThemeData sliderTheme,
        required Animation<double> enableAnimation,
        required TextDirection textDirection,
        required Offset thumbCenter,
        bool? isDiscrete,
        bool? isEnabled,
        double additionalActiveTrackHeight = 2,
      }) {
    if (sliderTheme.trackHeight == 0) {
      return;
    }

    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled ?? false,
      isDiscrete: isDiscrete ?? false,
    );

    final ColorTween activeTrackColorTween = ColorTween(
        begin: sliderTheme.disabledActiveTrackColor,
        end: lighten(sliderTheme.activeTrackColor!, 0.22)
    );
    final ColorTween inactiveTrackColorTween = ColorTween(
        begin: sliderTheme.disabledInactiveTrackColor,
        end: sliderTheme.inactiveTrackColor
    );
    final Paint activePaint = Paint()..color = activeTrackColorTween.evaluate(enableAnimation)!;
    final Paint activeSegmentGlowPaint = Paint()
      ..color = sliderTheme.activeTrackColor!
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10.0);
    final Paint inactivePaint = Paint()..color = inactiveTrackColorTween.evaluate(enableAnimation)!;
    final Radius trackRadius = Radius.circular(trackRect.height / 2);
    final Radius activeTrackRadius = Radius.circular((trackRect.height + additionalActiveTrackHeight) / 2);

    // Inactive segment of the fader
    context.canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        thumbCenter.dx,
        trackRect.top,
        trackRect.right,
        trackRect.bottom,
        topRight: trackRadius,
        bottomRight: trackRadius,
      ),
      inactivePaint,
    );

    // Fake glow effect with a blurred rectangle
    // Create a path a little bit shifted to the top to create a shadow
    final activeSegmentGlow = Path()
      ..moveTo(trackRect.left, trackRect.top)
      ..lineTo(thumbCenter.dx, trackRect.top)
      ..lineTo(thumbCenter.dx, trackRect.bottom)
      ..lineTo(trackRect.left, trackRect.bottom);
    context.canvas.drawPath(activeSegmentGlow, activeSegmentGlowPaint);

    // Active segment of the fader
    context.canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        trackRect.left,
        (textDirection == TextDirection.ltr) ? trackRect.top - (additionalActiveTrackHeight / 2): trackRect.top,
        thumbCenter.dx,
        (textDirection == TextDirection.ltr) ? trackRect.bottom + (additionalActiveTrackHeight / 2) : trackRect.bottom,
        topLeft: (textDirection == TextDirection.ltr) ? activeTrackRadius : trackRadius,
        bottomLeft: (textDirection == TextDirection.ltr) ? activeTrackRadius: trackRadius,
        topRight: (textDirection == TextDirection.ltr) ? activeTrackRadius : trackRadius,
        bottomRight: (textDirection == TextDirection.ltr) ? activeTrackRadius: trackRadius,
      ),
      activePaint,
    );

    // Handle empty track
    final Rect leftTrackSegment = Rect.fromLTRB(trackRect.left, trackRect.top, thumbCenter.dx, trackRect.bottom);
    if (!leftTrackSegment.isEmpty) {
      context.canvas.drawRect(leftTrackSegment, activePaint);
    }
    final Rect rightTrackSegment = Rect.fromLTRB(thumbCenter.dx, trackRect.top, trackRect.right, trackRect.bottom);
    if (!rightTrackSegment.isEmpty) {
      context.canvas.drawRect(rightTrackSegment, inactivePaint);
    }

  }
}