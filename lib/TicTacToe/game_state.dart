// game_state.dart
// Barrett Koster 2025

import "package:flutter_bloc/flutter_bloc.dart";

// This is where you put whatever the game is about.

class GameState {
  final bool iStart;
  final bool myTurn;
  final List<String> board;
  final bool gameOver;
  final String status;

  GameState(this.iStart, this.myTurn, this.board, this.gameOver, this.status);

  GameState copyWith({
    bool? iStart,
    bool? myTurn,
    List<String>? board,
    bool? gameOver,
    String? status,
  }) {
    return GameState(
      iStart ?? this.iStart,
      myTurn ?? this.myTurn,
      board ?? this.board,
      gameOver ?? this.gameOver,
      status ?? this.status,
    );
  }
}

class GameCubit extends Cubit<GameState> {
  static final String d = ".";
  GameCubit(bool myt)
    : super(
        GameState(
          myt,
          myt,
          [d, d, d, d, d, d, d, d, d],
          false,
          myt ? "Your turn" : "Opponent's turn",
        ),
      );

  String myMark() => state.iStart ? "x" : "o";
  String oppMark() => state.iStart ? "o" : "x";

  bool canPlaySquare(int where) {
    return !state.gameOver && state.myTurn && state.board[where] == d;
  }

  String _winnerForBoard(List<String> b) {
    const lines = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6],
    ];

    for (final line in lines) {
      final a = b[line[0]];
      if (a != d && a == b[line[1]] && a == b[line[2]]) {
        return a;
      }
    }
    return "";
  }

  bool _boardFull(List<String> b) {
    return !b.contains(d);
  }

  // Someone played x or o in this square.  (numbered from
  // upper left 0,1,2, next row 3,4,5 ...
  // Update the board and emit.
  bool playLocal(int where) {
    if (state.gameOver) {
      emit(state.copyWith(status: "Game over"));
      return false;
    }
    if (!state.myTurn) {
      emit(state.copyWith(status: "Wait for your turn"));
      return false;
    }
    if (state.board[where] != d) {
      emit(state.copyWith(status: "Square already used"));
      return false;
    }

    final b = List<String>.from(state.board);
    b[where] = myMark();
    final w = _winnerForBoard(b);
    if (w.isNotEmpty) {
      emit(
        state.copyWith(
          board: b,
          myTurn: false,
          gameOver: true,
          status: "You win",
        ),
      );
      return true;
    }
    if (_boardFull(b)) {
      emit(
        state.copyWith(
          board: b,
          myTurn: false,
          gameOver: true,
          status: "Tie game",
        ),
      );
      return true;
    }

    emit(state.copyWith(board: b, myTurn: false, status: "Opponent's turn"));
    return true;
  }

  bool applyRemoteMove(int where) {
    if (state.gameOver || state.board[where] != d) {
      return false;
    }

    final b = List<String>.from(state.board);
    b[where] = oppMark();
    final w = _winnerForBoard(b);
    if (w.isNotEmpty) {
      emit(
        state.copyWith(
          board: b,
          myTurn: false,
          gameOver: true,
          status: "Opponent wins",
        ),
      );
      return true;
    }
    if (_boardFull(b)) {
      emit(
        state.copyWith(
          board: b,
          myTurn: false,
          gameOver: true,
          status: "Tie game",
        ),
      );
      return true;
    }

    emit(state.copyWith(board: b, myTurn: true, status: "Your turn"));
    return true;
  }

  bool resignLocal() {
    if (state.gameOver) {
      return false;
    }
    emit(state.copyWith(gameOver: true, myTurn: false, status: "You resigned"));
    return true;
  }

  void resignRemote() {
    if (!state.gameOver) {
      emit(
        state.copyWith(
          gameOver: true,
          myTurn: false,
          status: "Opponent resigned. You win",
        ),
      );
    }
  }

  bool passLocal() {
    if (state.gameOver || !state.myTurn) {
      return false;
    }
    emit(state.copyWith(myTurn: false, status: "You passed. Opponent's turn"));
    return true;
  }

  void passRemote() {
    if (!state.gameOver) {
      emit(state.copyWith(myTurn: true, status: "Opponent passed. Your turn"));
    }
  }

  // incoming messages are sent here for the game to do
  // whatever with.  in this case, "sq NUM" messages ..
  // we send the number to be played.
  void handle(String msg) {
    List<String> parts = msg.split(" ");
    if (parts.isEmpty) {
      return;
    }

    if (parts[0] == "MOVE" && parts.length > 1) {
      int sqNum = int.parse(parts[1]);
      applyRemoteMove(sqNum);
      return;
    }

    if (parts[0] == "RESIGN") {
      resignRemote();
      return;
    }

    if (parts[0] == "PASS") {
      passRemote();
      return;
    }

    // Backward-compatibility with original starter protocol.
    if (parts[0] == "sq" && parts.length > 1) {
      int sqNum = int.parse(parts[1]);
      applyRemoteMove(sqNum);
    }
  }
}
