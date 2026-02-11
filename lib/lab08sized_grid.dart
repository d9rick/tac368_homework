// 08sized_grid.dart
// Derick Walker  2025 
// lab
// let user increase or decrease the width and height of a grid of boxes. Uses BlocProvider to manage state.

import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

void main()
{ runApp(SG()); }

// Events
abstract class GridEvent {}

class IncrementWidth extends GridEvent {}
class DecrementWidth extends GridEvent {}
class IncrementHeight extends GridEvent {}
class DecrementHeight extends GridEvent {}

// State
class GridState {
  final int width;
  final int height;

  GridState({required this.width, required this.height});
}

// BLoC
class GridBloc extends Bloc<GridEvent, GridState> {
  GridBloc() : super(GridState(width: 4, height: 3)) {
    on<IncrementWidth>((event, emit) {
      emit(GridState(width: state.width + 1, height: state.height));
    });

    on<DecrementWidth>((event, emit) {
      if (state.width > 1) {
        emit(GridState(width: state.width - 1, height: state.height));
      }
    });

    on<IncrementHeight>((event, emit) {
      emit(GridState(width: state.width, height: state.height + 1));
    });

    on<DecrementHeight>((event, emit) {
      if (state.height > 1) {
        emit(GridState(width: state.width, height: state.height - 1));
      }
    });
  }
}

class SG extends StatelessWidget
{
  SG({super.key});

  Widget build( BuildContext context )
  {
    return MaterialApp
    ( title: "sized grid prep",
      home: BlocProvider
      ( create: (context) => GridBloc(),
        child: SG1(),
      ),
    );
  }
}

class SG1 extends StatelessWidget
{
  SG1({super.key});

  Widget build( BuildContext context )
  { 
    return Scaffold
    ( appBar: AppBar( title: Text("sized grid") ),
      body: BlocBuilder<GridBloc, GridState>
      ( builder: (context, state)
        {
          Row theGrid = Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children:[],
          );
          for ( int i=0; i<state.width; i++ )
          { Column c = Column(children:[]);
            for ( int j=0; j<state.height; j++ )
            { c.children.add( Boxy(40,40)  );
            }
            theGrid.children.add(c);
          }

          return Column
          ( crossAxisAlignment: CrossAxisAlignment.center,
            children:
            [ Padding
              ( padding: EdgeInsets.all(16.0),
                child: Row
                ( mainAxisAlignment: MainAxisAlignment.center,
                  children:
                  [ Text("Width: ${state.width}  "),
                    ElevatedButton
                    ( onPressed: () => context.read<GridBloc>().add(DecrementWidth()),
                      child: Icon(Icons.remove),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton
                    ( onPressed: () => context.read<GridBloc>().add(IncrementWidth()),
                      child: Icon(Icons.add),
                    ),
                    SizedBox(width: 24),
                    Text("Height: ${state.height}  "),
                    ElevatedButton
                    ( onPressed: () => context.read<GridBloc>().add(DecrementHeight()),
                      child: Icon(Icons.remove),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton
                    ( onPressed: () => context.read<GridBloc>().add(IncrementHeight()),
                      child: Icon(Icons.add),
                    ),
                  ],
                ),
              ),
              Text("Grid (${state.width} x ${state.height})"),
              SizedBox(height: 8),
              Center(child: theGrid),
              Text("after the grid"),
            ],
          );
        },
      ),
    );
  }
}

class Boxy extends Padding
{
  final double width;
  final double height;
  Boxy( this.width,this.height ) 
  : super
    ( padding: EdgeInsets.all(4.0),
      child: Container
      ( width: width, height: height,
        decoration: BoxDecoration
        ( border: Border.all(), ),
        child: Text("x"),
      ),
    );
}
