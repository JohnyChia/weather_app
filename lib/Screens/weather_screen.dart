import 'package:flutter/material.dart';
import 'package:weather_app/Screens/weather_map.dart';
import '../Screens/Astronomy.dart';
import '../Screens/Chart.dart';
import 'package:weather_app/models/hourly_data.dart';
import '../models/weather_data.dart';
import '../Location/LocationService.dart';
import '../API/ApiService.dart';

String getWeatherIcon(String? weatherMain) {
  final weather = weatherMain?.toLowerCase();

  switch (weather) {
    case 'Rain':
      return 'assets/images/rainy_2d.png';
    case 'Drizzle':
      return 'assets/images/rainy_2d.png';
    case 'Thunderstorm':
      return 'assets/images/thunder_2d.png';
    case 'Clouds':
      return 'assets/images/sunny_2d.png';
    case 'Snow':
      return 'assets/images/snow_2d.png';
    default:
      return 'assets/images/sunny_2d.png';
  }
}


class WeatherScreen extends StatefulWidget {
  final String username;
  final String email;
  final String role;

  const WeatherScreen({
    super.key,
    required this.username,
    required this.email,
    required this.role,
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchWeatherData());

    // 2️⃣ 预加载所有可能用到的图片，避免首次显示黑屏
    final imageList = [
      'assets/images/sunny.png',
      'assets/images/rainy.png',
      'assets/images/thunder.png',
      'assets/images/snow.png',
      'assets/images/sunny_2d.png',
      'assets/images/rainy_2d.png',
      'assets/images/thunder_2d.png',
      'assets/images/snow_2d.png',
    ];
    for (var img in imageList) {
      precacheImage(AssetImage(img), context);
    }
  }

  Future<void> _fetchWeatherData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final position = await _locationService.determinePosition();
      final cityName = await _locationService.getCity(position);

      final weather = await Future.wait([
        _apiService.fetchWeather(position.latitude, position.longitude),
        _apiService.fetchHourlyForecast(position.latitude, position.longitude),
        _apiService.fetchFiveDayForecast(position.latitude, position.longitude),
      ]);

      setState(() {
        _city = cityName;
        _weatherData = weather[0] as WeatherData?;
        _hourlyForecast = weather[1] as List<HourlyData>?;
        _fiveDayForecast = weather[2] as List<HourlyData>?;
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  String _getBackgroundImage(String? weatherMain) {
    final weather = weatherMain?.toLowerCase();

    switch (weather) {
      case 'Rain':
        return 'assets/images/rainy.png';
      case 'Drizzle':
        return 'assets/images/rainy.png';
      case 'Thunderstorm':
        return 'assets/images/thunder.png';
      case 'Clouds':
        return 'assets/images/sunny.png';
      case 'Snow':
        return 'assets/images/snow.png';
      default:
        return 'assets/images/sunny.png';
    }
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
              accountName: Text(widget.username),
              accountEmail: Text(widget.email),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  widget.username.isNotEmpty
                      ? widget.username[0].toUpperCase()
                      : "?",
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.location_city, color: Colors.white),
              title: const Text('City', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
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
                      builder: (context) => ChartScreen(
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
              title: const Text('Live Weather Map', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MapScreen(
                      lat: _weatherData!.lat,
                      lon: _weatherData!.lon,
                    ),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.history, color: Colors.white),
              title: const Text('Weather History', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
              },
            ),

            ListTile(
              leading: const Icon(Icons.notifications, color: Colors.white),
              title: const Text('Notifications', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
              },
            ),

            ListTile(
              leading: const Icon(Icons.alarm, color: Colors.white),
              title: const Text('Severe Weather Center', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
              },
            ),

            ListTile(
              leading: const Icon(Icons.sunny, color: Colors.white),
              title: const Text('Astronomy', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);

                if (_weatherData != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AstronomyScreen(
                        sunrise: _weatherData!.sunrise,
                        sunset: _weatherData!.sunset,
                        moonrise: _weatherData!.moonrise,
                        moonset: _weatherData!.moonset,
                        moonPhase: _weatherData!.moonPhase,
                        uvIndex: _weatherData!.uvIndex,
                        hourlyUV: _hourlyForecast,
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),

      ),

      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.deepPurple.shade900,
                  Colors.deepPurple.shade600,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            height: double.infinity,
            width: double.infinity,
          ),
          Container(
            color: Colors.black.withOpacity(0.5),
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
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18)),
        ),
      );
    }
    if (_weatherData != null) {
      return SingleChildScrollView(
        child: _buildWeatherInfo(),
      );
    }
    return const Center(child: Text('No weather data available', style: TextStyle(color: Colors.white)));
  }

  Widget _buildWeatherInfo() {
    final cityName = _city ?? '';
    final temp = _weatherData!.temperature.round();
    final bodyTemp = _weatherData!.bodyTemperature.round();
    final windSpeed = _weatherData!.windSpeed.round();
    final humidity = _weatherData!.humidity;
    final uv = _weatherData!.uvIndex.round();
    final aqi = _weatherData!.aqi;

    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: 40.0,
          horizontal: 20.0
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
              cityName,
              style:
              const TextStyle(
                  fontSize: 32,
                  fontWeight:
                  FontWeight.bold,
                  color: Colors.white
              )),
          const SizedBox(height: 10),

          Image.asset(
            _getBackgroundImage(_weatherData?.weatherMain),
            width: 200,
            height: 200,
            fit: BoxFit.cover,
          ),

          Text(
              '$temp°',
               style:
               const TextStyle(
                   fontSize: 100,
                   fontWeight: FontWeight.bold,
                   color: Colors.white
               )),
          const SizedBox(height: 25),

          const Text(
              'Hourly Forecast',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70
              )),
          const SizedBox(height: 15),

          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _hourlyForecast?.length ?? 0,
              itemBuilder: (context, index) {
                final item = _hourlyForecast![index];
                return _buildHourlyItem(item);
              },
            ),
          ),
          const SizedBox(height: 25),

          Card(
            color: Colors.black.withOpacity(0.5),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
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
        ],
      ),
    );
  }

  Widget _buildHourlyItem(HourlyData item) {
    return Container(
      width: 75,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            item.weatherTime,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold
            ),
          ),
          const SizedBox(height: 8),

          Image.asset(
            getWeatherIcon(item.condition),
            width: 50,
            height: 50,
          ),

          const SizedBox(height: 8),

          Text(
            '${item.temp.round()}°',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
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
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 4),
        Text(value.toString(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
