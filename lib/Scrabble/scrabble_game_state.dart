// scrabble_game_state.dart
// Derick Walker 2026
//
// Game state and logic for a simplified Scrabble game.
// Manages the board, player rack, shared tile bag,
// scoring, and turn-taking.
//
// Bag synchronization: the host generates a shuffled bag
// and sends it to the client. Both sides maintain an
// identical bag list and a shared draw index (nextDraw).
// When either player draws tiles, both sides advance
// nextDraw by the same amount so the bag stays in sync.

import "dart:math";
import "package:flutter_bloc/flutter_bloc.dart";

/// A record of one tile placed on the board during the current turn.
class TilePlacement {
  final int row;
  final int col;
  final String letter;
  TilePlacement(this.row, this.col, this.letter);
}

/// Immutable snapshot of the entire game state.
class ScrabbleState {
  static const int boardSize = 11;

  final List<List<String>> board; // boardSize x boardSize, "" = empty
  final List<String> rack; // this player's tiles (up to 7)
  final int selectedRackIndex; // which rack tile is selected, -1 = none
  final bool myTurn;
  final int myScore;
  final int oppScore;
  final List<String> bag; // the full shuffled tile bag
  final int nextDraw; // index of next tile to draw from bag
  final List<TilePlacement> placedThisTurn; // tiles placed this turn
  final bool isHost;
  final String status; // message shown to the player
  final bool bagReady; // true once the bag has been initialized

  ScrabbleState({
    required this.board,
    required this.rack,
    this.selectedRackIndex = -1,
    required this.myTurn,
    this.myScore = 0,
    this.oppScore = 0,
    required this.bag,
    this.nextDraw = 0,
    this.placedThisTurn = const [],
    required this.isHost,
    required this.status,
    this.bagReady = false,
  });

  ScrabbleState copyWith({
    List<List<String>>? board,
    List<String>? rack,
    int? selectedRackIndex,
    bool? myTurn,
    int? myScore,
    int? oppScore,
    List<String>? bag,
    int? nextDraw,
    List<TilePlacement>? placedThisTurn,
    bool? isHost,
    String? status,
    bool? bagReady,
  }) {
    return ScrabbleState(
      board: board ?? this.board,
      rack: rack ?? this.rack,
      selectedRackIndex: selectedRackIndex ?? this.selectedRackIndex,
      myTurn: myTurn ?? this.myTurn,
      myScore: myScore ?? this.myScore,
      oppScore: oppScore ?? this.oppScore,
      bag: bag ?? this.bag,
      nextDraw: nextDraw ?? this.nextDraw,
      placedThisTurn: placedThisTurn ?? this.placedThisTurn,
      isHost: isHost ?? this.isHost,
      status: status ?? this.status,
      bagReady: bagReady ?? this.bagReady,
    );
  }
}

/// Cubit that manages all Scrabble game logic.
class ScrabbleGameCubit extends Cubit<ScrabbleState> {
  // Standard Scrabble letter distribution (98 tiles total)
  static const Map<String, int> letterCounts = {
    "A": 9, "B": 2, "C": 2, "D": 4, "E": 12, "F": 2, "G": 3,
    "H": 2, "I": 9, "J": 1, "K": 1, "L": 4, "M": 2, "N": 6,
    "O": 8, "P": 2, "Q": 1, "R": 6, "S": 4, "T": 6, "U": 4,
    "V": 2, "W": 2, "X": 1, "Y": 2, "Z": 1,
  };

  ScrabbleGameCubit(bool isHost)
      : super(ScrabbleState(
          board: List.generate(
            ScrabbleState.boardSize,
            (_) => List.filled(ScrabbleState.boardSize, ""),
          ),
          rack: [],
          myTurn: false,
          bag: [],
          isHost: isHost,
          status: isHost ? "Setting up game..." : "Waiting for host...",
        ));

  /// Create a shuffled bag of all tiles. Called by host only.
  List<String> generateBag() {
    List<String> tiles = [];
    letterCounts.forEach((letter, count) {
      for (int i = 0; i < count; i++) {
        tiles.add(letter);
      }
    });
    tiles.shuffle(Random());
    return tiles;
  }

  /// Set the bag contents. Called on both sides.
  void initBag(List<String> bagLetters) {
    emit(state.copyWith(bag: bagLetters, bagReady: true));
  }

  /// Draw initial 7 tiles from the bag.
  /// Host draws indices 0-6, client draws indices 7-13.
  /// After this, nextDraw is set to 14 on both sides.
  void drawInitialTiles() {
    int startIndex = state.isHost ? 0 : 7;
    List<String> drawn = [];
    for (int i = startIndex; i < startIndex + 7 && i < state.bag.length; i++) {
      drawn.add(state.bag[i]);
    }
    emit(state.copyWith(
      rack: drawn,
      nextDraw: 14,
      myTurn: state.isHost, // host goes first
      status: state.isHost ? "Your turn" : "Opponent's turn",
    ));
  }

