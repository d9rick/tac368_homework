// lab10madlib.dart
// Derick Walker
// This demos a simple Madlib app with file input.

// The story template is loaded from a file (madlib.txt). It first checks
// the device's documents directory for a user-saved version; if none is
// found it falls back to the bundled asset. Blanks are marked with
// "$ type" (e.g. "$ animal") and back-references with "% n" (e.g. "% 1"
// reuses the answer from the second blank). Users can also edit and save
// new story templates from within the app.

import "dart:io";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:path_provider/path_provider.dart";

// State

class MadlibState
{ String rawStory;       // the template loaded from file
  List<String> blanks;   // the types of words needed ("place", "animal", …)
  List<String> answers;  // what the user has typed for each blank
  bool loaded;           // whether the file has been loaded
  bool revealed;         // whether the finished story is showing

  MadlibState( this.rawStory, this.blanks, this.answers,
               this.loaded, this.revealed );
}

// Cubit

class MadlibCubit extends Cubit<MadlibState>
{
  MadlibCubit() : super( MadlibState("", [], [], false, false) );

  // Load the story template from a file in the documents directory.
  // Falls back to the bundled asset if no file is found on disk.
  Future<void> loadFromFile() async {
    String contents = "";
    try {
      Directory mainDir = await getApplicationDocumentsDirectory();
      String filePath = "${mainDir.path}/madlib.txt";
      File fodder = File(filePath);
      if (await fodder.exists()) {
        contents = await fodder.readAsString();
      } else {
        // fall back to the bundled asset
        contents = await rootBundle.loadString("assets/madlib.txt");
      }
    } catch (e) {
      // last resort: fall back to asset
      try {
        contents = await rootBundle.loadString("assets/madlib.txt");
      } catch (e2) {
        print("Error loading madlib file: $e2");
      }
    }
    _parseStory(contents);
  }

  // Save a new story template to the documents directory.
  Future<void> saveStory(String storyText) async {
    try {
      Directory mainDir = await getApplicationDocumentsDirectory();
      String filePath = "${mainDir.path}/madlib.txt";
      File fodder = File(filePath);
      fodder.writeAsStringSync(storyText);
    } catch (e) {
      print("Error saving story: $e");
    }
    _parseStory(storyText);
  }

  // Parse the raw template: find every "$ type" blank.
  void _parseStory(String contents) {
    List<String> blanks = [];
    RegExp blankPattern = RegExp(r'\$ (\w+)');
    for (RegExpMatch m in blankPattern.allMatches(contents)) {
      blanks.add(m.group(1)!);
    }
    List<String> answers = List.filled(blanks.length, "");
    emit( MadlibState(contents, blanks, answers, true, false) );
  }

  // Update one answer.
  void setAnswer(int index, String value) {
    List<String> updated = List.from(state.answers);
    updated[index] = value;
    emit( MadlibState(state.rawStory, state.blanks, updated,
                      state.loaded, state.revealed) );
  }

  // Show the finished story.
  void reveal() {
    emit( MadlibState(state.rawStory, state.blanks, state.answers,
                      state.loaded, true) );
  }

  // Reset so the user can play again.
  void reset() {
    List<String> answers = List.filled(state.blanks.length, "");
    emit( MadlibState(state.rawStory, state.blanks, answers,
                      state.loaded, false) );
  }

  // Build the final story by replacing blanks and back‑references.
  String buildStory() {
    String story = state.rawStory;

    // replace "$ type" tokens with user answers (in order).
    int i = 0;
    story = story.replaceAllMapped(RegExp(r'\$ \w+'), (match) {
      String replacement = (i < state.answers.length && state.answers[i].isNotEmpty)
          ? state.answers[i]
          : "___";
      i++;
      return replacement;
    });

    // replace "% n" back‑references.
    story = story.replaceAllMapped(RegExp(r'% (\d+)'), (match) {
      int idx = int.parse(match.group(1)!);
      if (idx < state.answers.length && state.answers[idx].isNotEmpty) {
        return state.answers[idx];
      }
      return "___";
    });

    return story;
  }
}

void main()
{ runApp( MadlibApp() );
}



class MadlibApp extends StatelessWidget
{
  MadlibApp({super.key});

  @override
  Widget build( BuildContext context )
  { return MaterialApp
    ( title: "Madlib - Derick Walker",
      home: BlocProvider<MadlibCubit>
      ( create: (context) {
          MadlibCubit mc = MadlibCubit();
          mc.loadFromFile();
          return mc;
        },
        child: BlocBuilder<MadlibCubit,MadlibState>
        ( builder: (context,state) => MadlibPage(),
        ),
      ),
    );
  }
}

// Main page

