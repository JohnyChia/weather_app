class TravelPlan {
  final int? id;
  final String userId;
  final int? cityId;
  final String activity;
  final String location;
  final DateTime planDatetime;
  final String status;
  final String? suggestion;

  TravelPlan({
    this.id,
    required this.userId,
    this.cityId,
    required this.activity,
    required this.location,
    required this.planDatetime,
    this.status = 'planned',
    this.suggestion,
  });

  factory TravelPlan.fromJson(Map<String, dynamic> json) {
    return TravelPlan(
      id: json['id'],
      userId: json['user_id'] ?? '',
      cityId: json['city_id'],
      activity: json['activity'] ?? '',
      location: json['location'] ?? '',
      planDatetime: DateTime.parse(json['plan_datetime']),
      status: json['status'] ?? 'planned',
      suggestion: json['suggestion'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'city_id': cityId,
      'activity': activity,
      'location': location,
      'plan_datetime': planDatetime.toIso8601String(),
      'status': status,
      if (suggestion != null) 'suggestion': suggestion,
    };
  }
}
