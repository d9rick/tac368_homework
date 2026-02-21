import 'package:flutter/material.dart';
import 'package:tac368_homework/widgets/bb.dart';
import 'package:tac368_homework/widgets/formula_button.dart';

void main() {
  runApp(const ConverterApp());
}

class ConverterApp extends StatelessWidget {
  const ConverterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ConverterPage(),
    );
  }
}

class ConverterPage extends StatefulWidget {
  const ConverterPage({super.key});

  @override
  State<ConverterPage> createState() => _ConverterPageState();
}

class _ConverterPageState extends State<ConverterPage> {
  String preConvert = '';
  String postConvert = '';
  bool justDone = false;

  void appendInput(String value) {
    setState(() {
      if (justDone) {
        preConvert = '';
        postConvert = '';
        justDone = false;
      }

      if (value == '-') {
        if (preConvert.startsWith('-')) {
          preConvert = preConvert.substring(1);
        } else {
          preConvert = '-$preConvert';
        }
        return;
      }

      if (value == '.') {
        if (preConvert.contains('.')) {
          return;
        }

        if (preConvert.isEmpty || preConvert == '-') {
          preConvert = '${preConvert}0.';
          return;
        }

        preConvert += '.';
        return;
      }

      if (preConvert == '0') {
        preConvert = value;
        return;
      }

      if (preConvert == '-0') {
        preConvert = '-$value';
        return;
      }

      preConvert += value;
    });
  }

  Widget digitButton(String label) {
    return SizedBox(
      width: 52,
      height: 52,
      child: TextButton(
        style: TextButton.styleFrom(padding: EdgeInsets.zero),
        onPressed: () => appendInput(label),
        child: BB(
          label,
          width: 52,
          height: 52,
          fontSize: 32,
          backgroundColor: const Color(0xFFE1D7F2),
        ),
      ),
    );
  }

  Widget displayBox(String value) {
    return Expanded(
      child: Container(
        height: 48,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(border: Border.all(width: 2)),
        child: Text(value, style: const TextStyle(fontSize: 32)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shownInput = preConvert.isEmpty ? '0' : preConvert;
    final shownOutput = postConvert.isEmpty ? '0.0000' : postConvert;

    return Scaffold(
      backgroundColor: const Color(0xFFE8E8E8),
      body: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF2EEF5),
            border: Border.all(width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Converter', style: TextStyle(fontSize: 32)),
              const SizedBox(height: 10),
              Row(
                children: [
                  displayBox(shownInput),
                  const SizedBox(width: 8),
                  displayBox(shownOutput),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 168,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            digitButton('7'),
                            digitButton('8'),
                            digitButton('9'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            digitButton('4'),
                            digitButton('5'),
                            digitButton('6'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            digitButton('1'),
                            digitButton('2'),
                            digitButton('3'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            digitButton('.'),
                            digitButton('0'),
                            digitButton('-'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    children: [
                      formulaButton(
                        'C-F',
                        (c) => (c * 9 / 5) + 32,
                        preConvert: preConvert,
                        setStateFn: setState,
                        setPostConvert: (value) => postConvert = value,
                        setJustDone: (value) => justDone = value,
                      ),
                      const SizedBox(height: 4),
                      formulaButton(
                        'F-C',
                        (f) => (f - 32) * 5 / 9,
                        preConvert: preConvert,
                        setStateFn: setState,
                        setPostConvert: (value) => postConvert = value,
                        setJustDone: (value) => justDone = value,
                      ),
                      const SizedBox(height: 4),
                      formulaButton(
                        'Kg-Lb',
                        (kg) => kg * 2.2046226218,
                        preConvert: preConvert,
                        setStateFn: setState,
                        setPostConvert: (value) => postConvert = value,
                        setJustDone: (value) => justDone = value,
                      ),
                      const SizedBox(height: 4),
                      formulaButton(
                        'Lb-Kg',
                        (lb) => lb / 2.2046226218,
                        preConvert: preConvert,
                        setStateFn: setState,
                        setPostConvert: (value) => postConvert = value,
                        setJustDone: (value) => justDone = value,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
