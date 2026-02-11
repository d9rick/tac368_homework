// 09groceries.dart
// Derick Walker
// This demos a simple grocery list app.

import "dart:io";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:path_provider/path_provider.dart";

class BufState
{ String text;
  bool loaded;

  BufState( this.text, this.loaded );
}

class BufCubit extends Cubit<BufState>
{
  BufCubit() : super( BufState("", false) );

  void update(String s) { emit( BufState(s,true) ); }

  void add(String s ) { emit( BufState("${state.text},$s",true) ); }

  void delete(int index) {
    List<String> items = state.text.split(",");
    items.removeAt(index);
    emit( BufState(items.join(","),true) );
  }

  Future<void> loadFromFile() async {
    try {
      Directory mainDir = await getApplicationDocumentsDirectory();
      String filePath = "${mainDir.path}/stuff.txt";
      File fodder = File(filePath);
      if (await fodder.exists()) {
        String contents = await fodder.readAsString();
        emit( BufState(contents, true) );
      }
    } catch (e) {
      print("Error loading file: $e");
    }
  }
}

void main() 
{ runApp( FileStuff () );
}

class FileStuff extends StatelessWidget
{
  FileStuff({super.key});

  Widget build( BuildContext context )
  { return MaterialApp
    ( title: "Grocery List - Derick Walker",
      home: BlocProvider<BufCubit>
      ( create: (context) {
          BufCubit bc = BufCubit();
          bc.loadFromFile();
          return bc;
        },
        child: BlocBuilder<BufCubit,BufState>
        ( builder: (context,state) => FileStuff2(),
        ),
      ),
    );
  }
}

class FileStuff2 extends StatelessWidget
{
  FileStuff2({super.key});

  @override
  Widget build( BuildContext context ) 
  { BufCubit bc = BlocProvider.of<BufCubit>(context);
    BufState bs = bc.state;

    TextEditingController tec = TextEditingController();
    // tec.text = bs.loaded ? bs.text : "not loaded yet";

    // Future<String> contents = readFile();
    // writeFile("hi there");
    return Scaffold
    ( appBar: AppBar( title: Text("Grocery List - Derick Walker") ),
      body: Column
      ( mainAxisAlignment: MainAxisAlignment.center,
        children:
        [ // box to show contents of the BufState
          makeListView(bs.text, bc),

          // place to type stuff
          Row
          ( mainAxisAlignment: MainAxisAlignment.center,
            children:
            [ Text("type here: "),
              Container
              ( height: 50, width: 500,
                decoration: BoxDecoration( border: Border.all(width:2) ),
                child: TextField
                (controller:tec, style: TextStyle(fontSize:20) ),
              ),
            ],
          ),

          // row of buttons
          Row
          ( mainAxisAlignment: MainAxisAlignment.center,
            children:
            [
              // shows where is the current directory
              FloatingActionButton
              ( onPressed: (){ whereAmI().then( (String c) { bc.add(c); }); },
                child: Text("Where", style:TextStyle(fontSize:18)),
              ),

              // add the typed text to the list
              FloatingActionButton
              ( onPressed: (){ bc.add(tec.text); },
                child: Text("Add", style:TextStyle(fontSize:20)),
              ),

              // clear the list
              FloatingActionButton
              ( onPressed: (){ bc.update(""); },
                child: Text("Clear", style:TextStyle(fontSize:20)),
              ),

              // loads from the file
              FloatingActionButton 
              ( onPressed: () async
                { String contents = await readFile(); 
                  bc.update(contents);
                },
                child: Text("Load", style:TextStyle(fontSize:20)),
              ),
            
              // saves to the file
              FloatingActionButton
              ( onPressed: (){ writeFile(bs.text); },
                child: Text("Save", style:TextStyle(fontSize:20)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // splits the string by commas to make a list of kids (Text objects), 
  // shows the kids in a vertical ListView widget in a Container with a 
  // border.
  Widget makeListView( String theString, BufCubit bc )
  { List<String> items =  theString.split(",");
    List<Widget> kids = [];
    for ( int i = 0; i < items.length; i++ )
    { kids.add(
        Align(
          alignment: Alignment.topLeft, 
          child: Row(
            children: [
              Expanded(child: Text(items[i])),
              IconButton(
                icon: Icon(Icons.delete, size: 20),
                onPressed: () { bc.delete(i); },
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
            ],
          ),
        )
      ); 
    }
    return Container
    ( height:300, width:700,
      decoration: BoxDecoration( border:Border.all(width:1)),
      child: ListView 
      ( scrollDirection: Axis.vertical,
        itemExtent: 30,
        children: kids,
      ),
    );
  }

  Future<String> whereAmI() async
  {
    Directory mainDir = await getApplicationDocumentsDirectory();
    String mainDirPath = mainDir.path;
    // String mainDirPath = "/Users/bkoster/Documents/courses/USC/368/shared";
    print("mainDirPath is $mainDirPath");
    return mainDirPath;
  }
  
  Future<String> readFile() async
  { await Future.delayed( const Duration(seconds:2) ); // adds drama
    String myStuff = await whereAmI();
    String filePath = "$myStuff/stuff.txt";
    File fodder = File(filePath);
    String contents = fodder.readAsStringSync();
    print("-------------in readFile ...");
    print(contents);
    return contents;
  }

  Future<void> writeFile( String writeMe) async
  { String myStuff = await whereAmI();
    String filePath = "$myStuff/stuff.txt";
    print("about to write to $filePath");
    File fodder = File(filePath);
    fodder.writeAsStringSync( writeMe );
  }
}