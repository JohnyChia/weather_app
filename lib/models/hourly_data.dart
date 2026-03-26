class HourlyData {
  final String weatherDate;
  final String weatherTime;
  final double temp;
  final int humidity;
  final String condition;
  final double uvIndex;

  HourlyData({
    required this.weatherDate,
    required this.weatherTime,
    required this.temp,
    required this.humidity,
    required this.condition,
    required this.uvIndex,
  });

  factory HourlyData.fromJson(Map<String, dynamic> json) {
    return HourlyData(
      weatherDate: json['weatherDate'] ?? '',
      weatherTime: json['weatherTime'] ?? '',
      temp: (json['temp'] is num) ? (json['temp'] as num).toDouble() : double.tryParse(json['temp'].toString()) ?? 0.0,
      humidity: (json['humidity'] is int) ? json['humidity'] as int : int.tryParse(json['humidity'].toString()) ?? 0,
      condition: json['condition'] ?? 'Clear',
      uvIndex: (json['uvIndex'] is num) ? (json['uvIndex'] as num).toDouble() : double.tryParse(json['uvIndex'].toString()) ?? 0.0,
    );
  }
}