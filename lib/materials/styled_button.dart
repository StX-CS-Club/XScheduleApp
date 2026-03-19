import 'dart:async';

import 'package:flutter/material.dart';
import 'package:xschedule/extensions/widget_extension.dart';

class StyledButton extends StatelessWidget {
  const StyledButton(
      {super.key,
      this.text,
      this.icon,
        this.iconSize = 24,
        this.textStyle,
      this.onTap,
      this.backgroundColor,
      this.contentColor,
      this.vertical = false,
      this.height,
      this.width, this.borderRadius = 16});

  final String? text;
  final IconData? icon;
  final double? iconSize;
  final TextStyle? textStyle;
  final FutureOr<void> Function()? onTap;
  final Color? backgroundColor;
  final Color? contentColor;
  final bool vertical;
  final double? height;
  final double? width;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    final List<Widget> children = [
      if (icon != null)
        Icon(
          icon,
          size: iconSize,
          color: contentColor ?? colorScheme.onPrimary,
        ),
      if (text != null)
        Text(
          "${icon != null && !vertical ? '  ' : ''}$text",
          style: textStyle ?? TextStyle(
              fontSize: 24,
              fontFamily: "Georama",
              color: contentColor ?? colorScheme.onPrimary),
        )
    ];

    return ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
            overlayColor: contentColor ?? colorScheme.onPrimary,
            backgroundColor: backgroundColor ?? colorScheme.primary,
            shape: borderRadius != null ? RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(borderRadius ?? 16))) : null),
        child: Container(
                alignment: Alignment.center,
                height: height,
                width: width,
                child: vertical
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: children,
                      ).fit()
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: children,
                      ).fit()));
  }
}
