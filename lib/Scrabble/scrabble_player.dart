// scrabble_player.dart
// Derick Walker 2026
//
// UI widgets for the Scrabble game.
// Structure mirrors TicTacToe/player.dart:
//   ScrabblePlayer  -- sets up GameCubit and SaidCubit BLoC layers
//   ScrabblePlayer2 -- initializes socket listening and bag exchange
//   ScrabblePlayer3 -- the actual game board, rack, and controls

import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

import "../TicTacToe/yak_state.dart";
import "scrabble_game_state.dart";
import "scrabble_said_state.dart";

/// Top-level player widget. Creates the game and message cubits.
class ScrabblePlayer extends StatelessWidget {
  final bool isHost;
  ScrabblePlayer(this.isHost, {super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ScrabbleGameCubit>(
      create: (_) => ScrabbleGameCubit(isHost),
      child: BlocBuilder<ScrabbleGameCubit, ScrabbleState>(
        builder: (context, state) => BlocProvider<ScrabbleSaidCubit>(
          create: (_) => ScrabbleSaidCubit(),
          child: BlocBuilder<ScrabbleSaidCubit, ScrabbleSaidState>(
            builder: (context, state) => Scaffold(
              appBar: AppBar(title: Text("Scrabble")),
              body: ScrabblePlayer2(),
            ),
          ),
        ),
      ),
    );
  }
}

/// Initializes socket listening. If this is the host,
/// generates the tile bag, sends it to the client, and
/// draws the initial tiles for both sides.
class ScrabblePlayer2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    YakCubit yc = BlocProvider.of<YakCubit>(context);
    YakState ys = yc.state;
    ScrabbleSaidCubit sc = BlocProvider.of<ScrabbleSaidCubit>(context);
    ScrabbleGameCubit gc = BlocProvider.of<ScrabbleGameCubit>(context);

    // Set up socket listening exactly once
    if (ys.socket != null && !ys.listened) {
      sc.listen(context);
      yc.updateListen();

      // Host: generate the shared bag, send it, draw initial tiles
      if (gc.state.isHost && !gc.state.bagReady) {
        List<String> bag = gc.generateBag();
        gc.initBag(bag);
        sc.sendHidden(context, "BAG|${gc.bagToString()}");
        gc.drawInitialTiles();
      }
    }

    return ScrabblePlayer3();
  }
}

/// The main game UI: status, scores, board, rack, and chat.
class ScrabblePlayer3 extends StatelessWidget {
  ScrabblePlayer3({super.key});
  final TextEditingController chatTec = TextEditingController();

  @override
  Widget build(BuildContext context) {
    ScrabbleGameCubit gc = BlocProvider.of<ScrabbleGameCubit>(context);
    ScrabbleState gs = gc.state;
    ScrabbleSaidCubit sc = BlocProvider.of<ScrabbleSaidCubit>(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(8),
      child: Column(
        children: [
          // --- Status message ---
          Text(
            gs.status,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),

          // --- Score display ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text("You: ${gs.myScore}", style: TextStyle(fontSize: 16)),
              Text("Opp: ${gs.oppScore}", style: TextStyle(fontSize: 16)),
              Text(
                "Bag: ${gs.bagReady ? gs.bag.length - gs.nextDraw : '?'}",
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
          SizedBox(height: 8),

          // --- Game board (11x11 grid) ---
          _buildBoard(gc, gs),
          SizedBox(height: 8),

          // --- Rack label ---
          Text("Your tiles:", style: TextStyle(fontSize: 14)),
          SizedBox(height: 4),

          // --- Player's tile rack ---
          _buildRack(gc, gs),
          SizedBox(height: 8),

          // --- End Turn button ---
          ElevatedButton(
            onPressed: (gs.myTurn && gs.placedThisTurn.isNotEmpty)
                ? () {
                    String? msg = gc.endTurn();
                    if (msg != null) {
                      sc.sendHidden(context, msg);
                    }
                  }
                : null,
            child: Text("End Turn"),
          ),
          SizedBox(height: 8),

          // --- Chat log ---
          SizedBox(
            height: 100,
            child: SingleChildScrollView(
              child: Align(
                alignment: Alignment.topLeft,
                child: Text(sc.state.said),
              ),
            ),
          ),

          // --- Chat input ---
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: chatTec,
                  decoration: InputDecoration(hintText: "chat"),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  sc.sendChat(context, chatTec.text);
                  chatTec.clear();
                },
                child: Text("send"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the 11x11 game board as a column of rows.
  /// Empty cells are clickable when the player has a tile selected.
  /// Tiles placed this turn are highlighted in green.
  Widget _buildBoard(ScrabbleGameCubit gc, ScrabbleState gs) {
    // Track which cells were placed this turn for highlighting
    Set<String> placedKeys = {};
    for (var p in gs.placedThisTurn) {
      placedKeys.add("${p.row},${p.col}");
    }

    return Column(
      children: List.generate(ScrabbleState.boardSize, (row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(ScrabbleState.boardSize, (col) {
            String cell = gs.board[row][col];
            bool justPlaced = placedKeys.contains("$row,$col");
            bool isEmpty = cell.isEmpty;

            // Color coding: green for just-placed, amber for existing, grey for empty
            Color bgColor;
            if (justPlaced) {
              bgColor = Colors.lightGreen.shade200;
            } else if (!isEmpty) {
              bgColor = Colors.amber.shade100;
            } else {
              bgColor = Colors.grey.shade100;
            }

            return GestureDetector(
              onTap: (isEmpty && gs.myTurn && gs.selectedRackIndex >= 0)
                  ? () => gc.placeTile(row, col)
                  : null,
              child: Container(
                width: 32,
                height: 32,
                margin: EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: bgColor,
                  border: Border.all(color: Colors.grey.shade400),
                ),
                alignment: Alignment.center,
                child: Text(
                  cell,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            );
          }),
        );
      }),
    );
  }

  /// Builds the player's rack as a horizontal row of tile buttons.
  /// The selected tile is highlighted with a red border.
  Widget _buildRack(ScrabbleGameCubit gc, ScrabbleState gs) {
    if (gs.rack.isEmpty) {
      return Text("(no tiles)");
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(gs.rack.length, (i) {
        bool isSelected = gs.selectedRackIndex == i;
        return GestureDetector(
          onTap: gs.myTurn ? () => gc.selectRackTile(i) : null,
          child: Container(
            width: 40,
            height: 40,
            margin: EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: Colors.amber.shade300,
              border: Border.all(
                color: isSelected ? Colors.red : Colors.brown,
                width: isSelected ? 3 : 1,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: Text(
              gs.rack[i],
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }),
    );
  }
}
