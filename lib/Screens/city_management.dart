import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Services/db_service.dart';
import '../Utils/translator.dart';
import '../models/city_data.dart';
import '../Services/api_service.dart';
import 'dart:async';
import '../Utils/timezone.dart';


class CityManagement extends StatefulWidget {
  final String userId;
  const CityManagement({super.key, required this.userId});

  @override
  State<CityManagement> createState() => _CityManagementState();
}

class _CityManagementState extends State<CityManagement> {
  final ApiService _apiService = ApiService();

  List<City> cities = [];
  List<City> _searchResults = [];
  List<String> _searchHistory = [];

  bool isLoading = true;
  bool isSearching = false;
  bool cityNotFound = false;

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  String? resolvedUuid;

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _fetchCities();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchHistory =
          prefs.getStringList('search_history_${widget.userId}') ?? [];
    });
  }

  Future<void> _saveSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'search_history_${widget.userId}', _searchHistory);
  }

  void _addToHistory(String query) {
    if (query.isEmpty) return;

    setState(() {
      _searchHistory.remove(query);
      _searchHistory.insert(0, query);

      if (_searchHistory.length > 5) {
        _searchHistory.removeLast();
      }
    });

    _saveSearchHistory();
  }

  Future<void> _fetchCities() async {
    setState(() => isLoading = true);

    try {
      final data = await DbService.view('city', {
        'user_id': widget.userId,
        'status': 'active'
      });

      List<City> savedCities =
      data.map((json) => City.fromJson(json)).toList();

      for (City city in savedCities) {

        try {
          final weather = await _apiService.fetchWeather(
            city.lat,
            city.lon,
          ).timeout(const Duration(seconds: 10));

          city.temperature = weather.temperature;
          city.condition = weather.weatherMain;
        } catch (e) {
          debugPrint('Weather failed: ${city.cityName}');
        }
      }

      if (!mounted) return;

      setState(() {
        cities = savedCities;
        isLoading = false;
      });

    } catch (e) {

      if (!mounted) return;

      isLoading = false;
    }
  }

  void _onSearchChanged(String query) {

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().isNotEmpty) {
        _performAutoSearch(query.trim());
      } else {
        setState(() {
          _searchResults = [];
          isSearching = false;
        });
      }
    });
  }

  Future<void> _performAutoSearch(String query) async {
    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      setState(() {
        _searchResults = [];
        cityNotFound = true;
      });
      return;
    }

    setState(() {
      isSearching = true;
      cityNotFound = false;
    });

    final result = await _apiService.searchCity(trimmed);

    setState(() {
      isSearching = false;

      if (result == null) {
        _searchResults = [];
        cityNotFound = true;
      } else {
        _searchResults = [result];
        cityNotFound = false;

        _addToHistory(trimmed);
      }
    });
  }

  Future<void> _searchCity(String query) async {
    if (query.isEmpty) return;
    _addToHistory(query);
    _performAutoSearch(query);
  }

  Future<void> _addSelectedCity(City selected) async {
    setState(() => isLoading = true);

    try {
      final existing = await DbService.view('city', {
        'user_id': widget.userId,
        'city_name': selected.cityName,
      });

      if (existing.isNotEmpty) {
        final city = existing.first;

        if (city['status'] == 'inactive') {
          await DbService.update(
            'city',
            'id',
            city['id'],
            {'status': 'active'},
          );

          await _fetchCities();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: AutoText('City restored!')),
          );
          return;
        } else {
          _showError('City already added');
          return;
        }
      }

      final weather = await _apiService.fetchWeather(
        selected.lat,
        selected.lon,
      );

      final cityData = {
        'user_id': widget.userId,
        'city_name': selected.cityName,
        'country': selected.country,
        'lat': selected.lat,
        'lon': selected.lon,
        'condition': weather.weatherMain,
        'temperature': weather.temperature,
        'timezone': selected.timezone,
        'city_time': TimezoneHelper.getCityTime(selected.timezone),
        'status': 'active',
      };

      await DbService.create('city', cityData);

      _searchController.clear();
      _searchResults.clear();

      await _fetchCities();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: AutoText('City added successfully!'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      _showError('Error adding city');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _deleteCity(int id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const AutoText(
            'Remove City',
            style: TextStyle(color: Colors.white)),
        content: const AutoText(
          'Are you sure you want to remove this city from your list?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const AutoText('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const AutoText('Remove'),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      try {
        await DbService.update(
          'city',
          'id',
          id,
          {'status': 'inactive'},
        );

        _fetchCities();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: AutoText('City removed')),
          );
        }
      } catch (e) {
        _showError('Delete error');
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: AutoText(msg),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const AutoText(
          'Manage Cities',
          style: TextStyle(
              color: Colors.white,
              fontWeight: .bold),
        ),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(
                Icons.refresh,
                color: Colors.blueAccent),
            onPressed: _fetchCities,
            tooltip: "Refresh Weather",
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _fetchCities,
        color: Colors.blueAccent,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: appLang.value == "en" ? "Search City Name..." : "搜索城市名称...",
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.blueAccent),
                    suffixIcon: isSearching
                        ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.blueAccent,
                      ),
                    ) : IconButton(
                      icon: const Icon(
                          Icons.send,
                          color: Colors.blueAccent),
                      onPressed: () =>
                          _searchCity(_searchController.text.trim()),
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (val) => _searchCity(val.trim()),
                ),
              ),

              if (cityNotFound)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: AutoText(
                    "City not found",
                    style: TextStyle(color: Colors.redAccent, fontSize: 14),
                  ),
                ),
              if (_searchHistory.isNotEmpty && _searchResults.isEmpty &&
                  !cityNotFound &&
                  !isSearching &&
                  _searchController.text.trim().isEmpty
              )
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      const AutoText(
                        "Recent Searches",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _searchHistory.map((history) {
                          return ActionChip(
                            backgroundColor: Colors.white10,
                            label: AutoText(
                              history,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                              ),
                            ),
                            onPressed: () {
                              _searchController.text = history;
                              _searchCity(history);
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              if (_searchResults.isNotEmpty)
                Container(
                  margin:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final res = _searchResults[index];

                      return ListTile(
                        title: Text(
                          res.cityName,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: AutoText(
                          res.country,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: const Icon(
                          Icons.add_circle,
                          color: Colors.greenAccent,
                        ),
                        onTap: () => _addSelectedCity(res),
                      );
                    },
                  ),
                ),

              const Divider(color: Colors.white12, height: 32),

              isLoading
                  ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(
                    color: Colors.blueAccent,
                  ),
                ),
              )
                  : cities.isEmpty
                  ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: AutoText(
                    'No cities saved yet.',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              )
                  : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: cities.length,
                itemBuilder: (context, index) {
                  final city = cities[index];
                  return _buildCityCard(city);
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCityCard(City city) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [Colors.blueAccent.withValues(alpha: 0.7), Colors.blue.shade900],
          begin: .topLeft, end: .bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                mainAxisSize: .min,
                children: [
                  Text(
                    city.cityName,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  AutoText(
                    '${city.country}\n${TimezoneHelper.getCityTime(city.timezone)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: .end,
              mainAxisSize: .min,
              children: [
                AutoText(
                  '${city.temperature.toStringAsFixed(0)}°',
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: .bold),
                ),
                AutoText(
                  city.condition,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white54),
              onPressed: () => _deleteCity(city.id!),
            ),
          ],
        ),
      ),
    );
  }
}

