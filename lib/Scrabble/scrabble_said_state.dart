// scrabble_said_state.dart
// Derick Walker 2026
//
// Message routing for the Scrabble game.
// Adapted from TicTacToe/said_state.dart to route
// incoming messages to ScrabbleGameCubit instead of GameCubit.
//
// Message protocol over the socket:
//   HIDE|<command>  -- game commands (BAG, TURN), not shown to user
//   CHAT|<text>     -- chat messages, shown in the chat area

import "dart:convert";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

import "../TicTacToe/yak_state.dart";
import "scrabble_game_state.dart";

/// State that holds the visible chat log.
class ScrabbleSaidState {
  String said;
  ScrabbleSaidState(this.said);
}

/// Cubit for sending and receiving messages over the socket.
class ScrabbleSaidCubit extends Cubit<ScrabbleSaidState> {
  ScrabbleSaidCubit() : super(ScrabbleSaidState(""));

  /// Add a line of text to the visible chat log.
  void addVisible(String more) {
    emit(ScrabbleSaidState("${state.said}$more\n"));
  }

  /// Send a chat message (visible to both players).
  void sendChat(BuildContext bc, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    YakCubit yc = BlocProvider.of<YakCubit>(bc);
    yc.say("CHAT|$trimmed");
    addVisible("me: $trimmed");
  }

  /// Send a hidden game command (not shown in chat).
  void sendHidden(BuildContext bc, String command) {
    YakCubit yc = BlocProvider.of<YakCubit>(bc);
    yc.say("HIDE|$command");
  }

  /// Start listening on the socket for incoming messages.
  /// Routes game commands to ScrabbleGameCubit.handle()
  /// and chat messages to the visible log.
  void listen(BuildContext bc) {
    YakCubit yc = BlocProvider.of<YakCubit>(bc);
    YakState ys = yc.state;
    ScrabbleGameCubit gc = BlocProvider.of<ScrabbleGameCubit>(bc);

    ys.socket!
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          (message) async {
            if (message.startsWith("HIDE|")) {
              // Route game command to the game cubit
              gc.handle(message.substring(5));
              return;
            }
            if (message.startsWith("CHAT|")) {
              // Show opponent's chat message
              addVisible("opponent: ${message.substring(5)}");
              return;
            }
            // Fallback: show raw message
            addVisible("opponent: $message");
          },
          onError: (error) {
            print(error);
            ys.socket!.close();
          },
        );
  }
}
