import 'package:flutter/material.dart';
import 'package:tac368_homework/widgets/bb.dart';

Widget formulaButton(
  String label,
  double Function(double) convert, {
  required String preConvert,
  required void Function(VoidCallback fn) setStateFn,
  required ValueChanged<String> setPostConvert,
  required ValueChanged<bool> setJustDone,
  double width = 94,
  double height = 52,
}) {
  return SizedBox(
    width: width,
    height: height,
    child: TextButton(
      style: TextButton.styleFrom(padding: EdgeInsets.zero),
      onPressed: () {
        final input = double.tryParse(preConvert);
        if (input == null) {
          return;
        }

        setStateFn(() {
          final converted = convert(input);
          setPostConvert(converted.toStringAsFixed(4));
          setJustDone(true);
        });
      },
      child: BB(label, width: width, height: height, fontSize: 24),
    ),
  );
}
