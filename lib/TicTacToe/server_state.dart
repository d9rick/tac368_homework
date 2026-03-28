// server_state.dart
// Barrett Koster 2025

import "dart:io";
import 'package:flutter_bloc/flutter_bloc.dart';

// This class holds the ServerSocket, obvioiusly only
// for the server.  Creating the ServerSocket is async,
// so we launch the process of doing so in the constructor,
// and then when it succeeds, it emits a new state which
// has the ServerSocket in place.
class ServerState
{
  ServerSocket? server;
  String? error;

  ServerState(this.server, {this.error});
}

class ServerCubit extends Cubit<ServerState>
{
  // constructor.  start with null ServerSocket, but when
  // connect() succeeds, that will get replaced.
  ServerCubit() : super( ServerState(null) )
  { connect(); }

  Future<void> connect() async
  {
    emit(ServerState(null));

    try
    {
      await Future.delayed( const Duration(seconds:2) ); // adds drama
      // bind the socket server to an address and port
      ServerSocket s = await ServerSocket.bind(InternetAddress.anyIPv4, 9203);
      print("server socket created?");
      print("server ip ${s.address}");
      emit( ServerState(s) );
    }
    catch (e)
    {
      emit(ServerState(null, error: "Failed to start server on port 9203: $e"));
    }
  }
}
