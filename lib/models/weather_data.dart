class WeatherData {
  final String city;
  final double temperature;
  final double bodyTemperature;
  final int humidity;
  final double windSpeed;
  final int airPressure;
  final double rainFall;
  final int aqi;
  final double co;
  final double no2;
  final double uvIndex;
  final String weatherMain;
  final String sunrise;
  final String sunset;
  final String moonPhase;
  final String dt;
  final String noon;
  final String peakStart;
  final String peakEnd;
  final double lat;
  final double lon;

  WeatherData({
    required this.city,
    required this.temperature,
    required this.bodyTemperature,
    required this.humidity,
    required this.windSpeed,
    required this.airPressure,
    required this.rainFall,
    required this.aqi,
    required this.co,
    required this.no2,
    required this.uvIndex,
    required this.weatherMain,
    required this.sunrise,
    required this.sunset,
    required this.moonPhase,
    required this.dt,
    required this.noon,
    required this.peakStart,
    required this.peakEnd,
    required this.lat,
    required this.lon,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      return (value as num).toDouble();
    }

    int parseInt(dynamic value) {
      if (value == null) return 0;
      return (value as num).toInt();
    }

    return WeatherData(
      city: json['city'] as String? ?? '',
      temperature: parseDouble(json['temperature']),
      bodyTemperature: parseDouble(json['bodyTemperature']),
      humidity: parseInt(json['humidity']),
      windSpeed: parseDouble(json['windSpeed']),
      airPressure: parseInt(json['airPressure']),
      rainFall: parseDouble(json['rainFall']),
      aqi: parseInt(json['aqi']),
      co: parseDouble(json['co']),
      no2: parseDouble(json['no2']),
      uvIndex: parseDouble(json['uvIndex']),
      weatherMain: json['weatherMain'] as String? ?? 'Clear',
      sunrise: json['sunrise'] as String? ?? '',
      sunset: json['sunset'] as String? ?? '',
      moonPhase: json['moonPhase'] as String? ?? '',
      dt: json['dt'] as String? ?? '',
      noon: json['noon'] as String? ?? '',
      peakStart: json['peakStart'] as String? ?? '',
      peakEnd: json['peakEnd'] as String? ?? '',
      lat: parseDouble(json['lat']),
      lon: parseDouble(json['lon']),
    );
  }
}