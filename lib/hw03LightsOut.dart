// hw03LightsOut.dart
// Derick Walker  2025 
// lab
// let user increase or decrease the number of cells in a row. Uses BlocProvider to manage state.

import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "dart:math";

void main()
{ runApp(SG()); }

// Events
abstract class GridEvent {}

class IncrementCells extends GridEvent {}
class DecrementCells extends GridEvent {}
class SetCells extends GridEvent {
  final int count;
  SetCells(this.count);
}
class ToggleCell extends GridEvent {
  final int index;
  ToggleCell(this.index);
}
class RestartGame extends GridEvent {}

// State
class GridState {
  final int cellCount;
  final List<bool> cellStates;

  GridState({required this.cellCount, required this.cellStates});
}

// BLoC
class GridBloc extends Bloc<GridEvent, GridState> {
  GridBloc() : super(GridState(
    cellCount: 9, 
    cellStates: List.generate(9, (_) => Random().nextBool())
  )) {
    on<IncrementCells>((event, emit) {
      List<bool> newStates = List.from(state.cellStates)..add(Random().nextBool());
      emit(GridState(cellCount: state.cellCount + 1, cellStates: newStates));
    });

    // handles decrementing cells by removing the last cell and its state
    on<DecrementCells>((event, emit) {
      if (state.cellCount > 1) {
        List<bool> newStates = List.from(state.cellStates)..removeLast();
        emit(GridState(cellCount: state.cellCount - 1, cellStates: newStates));
      }
    });

    // handles setting the number of cells directly
    on<SetCells>((event, emit) {
      if (event.count > 0) {
        emit(GridState(cellCount: event.count, cellStates: List.generate(event.count, (_) => Random().nextBool())));
      }
    });

    // handles toggling a cell and its neighbors
    on<ToggleCell>((event, emit) {
      List<bool> newStates = List.from(state.cellStates);
      // Toggle the clicked cell
      newStates[event.index] = !newStates[event.index];
      // Toggle left neighbor if it exists
      if (event.index > 0) {
        newStates[event.index - 1] = !newStates[event.index - 1];
      }
      // Toggle right neighbor if it exists
      if (event.index < state.cellCount - 1) {
        newStates[event.index + 1] = !newStates[event.index + 1];
      }
      emit(GridState(cellCount: state.cellCount, cellStates: newStates));
    });

    // handles restarting the game by resetting all cells to random states
    on<RestartGame>((event, emit) {
      emit(GridState(
        cellCount: state.cellCount,
        cellStates: List.generate(state.cellCount, (_) => Random().nextBool())
      ));
    });
  }
}

class SG extends StatelessWidget
{
  SG({super.key});

  Widget build( BuildContext context )
  {
    return MaterialApp
    ( title: "Lights Out",
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

  final TextEditingController _controller = TextEditingController();

  Widget build( BuildContext context )
  { 
    return Scaffold
    ( appBar: AppBar( title: Text("Lights Out") ),
      body: BlocBuilder<GridBloc, GridState>
      ( builder: (context, state)
        {
          // Check if all lights are out (win condition)
          bool allOff = state.cellStates.every((isOn) => !isOn);
          
          // give a win popup and a button to restart
          if (allOff) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext dialogContext) {
                  return AlertDialog(
                    title: Text('Congratulations!'),
                    content: Text('You turned off all the lights!'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          context.read<GridBloc>().add(RestartGame());
                        },
                        child: Text('Restart'),
                      ),
                    ],
                  );
                },
              );
            });
          }
          
          Row theGrid = Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children:[],
          );
          for ( int i=0; i<state.cellCount; i++ )
          { 
            theGrid.children.add( 
              GestureDetector(
                onTap: () => context.read<GridBloc>().add(ToggleCell(i)),
                child: Boxy(60, 60, state.cellStates[i]),
              ),
            );
          }

          return Column
          ( crossAxisAlignment: CrossAxisAlignment.center,
            children:
            [ SizedBox(height: 16),
              Center(child: theGrid),
              SizedBox(height: 24),
              Padding
              ( padding: EdgeInsets.all(16.0),
                child: Row
                ( mainAxisAlignment: MainAxisAlignment.center,
                  children:
                  [ Text("Cells: ${state.cellCount}  "),
                    ElevatedButton
                    ( onPressed: () => context.read<GridBloc>().add(DecrementCells()),
                      child: Icon(Icons.remove),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton
                    ( onPressed: () => context.read<GridBloc>().add(IncrementCells()),
                      child: Icon(Icons.add),
                    ),
                  ],
                ),
              ),
              Padding
              ( padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Row
                ( mainAxisAlignment: MainAxisAlignment.center,
                  children:
                  [ SizedBox
                    ( width: 100,
                      child: TextField
                      ( controller: _controller,
                        decoration: InputDecoration
                        ( labelText: "Count",
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton
                    ( onPressed: ()
                      { 
                        int? value = int.tryParse(_controller.text);
                        if (value != null) {
                          context.read<GridBloc>().add(SetCells(value));
                          _controller.clear();
                        }
                      },
                      child: Text("Submit"),
                    ),
                  ],
                ),
              ),
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
  final bool isOn;
  
  Boxy( this.width, this.height, this.isOn ) 
  : super
    ( padding: EdgeInsets.all(1.0),
      child: Container
      ( width: width, height: height,
        decoration: BoxDecoration
        ( border: Border.all(color: Colors.black, width: 2),
          color: isOn ? Colors.yellow : Colors.brown,
        ),
      ),
    );
}
