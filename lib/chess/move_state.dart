// move_state.dart
// Barrett Koster 2025

// This captures the state of the mouse having been
// clicked down at some Square, noted by Coords.
// When the mouse is let up, we make a move.  We do
// not need to RECORD this even as state.

import 'package:flutter_bloc/flutter_bloc.dart';

import 'coords.dart';
import 'chess_state.dart';

class MoveState
{
  Coords? mouseAt; // where the mouse was clicked
  bool dragging; // true == between two clicks

  MoveState( this.mouseAt, this.dragging );
}

class MoveCubit extends Cubit<MoveState>
{ MoveCubit() : super( MoveState(null,false) ) ;

  void mouseDown( Coords here, ChessCubit cc )
  { 
    if ( state.dragging ) // mouse already down, this is a move
    { if ( !here.equals(state.mouseAt!) )
      { 

      
        if ( state.mouseAt != null )
        { Coords temp = Coords(state.mouseAt!.c,state.mouseAt!.r);
          emit( MoveState(null,false) );
          cc.update( temp, here ); 
        }
        else
        { print("mouseAt is null -- how?"); }
      }
    }
    else // this is the first click of a move
    {   emit( MoveState(here,true) );
    }
  }
}

