// chess.dart
// Barrett Koster 2015
// This is starter code.  This is a pretty plain
// chess shell that does NOT remember the state of
// the game.  

// Derick Walker 2026
// Modified Barrett Koster's chess code to use hydrated_bloc to save the state of the game.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'chess_state.dart';
import 'move_state.dart';
import 'coords.dart';

class Chess extends StatelessWidget
{
  const Chess({super.key});

  @override
  Widget build( BuildContext context )
  {
    return MaterialApp
    ( title: "chess",
      home: BlocProvider<ChessCubit> 
      ( create: (context) => ChessCubit(),
        child: BlocBuilder<ChessCubit,ChessState>
        ( builder: (context,state) => 
          BlocProvider<MoveCubit>
          ( create: (context) => MoveCubit(),
            child: BlocBuilder<MoveCubit,MoveState>
            ( builder: (context,state) => Chess1(),
            ),
          ),
        ),
      ),
    );
  }
}

class Chess1 extends StatelessWidget
{
  @override
  Widget build( BuildContext context )
  { //ChessCubit cc = BlocProvider.of<ChessCubit>(context);
    //ChessState cs = cc.state;

    return Scaffold
    ( appBar: AppBar( title: Text("chess") ),
      body: drawBoard(context), // Text('board goes here'),
    
    );
  }

  Widget drawBoard( BuildContext context )
  { ChessCubit cc = BlocProvider.of<ChessCubit>(context);
    ChessState cs = cc.state;

    Column theGrid = Column(children:[]);
    
    if ( cs.turnCount%2==0 ) // white's turn, draw rank 1 at bottom
    { 
      for ( int row=7; row>=0; row-- ) // raster, draw board from highest rank
      { Row r = Row(children:[]);
        for ( int col=0; col<8; col++ )
        { r.children.add(Square(Coords(col,row), cs.board[col][row]) );
        }
        theGrid.children.add(r);
      }
    }
    else
    {
      for ( int row=0; row<8; row++ )
      { Row r = Row(children:[]);
        for ( int col=7; col>=0; col-- )
        { r.children.add( Square(Coords(col,row), cs.board[col][row]) ); 
        }
        theGrid.children.add(r);
      }
    }

    return theGrid;
  }
}

class Square extends StatelessWidget
{
  final Coords here;
  final String letter;
  final bool light; // true means light colored square
  Square(this.here, this.letter) : light = ( (here.r+here.c)%2==1 )
  { print("Square constructor .. coords = ${here.c},${here.r}");}

  @override
  Widget build( BuildContext context )
  { MoveCubit mc = BlocProvider.of<MoveCubit>(context);
    ChessCubit cc = BlocProvider.of<ChessCubit>(context);

    return Listener
    ( onPointerDown: (_)
      { print("mouse down at  ${here.c},${here.r}");
        mc.mouseDown(here, cc); 
      },
      child:  Container
      ( height:40, width: 40,
        decoration: BoxDecoration
        ( color: light? Colors.white : Colors.grey,
          border: Border.all(), 
        ),
        child: Text(letter, style:TextStyle(fontSize:30)),
      )
    )
    ;
  }
}

