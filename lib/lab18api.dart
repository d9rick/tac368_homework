import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:tac368_homework/widgets/bb.dart';

void main() {
  runApp(const ApiPage());
}

class ApiPage extends StatelessWidget {
  const ApiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'api demo',
      home: Scaffold(
        appBar: AppBar(title: const Text('api demo')),
        body: BlocProvider<ApiCubit>(
          create: (context) => ApiCubit(),
          child: BlocBuilder<ApiCubit, ApiModel>(
            builder: (context, state) {
              return ApiView();
            },
          ),
        ),
      ),
    );
  }
}

class ApiView extends StatelessWidget {
  const ApiView({super.key});

  @override
  Widget build(BuildContext context) {
    ApiCubit apiCubit = BlocProvider.of<ApiCubit>(context);
    TextEditingController tec = TextEditingController();

    return Column(
      children: [
        Row(children: [BB('name '), BB(apiCubit.state.name)]),
        Row(children: [BB('predicted age'), BB('${apiCubit.state.age}')]),
        Row(children: [BB('sample size'), BB('${apiCubit.state.count}')]),
        Row(
          children: [
            BB('name '),
            SizedBox(
              height: 90,
              width: 200,
              child: TextField(
                controller: tec,
                style: const TextStyle(fontSize: 30),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                apiCubit.update(tec.text);
              },
              child: BB('update'),
            ),
          ],
        ),
      ],
    );
  }
}

class ApiModel {
  String name;
  int age;
  int count;

  ApiModel() : name = 'name?', age = 0, count = 0;

  ApiModel.fromJSON(dynamic response) : name = 'name?', age = 0, count = 0 {
    Map<String, dynamic> dataAsMap = jsonDecode(response.body);

    if (dataAsMap['name'] == null || dataAsMap['name'].toString().isEmpty) {
      name = 'bad name';
      age = 0;
      count = 0;
      return;
    }

    name = dataAsMap['name'] ?? 'name?';
    age = dataAsMap['age'] ?? 0;
    count = dataAsMap['count'] ?? 0;
  }
}

class ApiCubit extends Cubit<ApiModel> {
  ApiCubit() : super(ApiModel());

  Future<void> update(String name) async {
    final url = Uri.parse('https://api.agify.io?name=${name.trim()}');
    final response = await http.get(url);

    emit(ApiModel.fromJSON(response));
  }
}
