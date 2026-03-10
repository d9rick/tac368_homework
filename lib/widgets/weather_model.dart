import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
// > flutter pub add flutter_bloc
import 'package:http/http.dart' as http;
// > flutter pub add http

const String weatherApiKey = 'afe374809c9a40c786d230944261003';

class WeatherModel {
  String cityName; // from location / name
  late double temperature; // C, from current / temp_c
  late double windSpeed; // kph, from current / wind_kph
  late String windDir; // e.g. SW, from current / wind_dir

  WeatherModel()
    : cityName = "city?",
      temperature = 999,
      windSpeed = 0,
      windDir = "N";

  WeatherModel.p4(
    this.cityName,
    this.temperature,
    this.windSpeed,
    this.windDir,
  );

  WeatherModel.fromJSON(dynamic response) : cityName = 'city?' {
    Map<String, dynamic> dataAsMap = jsonDecode(response.body);

    if (dataAsMap['error'] != null) {
      cityName = 'bad zip';
      temperature = 0;
      windSpeed = 0;
      windDir = 'N';
      return;
    }

    Map<String, dynamic> currentPart = dataAsMap['current'];
    Map<String, dynamic> locationPart = dataAsMap['location'];

    cityName = locationPart['name'];
    temperature = currentPart['temp_c'];
    windSpeed = currentPart['wind_kph'];
    windDir = currentPart['wind_dir'];
  }
}

class WeatherCubit extends Cubit<WeatherModel> {
  WeatherCubit() : super(WeatherModel());

  Future<void> update(String zip) async {
    final url = Uri.parse(
      'http://api.weatherapi.com/v1/current.json'
      '?key=$weatherApiKey&q=${zip.trim()}&aqi=no',
    );
    final response = await http.get(url);

    emit(WeatherModel.fromJSON(response));
  }
}
