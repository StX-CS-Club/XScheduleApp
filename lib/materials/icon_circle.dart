import 'package:flutter/material.dart';
import 'package:xschedule/extensions/widget_extension.dart';

class IconCircle extends StatelessWidget {
  /// Widget which provides an Icon with a filled, circular border around it. <p>
  /// [required IconData icon]: The icon to be displayed <p>
  /// [void Function()? onTap]: The method to run once the icon is tapped <p>
  /// [double radius = 15]: The radius of the circle <p>
  /// [double padding 5]: The padding of the circle and its icon <p>
  /// [Color? color]: The color of the circle <p>
  /// [Color? iconColor]: The color of the icon
  const IconCircle(
      {super.key,
      required this.icon,
      this.onTap,
      this.color,
      this.radius = 15,
      this.padding = 5,
      this.iconColor});

  final IconData icon;
  final void Function()? onTap;
  final double radius;
  final double padding;
  final Color? color;
  final Color? iconColor;

// Returns an InkWell w/ a Stack of circle on Icon
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: color,
        child: Icon(
          icon,
          size: radius * 2 - padding,
          color: iconColor,
        ).fit(),
      ),
    );
  }
}
