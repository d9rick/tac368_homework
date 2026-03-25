// s4.dart.  This is a GUI demo of socket connections.
// Barrett Koster
// working from notes from Suragch

// modified by derick 2026 to maintain a chat log

// This runs with lab19client.dart.  Run this lab19server.dart first, then
// run lab19client.dart along with it.  They should communicate.
/*
   must have 
	<key>com.apple.security.network.client</key>
	<true/>
  in Runner/DebugProfile.entitlements and Runner/Release.entitlements


  for Android ...
  Open the android/app/src/main/AndroidManifest.xml file.
  Add the following permission inside the <manifest> tag, before the <application> tag:

      <uses-permission android:name="android.permission.INTERNET" />

*/

// server.listen() defines a function that gets
// called EVERY time a client calls the server.  We
// can make a server that handles lots of clients, but
// we start with one.

import 'dart:io';
import 'dart:typed_data';

import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class ConnectionState {
  bool listening = false; // true === server is waiting for a client to connect
  Socket? theClient = null; // the client's Socket when connected
  bool listened = false; // true === we are listening to client (we only
  // want to turn this on once, so ... )

  ConnectionState(this.listening, this.theClient, this.listened);
}

class ConnectionCubit extends Cubit<ConnectionState> {
  // constructor.  make empty start, but then launch the async
  // connect() that will make a connection.
  ConnectionCubit() : super(ConnectionState(false, null, false))
  // { if ( state.theClient==null) { connect(); } }
  {
    if (!state.listening) {
      connect();
    }
  }

  // when a connection is made, note the Socket
  update(bool b, Socket s) {
    emit(ConnectionState(b, s, state.listened));
  }

  // when we turn on listening on this Socket, make a not of that
  updateListen() {
    emit(ConnectionState(true, state.theClient, true));
  }

  // connect() creates a ServerSocket and then it waits/listens, possibly
  // forever, for Client to call.
  Future<void> connect() async {
    await Future.delayed(const Duration(seconds: 2)); // adds drama
    // bind the socket server to an address and port
    final server = await ServerSocket.bind(InternetAddress.anyIPv4, 9203);
    print("server socket created?");

    // listen for clent connections to the server.
    // When this function is triggered, it sets up the Sockets, nothing more.
    server.listen((client) {
      emit(ConnectionState(true, client, state.listened));
    });
    emit(ConnectionState(true, null, false));
    // print("server waiting for client");
  }
}

class SaidState {
  String said;

  SaidState(this.said);
}

class SaidCubit extends Cubit<SaidState> {
  SaidCubit() : super(SaidState("and so it begins ....\n"));

  // Append to keep an ongoing transcript instead of replacing the last line.
  void addLine(String s) {
    emit(SaidState("${state.said}$s\n"));
  }

  void update(String s) {
    emit(SaidState(s));
  }
}

void main() {
  runApp(Server());
}

// The Server class just has the BLoC layers.  Note that the
// Connection is outside the message, so we can connect once and
// then re-build the message many times.
class Server extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "server",
      home: BlocProvider<ConnectionCubit>(
        create: (context) => ConnectionCubit(),
        child: BlocBuilder<ConnectionCubit, ConnectionState>(
          builder: (context, state) => BlocProvider<SaidCubit>(
            create: (context) => SaidCubit(),
            child: BlocBuilder<SaidCubit, SaidState>(
              builder: (context, state) => Server2(),
            ),
          ),
        ),
      ),
    );
  }
}

// Server2 layer draws the window.  The window is
// 1. a text field where you can type stuff
// 2. a button to press to send what you typed
// 3. a text window showing what the other side has sent.
class Server2 extends StatelessWidget {
  final TextEditingController tec = TextEditingController();

  @override
  Widget build(BuildContext context) {
    ConnectionCubit cc = BlocProvider.of<ConnectionCubit>(context);
    ConnectionState cs = cc.state;
    SaidCubit sc = BlocProvider.of<SaidCubit>(context);

    // This 'listen' call is a little tricky.  We want to define the
    // listener only once, so you might suppose we would put this code outside
    // the message BLoC (which happens every time somebody says something).
    // But the listen function itself needs access to the message BLoC
    // because it uses the messagE BLoC to display what was heard.
    // So we have a 'listened' flag that gets set the first time, so we
    // only define Socket.listen( (){} ) once.
    if (cs.theClient != null && !cs.listened) {
      listen(context);
      // cc.updateListen(); // set the listened flag
    }

    return Scaffold(
      appBar: AppBar(title: Text("server")),
      body: Column(
        children: [
          // place to type message
          SizedBox(child: TextField(controller: tec)),
          // button to send message
          // (or "not ready" message if client is not there yet)
          cs.theClient != null
              ? ElevatedButton(
                  onPressed: () {
                    final message = tec.text.trim();
                    if (message.isEmpty) {
                      return;
                    }
                    cs.theClient!.write(message);
                    sc.addLine("me: $message");
                    tec.clear();
                  },
                  child: Text("send to client"),
                )
              : Text("not ready"),
          // message from the other process (or local message
          // if we are just getting started.
          cs.listening
              ? cs.theClient != null
                    ? Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(8),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Text(sc.state.said),
                          ),
                        ),
                      )
                    : Text("waiting for client to call ...")
              : Text("server loading ... "),
        ],
      ),
    );
  }

  // listen() tells the Socket to listen for messages from the
  // other side and what to do with them.    It assumes that
  // theClient is there (checking must occur before this call).
  // We also only want to do this ONCE.  We would have to
  // un-listen and then re-listen if we called this more than once.  ick.
  void listen(BuildContext bc) {
    ConnectionCubit cc = BlocProvider.of<ConnectionCubit>(bc);
    ConnectionState cs = cc.state;
    SaidCubit sc = BlocProvider.of<SaidCubit>(bc);

    cs.theClient!.listen(
      (Uint8List data) async {
        final message = String.fromCharCodes(data);
        sc.addLine("client: $message");
      },
      // handle errors
      onError: (error) {
        print(error);
        cs.theClient!.close();
      },
    );
    cc.updateListen();
  }
}