  /// Select (or deselect) a tile from the rack by index.
  void selectRackTile(int index) {
    if (!state.myTurn) return;
    if (index < 0 || index >= state.rack.length) return;
    // Toggle selection: tap same tile again to deselect
    int newIndex = (state.selectedRackIndex == index) ? -1 : index;
    emit(state.copyWith(selectedRackIndex: newIndex));
  }

  /// Place the currently selected rack tile onto the board at (row, col).
  void placeTile(int row, int col) {
    if (!state.myTurn) return;
    if (state.selectedRackIndex < 0) return;
    if (state.board[row][col].isNotEmpty) return;

    String letter = state.rack[state.selectedRackIndex];

    // Update the board with the new tile
    List<List<String>> newBoard =
        state.board.map((r) => List<String>.from(r)).toList();
    newBoard[row][col] = letter;

    // Remove the tile from the rack
    List<String> newRack = List<String>.from(state.rack);
    newRack.removeAt(state.selectedRackIndex);

    // Record this placement for the turn message
    List<TilePlacement> newPlacements = List.from(state.placedThisTurn);
    newPlacements.add(TilePlacement(row, col, letter));

    emit(state.copyWith(
      board: newBoard,
      rack: newRack,
      selectedRackIndex: -1,
      placedThisTurn: newPlacements,
      status: "Place tiles, then End Turn",
    ));
  }

  /// End the current turn. Draws replacement tiles from the bag.
  /// Returns the message string to send to the opponent, or null
  /// if the turn cannot be ended (no tiles placed / not your turn).
  String? endTurn() {
    if (!state.myTurn) return null;
    if (state.placedThisTurn.isEmpty) return null;

    int tilesPlaced = state.placedThisTurn.length;

    // Build the placement string: "row,col,letter;row,col,letter;..."
    String placements = state.placedThisTurn
        .map((p) => "${p.row},${p.col},${p.letter}")
        .join(";");

    // Draw replacement tiles from the shared bag
    int remaining = state.bag.length - state.nextDraw;
    int drawCount = min(tilesPlaced, remaining);
    List<String> newRack = List<String>.from(state.rack);
    int newNextDraw = state.nextDraw;
    for (int i = 0; i < drawCount; i++) {
      newRack.add(state.bag[newNextDraw]);
      newNextDraw++;
    }

    emit(state.copyWith(
      rack: newRack,
      nextDraw: newNextDraw,
      myTurn: false,
      placedThisTurn: [],
      selectedRackIndex: -1,
      myScore: state.myScore + tilesPlaced,
      status: "Opponent's turn",
    ));

    return "TURN|$placements";
  }

  /// Handle an incoming message from the opponent.
  /// Message types:
  ///   BAG|A,B,C,...   -- the shuffled bag (client receives from host)
  ///   TURN|r,c,L;...  -- opponent's tile placements for their turn
  void handle(String msg) {
    // Split on first "|" only, in case payload contains "|"
    int sep = msg.indexOf("|");
    if (sep < 0) return;
    String command = msg.substring(0, sep);
    String payload = msg.substring(sep + 1);

    switch (command) {
      case "BAG":
        // Client receives the shuffled bag from host
        List<String> bagLetters = payload.split(",");
        initBag(bagLetters);
        drawInitialTiles();
        break;

      case "TURN":
        _handleRemoteTurn(payload);
        break;
    }
  }

  /// Apply the opponent's turn: update board, advance bag pointer, update score.
  void _handleRemoteTurn(String placementStr) {
    List<String> placements = placementStr.split(";");
    List<List<String>> newBoard =
        state.board.map((r) => List<String>.from(r)).toList();

    int tilesPlaced = 0;
    for (String p in placements) {
      List<String> parts = p.split(",");
      int row = int.parse(parts[0]);
      int col = int.parse(parts[1]);
      String letter = parts[2];
      newBoard[row][col] = letter;
      tilesPlaced++;
    }

    // Advance the draw index to stay in sync with the opponent's draw
    int remaining = state.bag.length - state.nextDraw;
    int drawCount = min(tilesPlaced, remaining);
    int newNextDraw = state.nextDraw + drawCount;

    emit(state.copyWith(
      board: newBoard,
      nextDraw: newNextDraw,
      myTurn: true,
      oppScore: state.oppScore + tilesPlaced,
      status: "Your turn",
    ));
  }

  /// Returns the bag as a comma-separated string for sending to the client.
  String bagToString() {
    return state.bag.join(",");
  }
}
