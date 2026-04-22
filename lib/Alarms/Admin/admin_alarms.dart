import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:weather_app/Utils/translator.dart';
import '../../Services/db_service.dart';

class AdminAlarms extends StatefulWidget {
  final String username;
  final String email;

  const AdminAlarms({
    super.key,
    required this.username,
    required this.email,
  });

  @override
  State<AdminAlarms> createState() => _AdminAlarmsState();
}

class _AdminAlarmsState extends State<AdminAlarms>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List alarms = [];
  List weather = [];
  bool isLoading = true;
  Map<String, String> userMap = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchAll();
  }

  Future<void> fetchAll() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    final alarmData = await DbService.viewAll('alarms');
    final weatherData = await DbService.viewAll('weather');
    final userData = await Supabase.instance.client
        .from('users_view')
        .select();

    Map<String, String> tempMap = {};
    for (var u in userData) {
      final meta = u['raw_user_meta_data'] ?? {};
      tempMap[u['id']] =
          meta['username'] ?? u['email'] ?? 'Unknown';
    }

    if (!mounted) return;

    setState(() {
      alarms = alarmData;
      weather = weatherData;
      userMap = tempMap;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const AutoText("Admin Panel"),
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.black,
            tabs: const [
              Tab(text: "Alarms"),
              Tab(text: "Weather"),
            ],
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
          controller: _tabController,
          children: [
            _buildAlarmsTable(),
            _buildWeatherTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildAlarmsTable() {
    if (alarms.isEmpty) return const Center(child: AutoText("No alarms"));

    return SingleChildScrollView(
      scrollDirection: .horizontal,
      child: DataTable(
        headingTextStyle: const TextStyle(
            fontWeight: .bold,
            color: Colors.black
        ),
        columns: const [
          DataColumn(label: AutoText("City")),
          DataColumn(label: AutoText("Temp")),
          DataColumn(label: AutoText("Rain")),
          DataColumn(label: AutoText("Humidity")),
          DataColumn(label: AutoText("AQI")),
          DataColumn(label: AutoText("Wind")),
          DataColumn(label: AutoText("Type")),
          DataColumn(label: AutoText("Description")),
          DataColumn(label: AutoText("Risk")),
          DataColumn(label: AutoText("Actions")),
        ],
        rows: alarms.map((a) {
          final original = Map<String, dynamic>.from(a['data'] ?? {});
          final override = Map<String, dynamic>.from(a['override_data'] ?? {});
          final data = {...original, ...override};

          return DataRow(
            color: override.isNotEmpty
                ? WidgetStateProperty.all(Colors.yellow.shade50)
                : null,
            cells: [
              DataCell(Text(a['city'] ?? '')),
              DataCell(AutoText("${data['temperature'] ?? ''}")),
              DataCell(AutoText("${data['rainFall'] ?? ''}")),
              DataCell(AutoText("${data['humidity'] ?? ''}")),
              DataCell(AutoText("${data['aqi'] ?? ''}")),
              DataCell(AutoText("${data['windSpeed'] ?? ''}")),
              DataCell(AutoText(a['type'] ?? '')),
              DataCell(AutoText(a['description'] ?? '')),
              DataCell(AutoText(a['risk'] ?? '')),
              DataCell(Row(
                children: [
                  IconButton(
                    icon: const Icon(
                        Icons.edit,
                        color: Colors.black
                    ),
                    onPressed: () => _showAlarmDialog(isUpdate: true, existingData: a),
                  ),
                  IconButton(
                    icon: const Icon(
                        Icons.delete,
                        color: Colors.black
                    ),
                    onPressed: () => _deleteAlarm(a['id']),
                  ),
                ],
              )),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWeatherTable() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (weather.isEmpty) {
      return const Center(child: AutoText("No weather data"));
    }

    final alarmWeatherIds = alarms.map((a) => a['weather_id']).toSet();

    final filteredWeather = weather.where((w) {
      return !alarmWeatherIds.contains(w['id']);
    }).toList();

    if (filteredWeather.isEmpty) {
      return const Center(
        child: AutoText("No available weather"),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingTextStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        columns: const [
          DataColumn(label: AutoText("City")),
          DataColumn(label: AutoText("Username")),
          DataColumn(label: AutoText("Temp")),
          DataColumn(label: AutoText("Rain")),
          DataColumn(label: AutoText("Humid")),
          DataColumn(label: AutoText("AQI")),
          DataColumn(label: AutoText("Wind")),
          DataColumn(label: AutoText("Risk")),
          DataColumn(label: AutoText("Actions")),
        ],
        rows: filteredWeather.map((w) {
          return DataRow(
            cells: [
              DataCell(Text(w['city']?.toString() ?? '')),
              DataCell(Text(userMap[w['user_id']?.toString()] ?? "Unknown")),
              DataCell(AutoText("${w['temperature'] ?? ''}")),
              DataCell(AutoText("${w['rainFall'] ?? ''}")),
              DataCell(AutoText("${w['humidity'] ?? ''}")),
              DataCell(AutoText("${w['aqi'] ?? ''}")),
              DataCell(AutoText("${w['windSpeed'] ?? ''}")),
              DataCell(AutoText(w['risk'] ?? '')),
              DataCell(
                IconButton(
                  icon: const Icon(Icons.add_alert, color: Colors.black),
                  onPressed: () =>
                      _showAlarmDialog(isUpdate: false, weatherData: w),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _showAlarmDialog({required bool isUpdate, Map? weatherData, Map? existingData}) {
    final descCtrl = TextEditingController(text: isUpdate ? existingData!['description'] : '');
    final valueCtrl = TextEditingController();

    String selectedType = isUpdate ? existingData!['type'] : "Heatwave";
    String riskLevel = isUpdate ? existingData!['risk'] : "Low";

    if (isUpdate) {
      final override = existingData!['override_data'] ?? {};
      if (override.isNotEmpty) valueCtrl.text = override.values.first.toString();
    }

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: AutoText(isUpdate ? "Update Alarm" : "Create Alarm"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: .min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    items: ["Heatwave", "Unhealthy Air", "Flood Risk", "Strong Wind"]
                        .map((t) => DropdownMenuItem(value: t, child: AutoText(t)))
                        .toList(),
                    onChanged: (value) {
                      setStateDialog(() {
                        selectedType = value!;
                        valueCtrl.clear();
                        riskLevel = "Low";
                      });
                    },
                    decoration: const InputDecoration(labelText: "Alarm Type"),
                  ),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: "Description"),
                  ),
                  TextField(
                    controller: valueCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: getFieldLabel(selectedType)
                    ),
                    onChanged: (val) {
                      double? v = double.tryParse(val);
                      if (v != null) {
                        setStateDialog(() =>
                        riskLevel = calculateRiskLevel(selectedType, v));
                      }
                    },
                  ),
                  const SizedBox(height: 15),
                  AutoText("Risk: $riskLevel",
                      style: TextStyle(
                        fontWeight: .bold,
                        color: Colors.black,
                      )),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () =>
                  Navigator.pop(context), child: const AutoText("Cancel")),
              ElevatedButton(
                onPressed: () async {
                  double? value = double.tryParse(valueCtrl.text);
                  if (value == null) return;

                  String risk = calculateRiskLevel(selectedType, value);
                  if (risk != "High") {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content:
                      AutoText("Risk level is $risk. Only HIGH is allowed."),
                          behavior: SnackBarBehavior.floating),
                    );
                    return;
                  }

                  Map<String, dynamic> overrideData = {getFieldKey(selectedType): value};

                  if (isUpdate) {
                    await DbService.update('alarms', 'id', existingData!['id'], {
                      "type": selectedType,
                      "description": descCtrl.text,
                      "override_data": overrideData,
                      "risk": risk,
                      "is_override": true,
                    });
                  } else {
                    await DbService.create('alarms', {
                      "city": weatherData!['city'],
                      "type": selectedType,
                      "description": descCtrl.text,
                      "time_bucket": DateTime.now().toIso8601String(),
                      "is_override": true,
                      "weather_id": weatherData['id'],
                      "data": {
                        "temperature": weatherData['temperature'],
                        "humidity": weatherData['humidity'],
                        "rainFall": weatherData['rainFall'],
                        "aqi": weatherData['aqi'],
                        "windSpeed": weatherData['windSpeed'],
                      },
                      "override_data": overrideData,
                      "risk": risk,
                      "lat" :weatherData['lat'],
                      'lon': weatherData['lon'],
                      "user_id": weatherData['user_id'],
                    });
                  }



                  if (!mounted) return;
                  Navigator.pop(context);
                  fetchAll();
                },
                child: AutoText(isUpdate ? "Update" : "Create"),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteAlarm(id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const AutoText("Confirm Delete"),
        content: const AutoText("Are you sure you want to delete this alarm?"),
        actions: [
          TextButton(onPressed: () =>
              Navigator.pop(context, false),
              child: const AutoText("Cancel")),
          ElevatedButton(onPressed: () =>
              Navigator.pop(context, true),
              child: const AutoText("Delete")),
        ],
      ),
    );

    if (confirm == true) {
      await DbService.delete('alarms', 'id', id);
      fetchAll();
    }
  }

  String getFieldKey(String type) {
    switch (type) {
      case "Heatwave":
        return "temperature";
      case "Unhealthy Air":
        return "aqi";
      case "Flood Risk":
        return "rainFall";
      case "Strong Wind":
        return "windSpeed";
      default:
        return "temperature";
    }
  }

  String getFieldLabel(String type) {
    switch (type) {
      case "Heatwave":
        return "Temperature (°C)";
      case "Unhealthy Air":
        return "AQI Level";
      case "Flood Risk":
        return "Rain Fall (mm)";
      case "Strong Wind":
        return "Wind Speed (km/h)";
      default:
        return "Value";
    }
  }
}

String calculateRiskLevel(String type, double value) {
  switch (type) {
    case "Heatwave":
      return value >= 35 ? "High" :
      (value >= 30 ? "Medium" : "Low");
    case "Unhealthy Air":
      return value >= 4 ? "High" :
      (value >= 3 ? "Medium" : "Low");
    case "Flood Risk":
      return value >= 50 ? "High" :
      (value >= 20 ? "Medium" : "Low");
    case "Strong Wind":
      return value >= 60 ? "High" :
      (value >= 30 ? "Medium" : "Low");
    default:
      return "Low";
  }
}