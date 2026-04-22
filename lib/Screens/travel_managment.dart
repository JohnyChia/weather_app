import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../Services/db_service.dart';
import '../Utils/translator.dart';
import '../models/travelplan_data.dart';
import '../Services/api_service.dart';
import '../Utils/timezone.dart';

class TravelManagement extends StatefulWidget {
  final String userId;
  const TravelManagement({super.key, required this.userId});

  @override
  State<TravelManagement> createState() => _TravelManagementState();
}

class _TravelManagementState extends State<TravelManagement> {
  final ApiService _apiService = ApiService();
  List<TravelPlan> plans = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPlans();
  }

  Widget inputField(
      String label,
      IconData icon,
      TextEditingController controller, {
        bool isPassword = false,
      }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white54),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white),
        ),
      ),
    );
  }

  Future<void> _fetchPlans() async {
    setState(() => isLoading = true);
    try {
      final data = await DbService.view('travel_plan', {'user_id': widget.userId});
      setState(() {
        plans = data.map((json) => TravelPlan.fromJson(json)).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showError('Error fetching plans: $e');
    }
  }

  Future<void> _addOrUpdatePlan({TravelPlan? plan}) async {
    final activityController = TextEditingController(text: plan?.activity ?? '');
    final locationController = TextEditingController(text: plan?.location ?? '');

    DateTime selectedDate = plan?.planDatetime ?? DateTime.now();
    TimeOfDay selectedTime =
    TimeOfDay.fromDateTime(plan?.planDatetime ?? DateTime.now());

    String tr(String en, String zh) {
      return appLang.value == "en" ? en : zh;
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: AutoText(
            plan == null ? 'New Travel Plan' : 'Edit Travel Plan',
            style: const TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                inputField(
                  tr('Activity (e.g. Picnic)', '活动（例如：野餐）'),
                  Icons.local_activity,
                  activityController,
                ),

                const SizedBox(height: 15),

                inputField(
                  tr('Location (City Name)', '地点（城市名称）'),
                  Icons.location_on,
                  locationController,
                ),
                const SizedBox(height: 15),

                ListTile(
                  tileColor: Colors.white10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  leading: const Icon(Icons.calendar_today,
                      color: Colors.blueAccent),
                  title: AutoText(
                    DateFormat('yyyy-MM-dd').format(selectedDate),
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (pickedDate != null) {
                      setDialogState(() => selectedDate = pickedDate);
                    }
                  },
                ),

                const SizedBox(height: 10),

                ListTile(
                  tileColor: Colors.white10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  leading:
                  const Icon(Icons.access_time, color: Colors.blueAccent),
                  title: AutoText(
                    selectedTime.format(context),
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    final pickedTime = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (pickedTime != null) {
                      setDialogState(() => selectedTime = pickedTime);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const AutoText('Cancel'),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
              ),
              onPressed: () async {
                if (activityController.text.isEmpty ||
                    locationController.text.isEmpty) {
                  _showError('Please enter activity and location');
                  return;
                }

                try {
                  final cityName = locationController.text.trim();

                  final cityResult = await _apiService.searchCity(cityName);

                  if (cityResult == null) {
                    _showError("City not found");
                    return;
                  }

                  final weather = await _apiService.fetchWeather(
                    cityResult.lat,
                    cityResult.lon,
                  );

                  final normalizedCity = cityResult.cityName.trim();
                  final existingCity = await DbService.view('city', {
                    'user_id': widget.userId,
                    'city_name': normalizedCity,
                    'lat': cityResult.lat,
                    'lon': cityResult.lon,
                  });

                  final payload = {
                    'user_id': widget.userId,
                    'city_name': normalizedCity,
                    'country': cityResult.country,
                    'condition': weather.weatherMain,
                    'temperature': weather.temperature,
                    'lat': cityResult.lat,
                    'lon': cityResult.lon,
                    'timezone': cityResult.timezone,
                    'city_time': TimezoneHelper.getCityTime(cityResult.timezone),
                    'status': 'active',
                  };

                  int cityId;

                  if (existingCity.isEmpty) {
                    await DbService.create('city', payload);

                    final inserted = await DbService.view('city', {
                      'user_id': widget.userId,
                      'city_name': normalizedCity,
                      'lat': cityResult.lat,
                      'lon': cityResult.lon,
                    });

                    if (inserted.isEmpty) {
                      throw Exception("City insert failed");
                    }

                    cityId = inserted.first['id'];
                  } else {
                    cityId = existingCity.first['id'];

                    await DbService.update(
                      'city',
                      'id',
                      cityId,
                      payload,
                    );
                  }

                  final finalDateTime = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    selectedTime.hour,
                    selectedTime.minute,
                  );

                  final newPlan = TravelPlan(
                    id: plan?.id,
                    userId: widget.userId,
                    cityId: cityId,
                    activity: activityController.text,
                    location: locationController.text.trim(),
                    planDatetime: finalDateTime,
                  );

                  if (plan == null) {
                    await DbService.create('travel_plan', newPlan.toJson());
                  } else {
                    await DbService.update(
                      'travel_plan',
                      'id',
                      plan.id,
                      newPlan.toJson(),
                    );
                  }

                  Navigator.pop(context);
                  _fetchPlans();
                } catch (e) {
                  _showError('Error: $e');
                }
              },
              child: const AutoText(
                'Save Plan',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deletePlan(int id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const AutoText(
            'Confirm Delete',
            style: TextStyle(color: Colors.white)),
        content: const AutoText(
            'Are you sure you want to delete this travel plan?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const AutoText('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const AutoText('Delete'),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      try {
        await DbService.delete('travel_plan', 'id', id);
        _fetchPlans();

        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: AutoText('Plan deleted successfully'))
        );
      } catch (e) {
        _showError('Error deleting: $e');
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: AutoText(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const AutoText(
          'Travel Planner',
          style: TextStyle(
            fontWeight: .bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchPlans,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrUpdatePlan(),
        backgroundColor: Colors.deepPurpleAccent,
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent))
          : plans.isEmpty
          ? const Center(child: AutoText('No plans yet. Tap + to start.', style: TextStyle(color: Colors.white54)))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: plans.length,
        itemBuilder: (context, index) => _buildPlanCard(plans[index]),
      ),
    );
  }

  Widget _buildPlanCard(TravelPlan plan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        title: AutoText(
            plan.activity,
            style: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: .bold)),
        subtitle: Column(
          crossAxisAlignment: .start,
          children: [
            AutoText(
                plan.location,
                style: const TextStyle(color: Colors.white70)),
            AutoText(DateFormat('MMM dd, yyyy • hh:mm a').format(plan.planDatetime),
                style: const TextStyle(color: Colors.white60)),

            if (plan.suggestion != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: AutoText("${plan.suggestion}", style: const TextStyle(color: Colors.yellow)),
              ),
          ],
        ),
        trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.white24), onPressed: () => _deletePlan(plan.id!)),
        onTap: () => _addOrUpdatePlan(plan: plan),
      ),
    );
  }
}