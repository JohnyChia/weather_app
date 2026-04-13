import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_animation/weather_animation.dart';
import 'package:weather_app/Screens/user_profile.dart';
import 'package:weather_app/Screens/weather_map.dart';
import '../Alarms/Admin/admin_alarms.dart';
import '../Alarms/User/user_alarms.dart';
import '../City/city_management.dart';
import '../Services/db_service.dart';
import '../Screens/astronomy.dart';
import '../Screens/chart.dart';
import 'package:weather_app/models/hourly_data.dart';
import '../Travel/travel_managment.dart';
import '../models/weather_data.dart';
import '../Services/location_service.dart';
import '../Services/api_service.dart';
import '../Services/notifications_services.dart';
import 'login.dart';
import 'weather_history.dart';


class WeatherScreen extends StatefulWidget {
  final String username;
  final String email;
  final String role;
  final String userId;

  const WeatherScreen({
    super.key,
    required this.username,
    required this.email,
    required this.role,
    required this.userId,
  });

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final LocationService _locationService = LocationService();
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  String? _errorMessage;
  WeatherData? _weatherData;
  List<HourlyData>? _hourlyForecast;
  List<HourlyData>? _fiveDayForecast;
  String? _city;
  Timer? _alarmTime;
  Set<String> triggeredAlarms = {};
  String _currentTime = '';
  String? _accusername;
  String? _accemail;
  String? _accprofileImage;
  String? _currentCondition;