class MadlibPage extends StatelessWidget
{
  MadlibPage({super.key});

  @override
  Widget build( BuildContext context )
  { MadlibCubit mc = BlocProvider.of<MadlibCubit>(context);
    MadlibState  ms = mc.state;

    TextEditingController storyTec = TextEditingController();

    if (!ms.loaded) {
      return Scaffold
      ( appBar: AppBar( title: Text("Madlib - Derick Walker") ),
        body: Center( child: Text("Loading story…") ),
      );
    }

    return Scaffold
    ( appBar: AppBar( title: Text("Madlib - Derick Walker") ),
      body: SingleChildScrollView
      ( child: Center
        ( child: Column
          ( mainAxisAlignment: MainAxisAlignment.center,
            children:
            [ SizedBox(height: 20),

              // blank input fields
              Text("Fill in the blanks:", style: TextStyle(fontSize: 22)),
              SizedBox(height: 10),
              ...makeBlanks(ms, mc),

              SizedBox(height: 20),

              // buttons row
              Row
              ( mainAxisAlignment: MainAxisAlignment.center,
                children:
                [
                  // reveal the story
                  FloatingActionButton.extended
                  ( heroTag: "go",
                    onPressed: (){ mc.reveal(); },
                    label: Text("Go!", style: TextStyle(fontSize: 20)),
                  ),

                  SizedBox(width: 10),

                  // reset answers
                  FloatingActionButton.extended
                  ( heroTag: "reset",
                    onPressed: (){ mc.reset(); },
                    label: Text("Reset", style: TextStyle(fontSize: 20)),
                  ),

                  SizedBox(width: 10),

                  // load from file
                  FloatingActionButton.extended
                  ( heroTag: "load",
                    onPressed: () async { await mc.loadFromFile(); },
                    label: Text("Load", style: TextStyle(fontSize: 20)),
                  ),
                ],
              ),

              SizedBox(height: 20),

              // story display (always visible)
              Container
              ( width: 700,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration
                ( border: Border.all(width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text
                ( ms.revealed ? mc.buildStory() : ms.rawStory,
                  style: TextStyle(fontSize: 20),
                ),
              ),

              SizedBox(height: 30),

              // story editor section
              Text("Edit / paste a new story template:",
                   style: TextStyle(fontSize: 18)),
              SizedBox(height: 5),
              Text("Use \"\$ type\" for blanks and \"% n\" for back-references.",
                   style: TextStyle(fontSize: 14, color: Colors.grey)),
              SizedBox(height: 5),
              Container
              ( width: 700, height: 120,
                decoration: BoxDecoration( border: Border.all(width: 1) ),
                child: TextField
                ( controller: storyTec,
                  maxLines: null,
                  expands: true,
                  style: TextStyle(fontSize: 16),
                ),
              ),
              SizedBox(height: 5),
              FloatingActionButton.extended
              ( heroTag: "save",
                onPressed: ()
                { mc.saveStory(storyTec.text); },
                label: Text("Save Story", style: TextStyle(fontSize: 18)),
              ),

              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // Build a list of text‑field rows, one per blank.
  List<Widget> makeBlanks( MadlibState ms, MadlibCubit mc )
  { List<Widget> rows = [];
    for (int i = 0; i < ms.blanks.length; i++)
    { rows.add( BlankField( label: ms.blanks[i], index: i, mc: mc ) );
    }
    return rows;
  }
}

// Stateful widget so each blank owns its own TextEditingController
// and doesn't reset the cursor on parent rebuilds.
class BlankField extends StatefulWidget
{ final String label;
  final int index;
  final MadlibCubit mc;

  const BlankField({ super.key,
    required this.label, required this.index, required this.mc });

  @override
  State<BlankField> createState() => _BlankFieldState();
}

class _BlankFieldState extends State<BlankField>
{ late TextEditingController tec;

  @override
  void initState()
  { super.initState();
    tec = TextEditingController();
  }

  @override
  void dispose()
  { tec.dispose();
    super.dispose();
  }

  @override
  Widget build( BuildContext context )
  { return Padding
    ( padding: EdgeInsets.symmetric(vertical: 4),
      child: Row
      ( mainAxisAlignment: MainAxisAlignment.center,
        children:
        [ SizedBox
          ( width: 160,
            child: Text("Enter a ${widget.label}:",
                         style: TextStyle(fontSize: 18)),
          ),
          Container
          ( height: 45, width: 300,
            decoration: BoxDecoration( border: Border.all(width: 2) ),
            child: TextField
            ( controller: tec,
              style: TextStyle(fontSize: 18),
              onChanged: (value) { widget.mc.setAnswer(widget.index, value); },
            ),
          ),
        ],
      ),
    );
  }
}
