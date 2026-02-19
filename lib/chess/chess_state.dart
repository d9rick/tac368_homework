// chess_state.dart
// Barrett Koster 2025

import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'coords.dart';

class ChessState
{
  List<List<String>> board;  // The state of the board is list
  // of columns, with each column listing pieces from 1 to 8.
  // [[a1,a2, ...],[b1,b2,...] ...
  // A character in the column is coded as lower case = white,
  // upper case = black.  p=pawn, r=rook, n=knight, b=bishop, 
  // q=quees, k=king.  Empty square is a space.
  // Additionally, we add a dot if the piece is eligible for
  // a special move on the next turn.  There are two possible
  // moves. 1. en passant.  a pawn that has just jumped 2 squares
  // (first move) is eligible to be captured by another pawn as
  // though it had only gone one square.  This lasts only through
  // the next side's turn.  
  // 2. A rook and king are eligible for castling if neither has
  // moved.  We signal this with a dot on each rook.  These dots
  // can persist indefinitely.  If a rook moves, its dot is gone.
  // If the king moves, both rook dots are gone.

  int turnCount; // nubmer of turns take, starts at 0,
                 // even is white's turn (odd is black's)

  ChessState() : board=
    [
      ['r.','p',' ',' ',' ',' ','P','R.'],
      ['n','p',' ',' ',' ',' ','P','N'],
      ['b','p',' ',' ',' ',' ','P','B'],
      ['q','p',' ',' ',' ',' ','P','Q'],
      ['k','p',' ',' ',' ',' ','P','K'],
      ['b','p',' ',' ',' ',' ','P','B'],
      ['n','p',' ',' ',' ',' ','P','N'],
      ['r.','p',' ',' ',' ',' ','P','R.'],
    ], turnCount = 0;

  ChessState.load( this.board, this.turnCount );
}

class ChessCubit extends HydratedCubit<ChessState>
{
  ChessCubit() : super( ChessState() );

  void update( Coords fromHere, Coords toHere )
  { state.board[toHere.c][toHere.r] = 
    state.board[fromHere.c][fromHere.r];
    state.board[fromHere.c][fromHere.r] = " ";
    emit( ChessState.load( state.board, state.turnCount+1) );
  }

  @override
  ChessState? fromJson( Map<String, dynamic> json )
  {
    try
    { List<List<String>> board = (json['board'] as List)
        .map( (col) => (col as List).map( (cell) => cell as String ).toList() )
        .toList();
      int turnCount = json['turnCount'] as int;
      return ChessState.load( board, turnCount );
    }
    catch (_) { return null; }
  }

  @override
  Map<String, dynamic>? toJson( ChessState state )
  {
    return
    { 'board': state.board,
      'turnCount': state.turnCount,
    };
  }
}