// scrabble_server_state.dart
// Derick Walker 2026
//
// ServerSocket setup for the Scrabble game.
// Copied from TicTacToe/server_state.dart with a fix
// for platforms where InternetAddress.anyIPv4 is unsupported.

import "dart:io";
import "package:flutter_bloc/flutter_bloc.dart";

/// Holds the ServerSocket once it has been created.
class ScrabbleServerState {
  ServerSocket? server;
  String? error;

  ScrabbleServerState(this.server, {this.error});
}

/// Creates a ServerSocket asynchronously. Emits a new state
/// once the socket is ready for client connections.
class ScrabbleServerCubit extends Cubit<ScrabbleServerState> {
  ScrabbleServerCubit() : super(ScrabbleServerState(null)) {
    connect();
  }

  Future<void> connect() async {
    emit(ScrabbleServerState(null));

    try {
      await Future.delayed(const Duration(seconds: 2));
      // Use loopbackIPv4 instead of anyIPv4 for Windows compatibility
      ServerSocket s =
          await ServerSocket.bind(InternetAddress.loopbackIPv4, 9203);
      print("server socket created at ${s.address}:${s.port}");
      emit(ScrabbleServerState(s));
    } catch (e) {
      emit(ScrabbleServerState(null,
          error: "Failed to start server on port 9203: $e"));
    }
  }
}
