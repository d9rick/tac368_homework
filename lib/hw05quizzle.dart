import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import "package:flutter_bloc/flutter_bloc.dart";
import "dart:math";

class QuizzleState {
  // holds the questions and answers
  List<String> questions;
  List<String> answers;

  int numQuestions;
  String questionType;
  String answerType;

  QuizzleState(this.questions, this.answers, this.numQuestions, this.questionType, this.answerType);
}

class QuizzleCubit extends Cubit<QuizzleState> {
  // load empty state
  QuizzleCubit() : super (QuizzleState([], [], 0, "", ""));

  Future<void> loadFromFile(String choice) async {
    try {
      // get the file contents
      final String content = await rootBundle.loadString('$choice');

      // grab the lines
      final List<String> lines = content.split('\n');

      // grab headers and delete top row
      final [questionType, answerType] = lines[0].trim().split(',');
      lines.removeAt(0);
      final int numQuestions = lines.length; 

      // get rest of question-answer pairs
      List<String> questions = [];
      List<String> answers = [];
      for(String line in lines) {
        if (line.isEmpty) continue;
    
        final List<String> pair = line.split(',');
        if (pair.length != 2) continue;

        questions.add(pair[0].trim());
        answers.add(pair[1].trim());
      }

      // update the state
      emit( QuizzleState(questions, answers, numQuestions, questionType, answerType) );
    } catch(e) {
      print("Error loading file: $e");
    }
  }
}

// handles the user's score
class UserState {
  int numCorrect;
  int numAttempted;
  int currentIndex;
  bool multipleChoice;

  UserState(this.numCorrect, this.numAttempted, this.currentIndex, this.multipleChoice);
}

class UserCubit extends Cubit<UserState> {
  UserCubit() : super( UserState(0, 0, 0, false));

  void addCorrect() {
    emit( UserState(state.numCorrect + 1, state.numAttempted + 1, state.currentIndex + 1, state.multipleChoice));
  }

  void addIncorrect() {
    emit( UserState(state.numCorrect, state.numAttempted + 1, state.currentIndex + 1, state.multipleChoice));
  }

  void toggleMultipleChoice() {
    emit( UserState(state.numCorrect, state.numAttempted, state.currentIndex, !state.multipleChoice));
  }

  void reset() {
    emit( UserState(0, 0, 0, state.multipleChoice));
  }
}

void main() {
  runApp(const Quizzle());
}

class QuizzleScreen extends StatelessWidget
{
  QuizzleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    QuizzleCubit qc = BlocProvider.of<QuizzleCubit>(context);
    QuizzleState qs = qc.state;
    UserCubit uc = BlocProvider.of<UserCubit>(context);
    UserState us = uc.state;

    return Scaffold
      ( appBar: AppBar( title: Text("Quizzle - Derick Walker") ),
        body: Center
        (
          
          child: Column
          (
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text
              (
                "Choose Your Quizzle",
                style:TextStyle(fontSize: 48)
              ),
              SizedBox(height: 20),
              Row
              (
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: ElevatedButton(
                      onPressed: () async {
                        uc.reset(); // reset before starting
                        await qc.loadFromFile("assets/Elements.txt");
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => MultiBlocProvider(
                            providers: [
                              BlocProvider.value(value: qc),
                              BlocProvider.value(value: context.read<UserCubit>()),
                            ],
                            child: QuizzleGame(),
                          ))
                        );
                      },
                      child: Text("Elements Quiz", style:TextStyle(fontSize: 24))
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: ElevatedButton(
                      onPressed: () async {
                        await qc.loadFromFile("assets/StateCapitals.txt");
                        uc.reset(); // reset before starting
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => MultiBlocProvider(
                            providers: [
                              BlocProvider.value(value: qc),
                              BlocProvider.value(value: context.read<UserCubit>()),
                            ],
                            child: QuizzleGame(),
                          ))
                        );
                      }, 
                      child: Text("State Capitals Quiz", style:TextStyle(fontSize: 24))
                    ),
                  )
                ]
              ),
              SizedBox(height: 14),
              BlocBuilder<UserCubit, UserState>(
                builder: (context, us) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Multiple Choice", style: TextStyle(fontSize: 18)),
                      Switch(
                        value: us.multipleChoice,
                        onChanged: (_) => uc.toggleMultipleChoice(),
                      ),
                    ],
                  );
                },
              )
            ],
          ) 
        )
      );
  }
}

class QuizzleGame extends StatelessWidget {
  QuizzleGame({super.key});

