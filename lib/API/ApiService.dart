import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_data.dart';
import '../models/hourly_data.dart';

class ApiService {
  static const String _URL = 'https://weather-api-nf24.onrender.com/api';

  Future<WeatherData> fetchWeather(double lat, double lon) async {
    final String url = '$_URL/weather/daily/$lat/$lon';

    try{
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

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
    final String url = '$_URL/weather/hourly/$lat/$lon';

    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> hourlyList = data['hourly'];
        return {
          'currentTime': data['currentTime'] ?? '',
          'hourly': hourlyList.map((item) => HourlyData.fromJson(item)).toList(),
        };
      } else {
        throw Exception('Failed to fetch hourly weather');
      }
    } catch (e) {
      throw Exception('An error occurred: $e');
    }
  }

  Future<List<HourlyData>> fetchFiveDayForecast(double lat, double lon) async {
    final String url = '$_URL/weather/forecast/$lat/$lon';

    try {
      final response = await http.get(Uri.parse(url))
          .timeout(const Duration(seconds: 30));
      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

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
    final String url = '$_URL/nearest-risk';

    try { final response = await http.get(Uri.parse(url)) .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception( 'Failed to fetch nearest risk. Server responded with ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('An error occurred: ${e.toString()}');
    }
  }

}