  @override
  void initState() {
    super.initState();

    _loaduserData();

    _startAlarmMonitoring();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchWeatherData();
    });
  }

  @override
  void dispose() {
    _alarmTime?.cancel();
    super.dispose();
  }

  Future<void> _fetchWeatherData() async {
    setState(() {
      _isLoading = true;
    });
    debugPrint("Fetching weather...");

    try {
      final position = await _locationService.determinePosition();
      debugPrint("Position: $position");

      final cityName = await _locationService.getCity(position);
      debugPrint("City: $cityName");

      final fetchedWeatherData = await _apiService.fetchWeather(
          position.latitude, position.longitude);
      debugPrint("WeatherData: $fetchedWeatherData");

      final fetchedHourly = await _apiService.fetchHourlyForecast(
          position.latitude, position.longitude);
      debugPrint("HourlyForecast length: ${fetchedHourly.length}");

      final fetchedFiveDay = await _apiService.fetchFiveDayForecast(
          position.latitude, position.longitude);
      debugPrint("FiveDayForecast length: ${fetchedFiveDay.length}");

      await http.post(
          Uri.parse("https://weather-api-nf24.onrender.com/api/user/location"),
          body: {
            "user_id": widget.userId,
            "lat": position.latitude.toString(),
            "lon": position.longitude.toString(),
          },
      );

      final currentCondition = fetchedWeatherData.weatherMain;
      final List hourlyList = fetchedHourly['hourly'];

      setState(() {
        _city = cityName;
        _weatherData = fetchedWeatherData;
        _hourlyForecast = hourlyList
            .map((e) => HourlyData.fromJson(e))
            .toList();

        _currentTime = fetchedHourly['currentTime'];
        _fiveDayForecast = fetchedFiveDay;
        _currentCondition = currentCondition;
        _isLoading = false;
      });

      NotificationService().checkRainAndNotify(_hourlyForecast!);
      NotificationService().showUvNotify(_weatherData!.uvIndex);

    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      debugPrint("Error: $e");
    }
  }

  void _startAlarmMonitoring() {
    _checkAlarms();
    _alarmTime = Timer.periodic(const Duration(seconds: 10), (timer) {
      _checkAlarms();
    });
  }

  List<Map<String, dynamic>> nearbyAlarms = [];

  Future<void> _checkAlarms() async {
    try {
      final position = await _locationService.determinePosition();
      final alarms = await DbService.viewAll('alarms');

      nearbyAlarms.clear();

      for (var alarm in alarms) {
        if (alarm['lat'] == null || alarm['lon'] == null) continue;

        final double alarmLat = double.parse(alarm['lat'].toString());
        final double alarmLon = double.parse(alarm['lon'].toString());
        final distance = _calculateDistance(
            position.latitude, position.longitude, alarmLat, alarmLon);

        if (distance < 50) {
          nearbyAlarms.add(alarm);
          final alarmId = alarm['id'].toString();
          if (!triggeredAlarms.contains(alarmId)) {
            NotificationService().showAlertNotification(
              id: 4,
              title: "Weather Alert (${alarm['city']})",
              body: "${alarm['type']} - ${alarm['risk']}",
            );
            triggeredAlarms.add(alarm['id'].toString());
          }
        }
      }
    } catch (e) {
      throw Exception("Alarm check error: $e");
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371;
    double dLat = _degToRad(lat2 - lat1);
    double dLon = _degToRad(lon2 - lon1);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) * cos(_degToRad(lat2)) * sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c;
  }

  double _degToRad(double deg) {
    return deg * (pi / 180);
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      drawer: Drawer(
        backgroundColor: Colors.deepPurple.shade900,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 50),
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.deepPurple,
              ),
              accountName: Text(_accusername ?? ''),
              accountEmail: Text(_accemail ?? ''),
              currentAccountPicture: GestureDetector(
                onTap: () async {
                  Navigator.pop(context);

                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserProfile(
                        userId: widget.userId,
                      ),
                    ),
                  );

                  if (result == true) {
                    _reloadUser();
                  }
                },
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: _accprofileImage != null
                      ? FileImage(File(_accprofileImage!))
                      : null,
                  child: _accprofileImage == null
                      ? Text(
                    _accusername != null && _accusername!.isNotEmpty
                        ? _accusername![0].toUpperCase()
                        : "?",
                    style: const TextStyle(fontSize: 24),
                  )
                      : null,
                ),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.location_city, color: Colors.white),
              title: const Text('City', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CityManagement(userId: widget.userId),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.bar_chart, color: Colors.white),
              title: const Text('Chart', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);

                if (_weatherData != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ChartScreen(
                            hourlyData: _hourlyForecast!,
                            multiDays: _fiveDayForecast!,
                          ),
                    ),
                  );
                }
              },
            ),

            ListTile(
              leading: const Icon(Icons.map, color: Colors.white),
              title: const Text(
                  'Live Weather Map', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        MapScreen(
                          lat: _weatherData!.lat,
                          lon: _weatherData!.lon,
                        ),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.history, color: Colors.white),
              title: const Text(
                  'Weather History', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                if (_city != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          WeatherHistory(
                            userId: widget.userId,
                          ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("City not available yet")),
                  );
                }
              },
            ),

            ListTile(
              leading: const Icon(Icons.alarm, color: Colors.white),
              title: const Text('Severe Weather Center',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);

                if (widget.role == 'User') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          UserAlarms(
                            username: widget.username,
                            email: widget.email,
                            triggeredAlarms: nearbyAlarms,
                          ),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AdminAlarms(
                            username: widget.username,
                            email: widget.email,
                          ),
                    ),
                  );
                }
              },
            ),

            ListTile(
              leading: const Icon(Icons.sunny, color: Colors.white),
              title: const Text(
                  'Astronomy', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);

                if (_weatherData != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AstronomyScreen(
                            sunrise: _weatherData!.sunrise,
                            sunset: _weatherData!.sunset,
                            moonPhase: _weatherData!.moonPhase,
                            noon: _weatherData!.noon,
                            uvIndex: _weatherData!.uvIndex,
                            hourlyUV: _hourlyForecast,
                          ),
                    ),
                  );
                }
              },
            ),

            ListTile(
              leading: const Icon(Icons.airport_shuttle, color: Colors.white),
              title: const Text(
                  'Travel Plan', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) =>
                      TravelManagement(userId: widget.userId)),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.logout, color: Colors.white),
              title: const Text(
                  'Logout', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                await _logout();
              },
            ),
          ],
        ),

      ),

      body: Stack(
        children: [
          Positioned.fill(
            child: _isLoading || _weatherData == null
                ? Container(color: Colors.black)
                : _buildWeatherBackground(_currentCondition),
          ),

          Container(
            color: Colors.black.withValues(alpha: 0.1),
          ),

          SafeArea(
            child: _buildContent(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchWeatherData,
        tooltip: 'Refresh',
        backgroundColor: Colors.white,
        child: Icon(Icons.refresh, color: Colors.blue.shade700),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(_errorMessage!, textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 18)),
        ),
      );
    }
    if (_weatherData != null) {
      return SingleChildScrollView(
        child: _buildWeatherInfo(),
      );
    }
    return const Center(child: Text(
        'No weather data available', style: TextStyle(color: Colors.white)));
  }

  Widget _buildWeatherInfo() {
    final cityName = _city ?? '';
    final temp = _weatherData!.temperature.round();
    final bodyTemp = _weatherData!.bodyTemperature.round();
    final windSpeed = _weatherData!.windSpeed.round();
    final humidity = _weatherData!.humidity;
    final uv = _weatherData!.uvIndex.round();
    final aqi = _weatherData!.aqi;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 40.0,
          horizontal: 20.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// CITY
            Center(
              child: Text(
                cityName,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 10),

            /// WEATHER ICON
            Center(
              child: Image.asset(
                getWeatherIcon(_currentCondition),
                fit: BoxFit.contain,
              ),
            ),

            const SizedBox(height: 10),

            /// TEMP
            Center(
              child: Text(
                '$temp°',
                style: const TextStyle(
                  fontSize: 90,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 10),

            Center(
              child: Text(
                "Current Time: $_currentTime",
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),

            const SizedBox(height: 20),

            /// HOURLY TITLE
            const Text(
              'Hourly Forecast',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),

            const SizedBox(height: 10),

            /// HOURLY LIST
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: (_hourlyForecast?.length ?? 0) + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    // NOW card
                    return _buildNowHourlyItem();
                  }

                  final item = _hourlyForecast![index - 1];
                  return _buildHourlyItem(item, index);
                },
              ),
            ),

            const SizedBox(height: 20),

            /// INFO CARD
            Card(
              color: Colors.white.withValues(alpha: 0.2),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildInfoColumn(Icons.thermostat, 'Feels Like', '$bodyTemp°'),
                        _buildInfoColumn(Icons.air, 'Wind', '$windSpeed m/s'),
                        _buildInfoColumn(Icons.water_drop, 'Humidity', '$humidity%'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildInfoColumn(Icons.lightbulb_outline, 'UV Index', '$uv'),
                        _buildInfoColumn(Icons.masks, 'AQI', '$aqi'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            /// SAFE SPACE (IMPORTANT)
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildNowHourlyItem() {
    final pop = (_hourlyForecast != null && _hourlyForecast!.isNotEmpty)
        ? (_hourlyForecast![0].pop).toDouble()
        : 0.0;

    final condition = _currentCondition ?? "Clear";

    return Container(
      width: 75,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [

          const Text(
            "Now",
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),

          Image.asset(
            getWeatherIcon(condition),
            width: 35,
            height: 35,
          ),

          Text(
            "${(pop * 100).round()}%",
            style: const TextStyle(
              color: Colors.lightBlueAccent,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyItem(HourlyData item, int index) {
    final pop = (item.pop).toDouble();

    final isNow = index == 0;

    return Container(
      width: 80,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [

          // TIME
          Text(
            isNow ? "Now" : item.weatherTime,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),

          // ICON
          Image.asset(
            getWeatherIcon(item.condition),
            width: 35,
            height: 35,
          ),

          // TEMP (optional if you want)
          Text(
            '${item.temp.round()}°',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),

          // POP
          Text(
            isNow
                ? "Now"
                : '${(pop * 100).round()}%',
            style: const TextStyle(
              color: Colors.lightBlueAccent,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(IconData icon, String title, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 30),
        const SizedBox(height: 8),
        Text(
            title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 4),
        Text(value.toString(), style: const TextStyle(
            color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Future<void> _loaduserData() async {
    final data = await DbService.view('users', {
      'id': widget.userId
    });

    if (data.isNotEmpty) {
      final user = data.first;

      setState(() {
        _accusername = user['username'] ?? '';
        _accemail = user['email'] ?? '';
        _accprofileImage = user['profile_image'];
      });
    }
  }

  Widget _buildWeatherBackground(String? condition) {
    final c = condition?.toLowerCase() ?? '';

    if (c.contains('rain')) return const RainWidget();
    if (c.contains('drizzle')) return const RainWidget();
    if (c.contains('thunder')) return const ThunderWidget();
    if (c.contains('snow')) return const SnowWidget();
    if (c.contains('clear')) return const SunWidget();
    if (c.contains('cloud')) return const CloudWidget();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6FB1FF), Color(0xFFEAF6FF)],
        ),
      ),
    );
  }

  Future<void> _reloadUser() async {
    final data = await DbService.view('users', {'id': widget.userId});

    if (data.isNotEmpty) {
      final user = data[0];

      setState(() {
        _accusername = user['username'];
        _accemail = user['email'];
        _accprofileImage = user['profile_image'];
      });
    }
  }
}


String getWeatherIcon(String? condition) {
  final weather = condition?.toLowerCase();

  switch (weather) {
    case 'rain':
      return 'assets/images/rainy_2d.png';
    case 'drizzle':
      return 'assets/images/rainy_2d.png';
    case 'thunderstorm':
      return 'assets/images/thunder_2d.png';
    case 'clouds':
      return 'assets/images/sunny_2d.png';
    case 'snow':
      return 'assets/images/snow_2d.png';
    default:
      return 'assets/images/sunny_2d.png';
  }
}
