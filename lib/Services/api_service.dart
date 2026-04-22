import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/city_data.dart';
import '../models/weather_data.dart';
import '../models/hourly_data.dart';

class ApiService {
  static const String _url = 'https://weather-api-nf24.onrender.com/api';

  Future<City?> searchCity(String cityName) async {
    final res = await http.get(
      Uri.parse('$_url/city?search=$cityName'),
    );

    final data = jsonDecode(res.body);

    if (res.statusCode != 200 || data['city'] == null) {
      return null;
    }

    return City.fromJson({
      'city_name': data['city'],
      'country': data['country'],
      'lat': data['coordinates']['lat'],
      'lon': data['coordinates']['lon'],
      'temperature': data['temperature'],
      'condition': data['condition'],
      'timezone': data['timezone'],
    });
  }

  Future<WeatherData> fetchWeather(double lat, double lon) async {
    final String url = '$_url/weather/daily/$lat/$lon';

    try{
      final response = await http.get(Uri.parse(url)).timeout(
          const Duration(seconds: 30));

      if(response.statusCode == 200){
        final Map<String, dynamic> data = jsonDecode(response.body);
        return WeatherData.fromJson(data);

      }else{
        throw Exception('Failed to fetch weather. Server responded with ${response.statusCode}');
      }
    }catch(e){
      throw Exception('An error occurred: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> fetchHourlyForecast(double lat, double lon) async {
    final String url = '$_url/weather/hourly/$lat/$lon';

    try {
      final response = await http.get(Uri.parse(url)).timeout(
          const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception('Failed to fetch hourly weather');
      }
    } catch (e) {
      throw Exception('An error occurred: $e');
    }
  }

  Future<List<HourlyData>> fetchFiveDayForecast(double lat, double lon) async {
    final String url = '$_url/weather/forecast/$lat/$lon';

    try {
      final response = await http.get(Uri.parse(url)).timeout(
          const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => HourlyData.fromJson(item)).toList();
      } else {
        throw Exception(
            'Failed to fetch 5-day forecast. Server responded with ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('An error occurred: ${e.toString()}');
    }
  }

  Future<dynamic> fetchNearestRisk() async {
    final String url = '$_url/nearest-risk';

    try { final response = await http.get(Uri.parse(url)) .timeout(
        const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception('Failed to fetch nearest risk. Server responded with ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('An error occurred: ${e.toString()}');
    }
  }

}
