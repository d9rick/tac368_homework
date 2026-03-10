// hw06dealNoDeal.dart
// Derick Walker  2026
// An implementation of deal or no deal, prescribed by the professor

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const DealNoDealApp());
}

String formatMoney(int amount) {
  final String digits = amount.toString();
  final StringBuffer buffer = StringBuffer();
  for (int index = 0; index < digits.length; index++) {
    final int remaining = digits.length - index;
    buffer.write(digits[index]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write(',');
    }
  }
  return '\$${buffer.toString()}';
}

class DealNoDealApp extends StatelessWidget {
  const DealNoDealApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Deal or No Deal - Derick Walker',
      home: const DealNoDealPage(),
    );
  }
}

class Suitcase {
  final int number;
  final int amount;
  bool isHeld;
  bool isOpened;

  Suitcase({
    required this.number,
    required this.amount,
    this.isHeld = false,
    this.isOpened = false,
  });
}

class DealNoDealPage extends StatefulWidget {
  const DealNoDealPage({super.key});

  @override
  State<DealNoDealPage> createState() => _DealNoDealPageState();
}

class _DealNoDealPageState extends State<DealNoDealPage> {
  static const List<int> caseValues = [
    1,
    5,
    10,
    100,
    1000,
    5000,
    10000,
    100000,
    500000,
    1000000,
  ];

  final Random _random = Random();
  final FocusNode _focusNode = FocusNode();

