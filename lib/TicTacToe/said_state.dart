// said_state.dart
// Barrett Koster 2025

import "dart:convert";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

import "yak_state.dart";
import "game_state.dart";

// Use this class to pass messages between two programs.
// It has access to the YakCubit so to listen for
// messages.  And it has access to the GameCubit
// so that it can send messages to it (to update the
// state of the game.

class SaidState {
  String said;

  SaidState(this.said);
}

class SaidCubit extends Cubit<SaidState> {
  SaidCubit() : super(SaidState("and so it begins ....\n"));

  void addVisible(String more) {
    emit(SaidState("${state.said}$more\n"));
  }

  void sendChat(BuildContext bc, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }

    YakCubit yc = BlocProvider.of<YakCubit>(bc);
    yc.say("CHAT|$trimmed");
    addVisible("me: $trimmed");
  }

  void sendHidden(BuildContext bc, String command) {
    YakCubit yc = BlocProvider.of<YakCubit>(bc);
    yc.say("HIDE|$command");
  }

  void listen(BuildContext bc) {
    YakCubit yc = BlocProvider.of<YakCubit>(bc);
    YakState ys = yc.state;

    GameCubit gc = BlocProvider.of<GameCubit>(bc);

    ys.socket!
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          (message) async {
            if (message.startsWith("HIDE|")) {
              gc.handle(message.substring(5));
              return;
            }

            if (message.startsWith("CHAT|")) {
              addVisible("opponent: ${message.substring(5)}");
              return;
            }

            // Backward-compatibility: old messages are visible and game-routed.
            addVisible("opponent: $message");
            gc.handle(message);
          },
          // handle errors
          onError: (error) {
            print(error);
            ys.socket!.close();
          },
        );
  }
}