  String normalizeAnswer(String value) {
    return value.trim().toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    // import state
    QuizzleCubit qc = BlocProvider.of<QuizzleCubit>(context);
    QuizzleState qs = qc.state;
    UserCubit uc = BlocProvider.of<UserCubit>(context);
    UserState us = uc.state;

    // create txt controller for the input
    TextEditingController tec = TextEditingController();

    // handle confirmation page
    void handleAnswer(bool correct) {
      final int currentIndex = uc.state.currentIndex;
      final String currentCorrectAnswer = qs.answers[currentIndex];

      if (correct) {
        uc.addCorrect();
      } else {
        uc.addIncorrect();
      }
      tec.clear();

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: qc),
            BlocProvider.value(value: uc),
          ],
          child: correct ? CorrectScreen() : IncorrectScreen(correctAnswer: currentCorrectAnswer),
        ))
      );
    }

    return Scaffold
    (
      appBar: AppBar( title: Text("Quizzle - Derick Walker") ),
      body: Column (
        children: [
          // -- Score Counter --
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [ ScoreWidget() ]
          ),
          // -- Question area --
          Expanded(
            child: BlocBuilder<UserCubit, UserState>(
              builder: (context, us) {
                if (qs.questions.isEmpty) {
                  return Center(child: Text("Loading...", style: TextStyle(fontSize: 28)));
                }

                if (us.currentIndex >= qs.questions.length) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Quiz complete!", style: TextStyle(fontSize: 42)),
                        SizedBox(height: 12),
                        Text(
                          "Final Score: ${us.numCorrect}/${us.numAttempted}",
                          style: TextStyle(fontSize: 28),
                        ),
                        SizedBox(height: 24),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          child: ElevatedButton(
                            onPressed: () {
                              uc.reset();
                              Navigator.pop(context);
                            },
                            child: Text("Back to Menu", style: TextStyle(fontSize: 24)),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 700,
                        child: Text(
                          "What is the ${qs.answerType} of ${qs.questionType} ${qs.questions[us.currentIndex]}?",
                          style: TextStyle(fontSize: 32),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(height: 20),
                      if (us.multipleChoice)
                        Builder(
                          builder: (context) {
                            final random = Random();
                            final correct = qs.answers[us.currentIndex];

                            // get 3 unique wrong answers
                            List<String> wrongAnswers = List.from(qs.answers)..remove(correct);
                            wrongAnswers.shuffle(random);
                            wrongAnswers = wrongAnswers.take(3).toList();

                            // shuffle in the right one
                            final choices = [...wrongAnswers, correct]..shuffle(random);

                            return Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 12,
                              runSpacing: 12,
                              children: choices
                                  .map(
                                    (choice) => ElevatedButton(
                                      onPressed: () => handleAnswer(choice == correct),
                                      child: Text(choice, style: TextStyle(fontSize: 24)),
                                    ),
                                  )
                                  .toList(),
                            );
                          },
                        )
                      else
                        Column(
                          children: [
                            SizedBox(
                              width: 600,
                              child: TextField(
                                controller: tec,
                                style: TextStyle(fontSize: 20),
                                decoration: InputDecoration(
                                  hintText: "Type your answer...",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            SizedBox(height: 14),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              child: ElevatedButton(
                                onPressed: () {
                                  final currentUs = uc.state;
                                  final correct = normalizeAnswer(tec.text) ==
                                      normalizeAnswer(qs.answers[currentUs.currentIndex]);
                                  handleAnswer(correct);
                                },
                                child: Text("Check Answer", style: TextStyle(fontSize: 24)),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      )
    );
  }
}

class ScoreWidget extends StatelessWidget {  
  ScoreWidget({super.key});

  @override
  Widget build(BuildContext context) {
    UserCubit uc = BlocProvider.of<UserCubit>(context);
    UserState us = uc.state;

    return BlocBuilder<UserCubit, UserState>(
      builder: (context, us) {
        final int percent = us.numAttempted == 0
            ? 0
            : ((us.numCorrect / us.numAttempted) * 100).round();

        return Text(
          "Score: ${us.numCorrect}/${us.numAttempted} ($percent%)",
          style: TextStyle(fontSize: 26),  
        );
      },
    );
  }
}

class CorrectScreen extends StatelessWidget {
  const CorrectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Quizzle - Derick Walker")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Correct!", style: TextStyle(fontSize: 48, color: Colors.green)),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Next Question", style: TextStyle(fontSize: 24)),
            )
          ],
        ),
      ),
    );
  }
}

class IncorrectScreen extends StatelessWidget {
  final String correctAnswer;
  const IncorrectScreen({super.key, required this.correctAnswer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Quizzle - Derick Walker")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Incorrect!", style: TextStyle(fontSize: 48, color: Colors.red)),
            Text("The answer was: $correctAnswer", style: TextStyle(fontSize: 32)),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Next Question", style: TextStyle(fontSize: 24)),
            )
          ],
        ),
      ),
    );
  }
}

class Quizzle extends StatelessWidget {
  const Quizzle({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<QuizzleCubit>(create: (context) => QuizzleCubit()),
        BlocProvider<UserCubit>(create: (context) => UserCubit()),
      ],
      child: MaterialApp(
        title: "Quizzle - Derick Walker",
        home: QuizzleScreen(),
      ),
    );
  }
}