  late List<Suitcase> _suitcases;
  int? _heldCaseNumber;
  int? _currentOffer;
  int? _acceptedOffer;
  int? _finalWinnings;
  String _statusMessage = '';
  bool _gameOver = false;

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _startNewGame() {
    final List<int> shuffledValues = List<int>.from(caseValues)
      ..shuffle(_random);

    setState(() {
      _suitcases = List<Suitcase>.generate(
        shuffledValues.length,
        (int index) =>
            Suitcase(number: index + 1, amount: shuffledValues[index]),
      );
      _heldCaseNumber = null;
      _currentOffer = null;
      _acceptedOffer = null;
      _finalWinnings = null;
      _gameOver = false;
      _statusMessage = 'Pick your hold suitcase to start the game.';
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final String key = event.logicalKey.keyLabel.toLowerCase();
    if (key == 'd') {
      _acceptDeal();
      return KeyEventResult.handled;
    }
    if (key == 'n') {
      _rejectDeal();
      return KeyEventResult.handled;
    }

    final int? caseNumber = _caseNumberFromKey(key);
    if (caseNumber != null) {
      _selectSuitcase(caseNumber);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  int? _caseNumberFromKey(String key) {
    if (key.length != 1 || !RegExp(r'[0-9]').hasMatch(key)) {
      return null;
    }

    if (key == '0') {
      return 10;
    }

    return int.tryParse(key);
  }

  Suitcase _getHeldSuitcase() {
    return _suitcases.firstWhere((Suitcase suitcase) => suitcase.isHeld);
  }

  List<Suitcase> _remainingHiddenSuitcases() {
    return _suitcases.where((Suitcase suitcase) => !suitcase.isOpened).toList();
  }

  List<Suitcase> _remainingHiddenNonHeldSuitcases() {
    return _suitcases
        .where((Suitcase suitcase) => !suitcase.isOpened && !suitcase.isHeld)
        .toList();
  }

  int _expectedValue() {
    final List<Suitcase> hiddenSuitcases = _remainingHiddenSuitcases();
    final int total = hiddenSuitcases.fold(
      0,
      (int sum, Suitcase suitcase) => sum + suitcase.amount,
    );
    return (total / hiddenSuitcases.length).round();
  }

  int _dealerOffer() {
    return (_expectedValue() * 0.9).round();
  }

  void _selectSuitcase(int caseNumber) {
    if (_gameOver) {
      setState(() {
        _statusMessage = 'The game is over. Start a new game to play again.';
      });
      return;
    }

    final Suitcase suitcase = _suitcases.firstWhere(
      (Suitcase item) => item.number == caseNumber,
    );

    if (_heldCaseNumber == null) {
      setState(() {
        suitcase.isHeld = true;
        _heldCaseNumber = suitcase.number;
        _statusMessage =
            'Suitcase ${suitcase.number} is yours. Open a different suitcase.';
      });
      return;
    }

    if (_currentOffer != null) {
      setState(() {
        _statusMessage = 'Respond to the dealer first: press DEAL or NO DEAL.';
      });
      return;
    }

    if (suitcase.isHeld) {
      setState(() {
        _statusMessage = 'You cannot open your hold suitcase.';
      });
      return;
    }

    if (suitcase.isOpened) {
      setState(() {
        _statusMessage = 'Suitcase ${suitcase.number} has already been opened.';
      });
      return;
    }

    setState(() {
      suitcase.isOpened = true;
      _currentOffer = _dealerOffer();
      _statusMessage =
          'Suitcase ${suitcase.number} contained ${_formatMoney(suitcase.amount)}.';
    });
  }

  void _acceptDeal() {
    if (_gameOver) {
      return;
    }

    if (_currentOffer == null) {
      setState(() {
        _statusMessage = 'There is no dealer offer to accept right now.';
      });
      return;
    }

    setState(() {
      _acceptedOffer = _currentOffer;
      _finalWinnings = _currentOffer;
      _gameOver = true;
      _statusMessage =
          'Deal accepted! You win ${_formatMoney(_finalWinnings!)}.';
      _currentOffer = null;
    });
  }

  void _rejectDeal() {
    if (_gameOver) {
      return;
    }

    if (_currentOffer == null) {
      setState(() {
        _statusMessage = 'There is no dealer offer to reject right now.';
      });
      return;
    }

    if (_remainingHiddenNonHeldSuitcases().isEmpty) {
      final Suitcase heldSuitcase = _getHeldSuitcase();
      setState(() {
        _currentOffer = null;
        _finalWinnings = heldSuitcase.amount;
        _gameOver = true;
        _statusMessage =
            'No deal! Your hold suitcase had ${_formatMoney(heldSuitcase.amount)}.';
      });
      return;
    }

    setState(() {
      _currentOffer = null;
      _statusMessage = 'No deal. Choose another suitcase to open.';
    });
  }

  String _formatMoney(int amount) {
    return formatMoney(amount);
  }

  @override
  Widget build(BuildContext context) {
    final List<int> revealedValues = _suitcases
        .where((Suitcase suitcase) => suitcase.isOpened)
        .map((Suitcase suitcase) => suitcase.amount)
        .toList();
    final List<Suitcase> remainingCases = _remainingHiddenNonHeldSuitcases();
    final int? heldValue = _heldCaseNumber == null
        ? null
        : _getHeldSuitcase().amount;

    return Focus(
      autofocus: true,
      focusNode: _focusNode,
      onKeyEvent: _handleKey,
      child: Scaffold(
        appBar: AppBar(title: const Text('Deal or No Deal - Derick Walker')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: _startNewGame,
                  child: const Text('New Game'),
                ),
                const SizedBox(height: 12),
                _StatusPanel(
                  statusMessage: _statusMessage,
                  offer: _currentOffer,
                  heldCaseNumber: _heldCaseNumber,
                  remainingCaseCount: remainingCases.length,
                  winnings: _finalWinnings,
                  acceptedOffer: _acceptedOffer,
                  heldValue: _gameOver && _acceptedOffer == null
                      ? heldValue
                      : null,
                  onDeal: _currentOffer == null || _gameOver
                      ? null
                      : _acceptDeal,
                  onNoDeal: _currentOffer == null || _gameOver
                      ? null
                      : _rejectDeal,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Keyboard: 1-9 pick cases, 0 is case 10, d = deal, n = no deal',
                ),
                const SizedBox(height: 12),
                _SuitcaseGrid(suitcases: _suitcases, onSelect: _selectSuitcase),
                const SizedBox(height: 12),
                _ValueBoard(
                  values: caseValues,
                  revealedValues: revealedValues,
                  formatMoney: _formatMoney,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  final String statusMessage;
  final int? offer;
  final int? heldCaseNumber;
  final int remainingCaseCount;
  final int? winnings;
  final int? acceptedOffer;
  final int? heldValue;
  final VoidCallback? onDeal;
  final VoidCallback? onNoDeal;

  const _StatusPanel({
    required this.statusMessage,
    required this.offer,
    required this.heldCaseNumber,
    required this.remainingCaseCount,
    required this.winnings,
    required this.acceptedOffer,
    required this.heldValue,
    required this.onDeal,
    required this.onNoDeal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('HW for TAC-368', style: TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(statusMessage),
          const SizedBox(height: 12),
          Text(
            'Hold suitcase: ${heldCaseNumber == null ? 'Not chosen' : '#$heldCaseNumber'}',
          ),
          Text('Cases left to open: $remainingCaseCount'),
          Text(
            'Dealer offer: ${offer == null ? 'Waiting...' : _money(offer!)}',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onDeal,
                  child: const Text('DEAL'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: onNoDeal,
                  child: const Text('NO DEAL'),
                ),
              ),
            ],
          ),
          if (winnings != null) ...[
            const SizedBox(height: 12),
            Text(
              acceptedOffer != null
                  ? 'You took the deal for ${_money(winnings!)}.'
                  : 'You won ${_money(winnings!)} from your hold suitcase.',
              style: const TextStyle(fontSize: 20),
            ),
          ],
          if (heldValue != null) ...[
            const SizedBox(height: 8),
            Text('Your hold suitcase contained ${_money(heldValue!)}.'),
          ],
        ],
      ),
    );
  }

  String _money(int amount) {
    return formatMoney(amount);
  }
}

class _SuitcaseGrid extends StatelessWidget {
  final List<Suitcase> suitcases;
  final ValueChanged<int> onSelect;

  const _SuitcaseGrid({required this.suitcases, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Suitcases', style: TextStyle(fontSize: 24)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suitcases.map((Suitcase suitcase) {
              return ElevatedButton(
                onPressed: suitcase.isOpened
                    ? null
                    : () => onSelect(suitcase.number),
                child: Text(_buttonText(suitcase)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _buttonText(Suitcase suitcase) {
    if (suitcase.isOpened) {
      return formatMoney(suitcase.amount);
    }
    if (suitcase.isHeld) {
      return 'Case ${suitcase.number}*';
    }
    return 'Case ${suitcase.number}';
  }
}

class _ValueBoard extends StatelessWidget {
  final List<int> values;
  final List<int> revealedValues;
  final String Function(int amount) formatMoney;

  const _ValueBoard({
    required this.values,
    required this.revealedValues,
    required this.formatMoney,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Value Board', style: TextStyle(fontSize: 24)),
          const SizedBox(height: 10),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: values.length,
            separatorBuilder: (BuildContext context, int index) =>
                const Divider(height: 1),
            itemBuilder: (BuildContext context, int index) {
              final int value = values[index];
              final bool revealed = revealedValues.contains(value);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  revealed
                      ? '${formatMoney(value)} (opened)'
                      : formatMoney(value),
                  style: TextStyle(
                    color: revealed ? Colors.grey : Colors.black,
                    decoration: revealed ? TextDecoration.lineThrough : null,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
