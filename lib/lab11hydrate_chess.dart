// chess.dart
// Derick Walker 2026
// Modified Barrett Koster's chess code to use hydrated_bloc to save the state of the game.

import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'chess/chess.dart';

void main() async
{
  WidgetsFlutterBinding.ensureInitialized();
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: HydratedStorageDirectory(
      (await getApplicationDocumentsDirectory()).path,
    ),
  );
  runApp( Chess() );
}
