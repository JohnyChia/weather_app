import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';
import '../Services/db_service.dart';
import '../models/travelplan_data.dart';
import '../Services/api_service.dart';

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
        fillColor: Colors.white.withOpacity(0.1),
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
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(plan?.planDatetime ?? DateTime.now());

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(plan == null ? 'New Travel Plan' : 'Edit Travel Plan',
              style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                inputField('Activity (e.g. Picnic)', Icons.local_activity, activityController),
                const SizedBox(height: 15),


                inputField('Location (City Name)', Icons.location_on, locationController),

                const SizedBox(height: 15),


                ListTile(
                  tileColor: Colors.white10,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  leading: const Icon(Icons.calendar_today, color: Colors.blueAccent),
                  title: Text(DateFormat('yyyy-MM-dd').format(selectedDate), style: const TextStyle(color: Colors.white)),
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (pickedDate != null) setDialogState(() => selectedDate = pickedDate);
                  },
                ),

                const SizedBox(height: 10),


                ListTile(
                  tileColor: Colors.white10,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  leading: const Icon(Icons.access_time, color: Colors.blueAccent),
                  title: Text(selectedTime.format(context), style: const TextStyle(color: Colors.white)),
                  onTap: () async {
                    final pickedTime = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (pickedTime != null) setDialogState(() => selectedTime = pickedTime);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent),
              onPressed: () async {
                if (activityController.text.isEmpty || locationController.text.isEmpty) {
                  _showError('Please enter activity and location');
                  return;
                }


                try {
                  String cityName = locationController.text.trim();
                  final cityData = await DbService.view('city', {
                    'user_id': widget.userId,
                    'city_name': cityName
                  });

                  int? selectedCityId;
                  String cityStatus = plan?.status ?? 'planned';

                  if (cityData.isEmpty) {
                    try {
                      List<Location> locations = await locationFromAddress(cityName);
                      if (locations.isNotEmpty) {
                        final loc = locations.first;
                        List<Placemark> placemarks = await placemarkFromCoordinates(loc.latitude, loc.longitude);
                        final p = placemarks.first;

                        final weather = await _apiService.fetchWeather(loc.latitude, loc.longitude);

                        final resolvedCityName = p.locality ?? p.name ?? cityName;

                        final Map<String, dynamic> newCityData = {
                          'user_id': widget.userId,
                          'city_name': resolvedCityName,
                          'country': p.country ?? 'Unknown',
                          'condition': weather.weatherMain,
                          'temperature': weather.temperature,
                          'lat': loc.latitude,
                          'lon': loc.longitude,
                        };

                        await DbService.create('city', newCityData);

                        final addedCity = await DbService.view('city', {
                          'user_id': widget.userId,
                          'city_name': resolvedCityName
                        });

                        if (addedCity.isNotEmpty) {
                          selectedCityId = addedCity.first['id'];
                          cityName = resolvedCityName;
                        } else {
                          throw Exception("Could not retrieve added city ID");
                        }
                      } else {
                        _showError('City not found. Please enter a valid city name.');
                        return;
                      }
                    } catch (e) {
                      _showError('Could not find or add city: $e');
                      return;
                    }
                  } else {
                    selectedCityId = cityData.first['id'];
                  }

                  final finalDateTime = DateTime(
                      selectedDate.year, selectedDate.month, selectedDate.day,
                      selectedTime.hour, selectedTime.minute
                  );

                  final newPlan = TravelPlan(
                    id: plan?.id,
                    userId: widget.userId,
                    cityId: selectedCityId,
                    activity: activityController.text,
                    location: locationController.text.trim(),
                    planDatetime: finalDateTime,
                    status: cityStatus,
                  );

                  final payload = newPlan.toJson();
                  print("Supabase : $payload" );

                  if (plan == null) {
                    await DbService.create('travel_plan', newPlan.toJson());
                  } else {
                    await DbService.update('travel_plan', 'id', plan.id, newPlan.toJson());
                  }
                  Navigator.pop(context);
                  _fetchPlans();
                } catch (e) {
                  _showError('Validation Error: $e');
                }
              },
              child: const Text('Save Plan'),
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
        title: const Text('Confirm Delete', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this travel plan?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      try {
        await DbService.delete('travel_plan', 'id', id);
        _fetchPlans();

        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Plan deleted successfully'))
        );
      } catch (e) {
        _showError('Error deleting: $e');
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Travel Planner', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchPlans),
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
          ? const Center(child: Text('No plans yet. Tap + to start.', style: TextStyle(color: Colors.white54)))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: plans.length,
        itemBuilder: (context, index) => _buildPlanCard(plans[index]),
      ),
    );
  }

  Widget _buildPlanCard(TravelPlan plan) {
    bool isWarning = plan.status == 'warning';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: isWarning
              ? [Colors.red.shade900, Colors.red.shade700]
              : [Colors.blueGrey.shade900, Colors.blueGrey.shade800],
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        title: Text(plan.activity, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(plan.location, style: const TextStyle(color: Colors.white70)),
            Text(DateFormat('MMM dd, yyyy • hh:mm a').format(plan.planDatetime), style: const TextStyle(color: Colors.white60)),
            if (plan.suggestion != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text("💡 ${plan.suggestion}", style: const TextStyle(color: Colors.yellowAccent)),
              ),
          ],
        ),
        trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.white24), onPressed: () => _deletePlan(plan.id!)),
        onTap: () => _addOrUpdatePlan(plan: plan),
      ),
    );
  }
}

