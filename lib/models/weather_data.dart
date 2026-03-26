class WeatherData {
  final DateTime time;
  final double temperature;
  final double bodyTemperature;
  final double windSpeed;
  final int humidity;
  final int aqi;
  final double uvIndex;
  final String weatherMain;
  final DateTime sunrise;
  final DateTime sunset;
  final DateTime moonrise;
  final DateTime moonset;
  final String moonPhase;
  final DateTime noon;
  final DateTime peakStart;
  final DateTime peakEnd;
  final double lat;
  final double lon;


  WeatherData({
    required this.time,
    required this.temperature,
    required this.bodyTemperature,
    required this.windSpeed,
    required this.humidity,
    required this.aqi,
    required this.uvIndex,
    required this.weatherMain,
    required this.sunrise,
    required this.sunset,
    required this.moonrise,
    required this.moonset,
    required this.moonPhase,
    required this.noon,
    required this.peakStart,
    required this.peakEnd,
    required this.lat,
    required this.lon,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      time: DateTime.fromMillisecondsSinceEpoch((json['dt'] as int? ?? 0) * 1000),
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      bodyTemperature: (json['bodyTemperature'] as num?)?.toDouble() ?? 0.0,
      windSpeed: (json['windSpeed'] as num?)?.toDouble() ?? 0.0,
      humidity: (json['humidity'] as num?)?.round() ?? 0,
      aqi: (json['aqi'] as num?)?.round() ?? 0,
      uvIndex: (json['uvIndex'] as num?)?.toDouble() ?? 0.0,
      weatherMain: json['weatherMain'] as String? ?? 'Clear',
      sunrise: DateTime.fromMillisecondsSinceEpoch((json['sunrise'] ?? 0) * 1000),
      sunset: DateTime.fromMillisecondsSinceEpoch((json['sunset'] ?? 0) * 1000),
      moonrise: DateTime.fromMillisecondsSinceEpoch((json['moonrise'] ?? 0) * 1000),
      moonset: DateTime.fromMillisecondsSinceEpoch((json['moonset'] ?? 0) * 1000),
      moonPhase: json['moonPhase'] as String? ?? '',
      noon: DateTime.fromMillisecondsSinceEpoch((json['noon'] ?? 0) * 1000),
      peakStart: DateTime.fromMillisecondsSinceEpoch((json['peakStart'] ?? 0) * 1000),
      peakEnd: DateTime.fromMillisecondsSinceEpoch((json['peakEnd'] ?? 0) * 1000),
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lon: (json['lon'] as num?)?.toDouble() ?? 0.0,
    );
  }

}
