import 'package:flutter/material.dart';

class BB extends StatelessWidget {
  const BB(
    this.label, {
    super.key,
    this.width = 200,
    this.height = 60,
    this.fontSize = 20,
    this.backgroundColor,
  });

  final String label;
  final double width;
  final double height;
  final double fontSize;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(width: 2),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(label, style: TextStyle(fontSize: fontSize)),
      ),
    );
  }
}
