// lab20tictactoe.dart.  for tic tac toe
// Barrett Koster
// Modified by Derick Walker 2026

// This is a start at tic tac toe on 2 machines, or
// at least 2 windows on one machine.
// Run this program twice, first selecting 'server' and
// second run selecting 'client'.

// version 2 adds the feature that you can set the IP for
// the client to call (before you click 'client').

/*
   must have
        <key>com.apple.security.network.client</key>
        <true/>
  in Runner/DebugProfile.entitlements and Runner/Release.entitlements

*/

import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

import "TicTacToe/server_state.dart";
import "TicTacToe/yak_state.dart";
import "TicTacToe/player.dart";

void main() {
  runApp(ServerOrClient());
}

// This is a spash page that gives the choices of
// server or client.
class ServerOrClient extends StatelessWidget {
  ServerOrClient({super.key});

  @override
  Widget build(BuildContext context) {
    TextEditingController tec = TextEditingController();
    tec.text = "localhost";

    return MaterialApp(
      title: "game",
      home: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text("which role?")),
          body: Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (context) => ServerBase()));
                },
                child: Text("server"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ClientBase(tec.text),
                    ),
                  );
                },
                child: Text("client"),
              ),
              SizedBox(
                width: 100,
                height: 50,
                child: TextField(
                  controller: tec,
                  style: TextStyle(fontSize: 25),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/*
  This is called when you choose 'server' from the splash screen.
  The sequence is a little tricky here.  We construct the ServerCubit,
  but the ServerSocket that gets created comes later, which causes the
  BlocBuilder for ServerCubit to rebuild.  And we do not want to
  construct the YakCubit until that happens (because the rebuild does
  not call the YakCubit constructor again).  So we issue a
  "loading" message until the ServerSocket exists.  THEN
  (when ServerCubit is rebuilt with an existing ServerSocket) we can
  tell the YakCubit to try to establish a connection.  The server
  version of YakCubit construction, i.e., YakCubit.server(ss), tells
  the ServerSocket ss to listen for a client to call, and when the
  client calls, THAT is the Socket that is the core of YakCubit.
*/
class ServerBase extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<ServerCubit>(
      create: (context) => ServerCubit(),
      child: BlocBuilder<ServerCubit, ServerState>(
        builder: (context, state) {
          ServerCubit sc = BlocProvider.of<ServerCubit>(context);
          ServerState ss = sc.state;
          if (ss.server == null) {
            if (ss.error != null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(ss.error!),
                    SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        sc.connect();
                      },
                      child: Text("retry"),
                    ),
                  ],
                ),
              );
            }
            return Center(child: Text("loading"));
          }

          return BlocProvider<YakCubit>(
            create: (context) => YakCubit.server(ss.server),
            child: BlocBuilder<YakCubit, YakState>(
              builder:
                  (context, state)
                  // => Player( false ), // this works but below is better
                  {
                    YakCubit yc = BlocProvider.of<YakCubit>(context);
                    YakState ys = yc.state;
                    return ys.socket == null
                        ? Text("waiting for client to call")
                        : Player(false);
                  },
            ),
          );
        },
      ),
    );
  }
}

/*
  The ClientBase is easier than the ServerBase.  YakCubit
  constructor (client version) calls the server and the resulting
  Socket is the connection core of YakCubit.  We could probably
  have a 'loading' message here too, because the call to the
  server is async, which means that we build Player onces and
  then have to do it again when the YakCubit socket gets
  created and BlocBuilder rebuilds from here down.
*/
class ClientBase extends StatelessWidget {
  final String ip;
  ClientBase(this.ip, {super.key});

  @override
  Widget build(BuildContext context) {
    print("------- ClientBase building ....");
    return BlocProvider<YakCubit>(
      create: (context) => YakCubit(ip),
      child: BlocBuilder<YakCubit, YakState>(
        builder: (context, state) => Player(true),
      ),
    );
  }
}
