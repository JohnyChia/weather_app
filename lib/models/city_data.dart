class City {
  final int? id;
  final String? userId;
  final String cityName;
  final String country;
  String condition;
  double temperature;
  String currentTime;
  final double lat;
  final double lon;
  final String status;
  final String timezone;

  City({
    this.id,
    this.userId,
    required this.cityName,
    required this.country,
    required this.condition,
    required this.temperature,
    required this.currentTime,
    required this.lat,
    required this.lon,
    this.status = 'active',
    required this.timezone,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? ''),
      userId: json['user_id']?.toString(),
      cityName: json['city_name'] ?? '',
      country: json['country'] ?? '',
      condition: json['condition'] ?? '',
      temperature: (json['temperature'] is num) ? (json['temperature'] as num).toDouble() : double.tryParse(json['temperature']?.toString() ?? '') ?? 0.0,
      currentTime: json['city_time'] ?? json['currentTime'] ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lon: (json['lon'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'active',
      timezone: json['timezone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      'city_name': cityName,
      'country': country,
      'condition': condition,
      'temperature': temperature,
      'currentTime':currentTime,
      'lat': lat,
      'lon': lon,
      'status' : status,
      'timezone' : timezone,
      'city_time': currentTime,
    };
  }
}
