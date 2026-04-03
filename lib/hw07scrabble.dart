// scrabble.dart
// Derick Walker 2026
//
// Entry point for the two-player networked Scrabble game.
// Based on the TicTacToe networking pattern (lab20).
//
// Run this program twice:
//   1. First instance: click "server" to host the game
//   2. Second instance: enter the host IP (or "localhost") and click "client"
//
// The server generates the shared tile bag and sends it
// to the client. The server (host) takes the first turn.

import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

import "Scrabble/scrabble_server_state.dart";
import "TicTacToe/yak_state.dart";
import "Scrabble/scrabble_player.dart";

void main() {
  runApp(ScrabbleApp());
}

/// Splash screen: choose server or client role, set IP for client.
class ScrabbleApp extends StatelessWidget {
  ScrabbleApp({super.key});

  @override
  Widget build(BuildContext context) {
    TextEditingController tec = TextEditingController();
    tec.text = "localhost";

    return MaterialApp(
      title: "Scrabble",
      home: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text("Scrabble - choose role")),
          body: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ScrabbleServerBase(),
                      ),
                    );
                  },
                  child: Text("server"),
                ),
                SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ScrabbleClientBase(tec.text),
                      ),
                    );
                  },
                  child: Text("client"),
                ),
                SizedBox(width: 12),
                SizedBox(
                  width: 120,
                  height: 50,
                  child: TextField(
                    controller: tec,
                    style: TextStyle(fontSize: 20),
                    decoration: InputDecoration(labelText: "Host IP"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Server flow: create ServerSocket, wait for client to connect,
/// then show the game UI as the host player.
class ScrabbleServerBase extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<ScrabbleServerCubit>(
      create: (context) => ScrabbleServerCubit(),
      child: BlocBuilder<ScrabbleServerCubit, ScrabbleServerState>(
        builder: (context, state) {
          ScrabbleServerCubit sc = BlocProvider.of<ScrabbleServerCubit>(context);
          ScrabbleServerState ss = sc.state;

          // ServerSocket not yet created
          if (ss.server == null) {
            if (ss.error != null) {
              return Scaffold(
                appBar: AppBar(title: Text("Scrabble - Server")),
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(ss.error!),
                      SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => sc.connect(),
                        child: Text("retry"),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Scaffold(
              appBar: AppBar(title: Text("Scrabble - Server")),
              body: Center(child: Text("Starting server...")),
            );
          }

          // ServerSocket ready, wait for client connection
          return BlocProvider<YakCubit>(
            create: (context) => YakCubit.server(ss.server),
            child: BlocBuilder<YakCubit, YakState>(
              builder: (context, state) {
                YakCubit yc = BlocProvider.of<YakCubit>(context);
                YakState ys = yc.state;
                return ys.socket == null
                    ? Scaffold(
                        appBar: AppBar(title: Text("Scrabble - Server")),
                        body: Center(
                          child: Text("Waiting for client to connect..."),
                        ),
                      )
                    : ScrabblePlayer(true); // isHost = true
              },
            ),
          );
        },
      ),
    );
  }
}

/// Client flow: connect to the server, then show the game UI
/// as the client (non-host) player.
class ScrabbleClientBase extends StatelessWidget {
  final String ip;
  ScrabbleClientBase(this.ip, {super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<YakCubit>(
      create: (context) => YakCubit(ip),
      child: BlocBuilder<YakCubit, YakState>(
        builder: (context, state) {
          YakState ys = BlocProvider.of<YakCubit>(context).state;
          if (ys.socket == null) {
            return Scaffold(
              appBar: AppBar(title: Text("Scrabble - Client")),
              body: Center(child: Text("Connecting to $ip...")),
            );
          }
          return ScrabblePlayer(false); // isHost = false
        },
      ),
    );
  }
}
