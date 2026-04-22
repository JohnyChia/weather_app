import 'package:flutter/material.dart';
import '../Services/db_service.dart';
import '../Utils/translator.dart';

class WeatherHistory extends StatefulWidget {
  final String userId;

  const WeatherHistory({super.key, required this.userId});

  @override
  State<WeatherHistory> createState() => _WeatherHistoryState();
}

class _WeatherHistoryState extends State<WeatherHistory> {
  List<Map<String, dynamic>> cities = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCities();
  }

  Future<void> _fetchCities() async {
    setState(() => isLoading = true);

    try {
      final data = await DbService.view('city', {'user_id': widget.userId});

      cities = data.map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item)).toList();

      if (!mounted) {
        return;
      }
      setState(() => isLoading = false);

    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: AutoText('Failed to load cities: $e')),
      );
    }
  }

  Widget _buildCityTile(Map<String, dynamic> city) {
    final name = city['city_name'] ?? '';
    final condition = city['condition'] ?? '';
    final timezone = city['timezone'] ?? '';
    final temp = city['temperature'] != null ? (city['temperature'] as num).round() : '';

    return ListTile(
      leading: const Icon(Icons.location_city, color: Colors.blueAccent, size: 50),

      title: Text(
        name,
        style: const TextStyle(color: Colors.black, fontWeight: .bold),
      ),

      subtitle: Column(
        crossAxisAlignment: .start,
        children: [
          AutoText(
            'Temperature : $temp°',
            style: const TextStyle(color: Colors.black),
          ),
          AutoText(
            'Condition : $condition',
            style: const TextStyle(color: Colors.black),
          ),
          AutoText(
            'Timezone: $timezone',
            style: const TextStyle(color: Colors.black),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const AutoText('Weather History'),
        backgroundColor: Colors.deepPurple,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent)) : cities.isEmpty
          ? const Center(
              child: AutoText('No cities found.', style: TextStyle(color: Colors.black))) : RefreshIndicator(
        onRefresh: _fetchCities,
        color: Colors.blueAccent,
        child: ListView.builder(
          itemCount: cities.length,
          itemBuilder: (context, index) => _buildCityTile(cities[index]),
        ),
      ),
    );
  }
}