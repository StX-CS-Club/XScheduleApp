import 'package:flutter/material.dart';

class PopupMenu extends StatelessWidget {
  const PopupMenu({
    super.key,
    this.backgroundColor,
    required this.child,
    this.popButton = false,
  });

  final Color? backgroundColor;
  final Widget child;
  final bool popButton;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Card(
        color: backgroundColor ?? colorScheme.surface,
        child: Stack(
          children: [
            child,
            // Conditional close button
            if (popButton)
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
