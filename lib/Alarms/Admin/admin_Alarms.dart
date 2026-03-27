import 'package:flutter/material.dart';
import '../../Database/DBService.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchAll();
  }

  Future<void> fetchAll() async {
    setState(() => isLoading = true);

    final alarmData = await DbService.viewAll('alarms');
    final weatherData = await DbService.viewAll('weather');

    if(!mounted){
      return;
    }

    setState(() {
      alarms = alarmData;
      weather = weatherData;
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
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,

        appBar: AppBar(
          title: const Text(
            "Admin Panel",
            style: TextStyle(color: Colors.black),
          ),
          iconTheme: const IconThemeData(color: Colors.black),
          backgroundColor: Colors.white,
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
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

  // ================= ALARMS TAB =================
  Widget _buildAlarmsTable() {
    if (alarms.isEmpty) {
      return const Center(child: Text("No alarms"));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingTextStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
        dataTextStyle: const TextStyle(color: Colors.black),
        columns: const [
          DataColumn(label: Text("City")),
          DataColumn(label: Text("Temperature")),
          DataColumn(label: Text("Rain Fall")),
          DataColumn(label: Text("Humidity")),
          DataColumn(label: Text("AQI")),
          DataColumn(label: Text("Wind Speed")),
          DataColumn(label: Text("Type")),
          DataColumn(label: Text("Description")),
          DataColumn(label: Text("Risk")),
          DataColumn(label: Text("Actions")),
        ],
        rows: alarms.map((a) {
          final original = Map<String, dynamic>.from(a['data'] ?? {});
          final override = Map<String, dynamic>.from(a['override_data'] ?? {});
          final data = {...original, ...override};

          return DataRow(
            color: override.isNotEmpty
                ? MaterialStateProperty.all(Colors.yellow.shade100)
                : null,
            cells: [
              DataCell(Text(a['city'] ?? '')),
              DataCell(Text("${data['temperature'] ?? ''}")),
              DataCell(Text("${data['rainFall'] ?? ''}")),
              DataCell(Text("${data['humidity'] ?? ''}")),
              DataCell(Text("${data['aqi'] ?? ''}")),
              DataCell(Text("${data['windSpeed'] ?? ''}")),
              DataCell(Text(a['type'] ?? '')),
              DataCell(Text(a['description'] ?? '')),
              DataCell(Text(a['risk'] ?? '')),

              DataCell(Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showAlarmDialog(
                      isUpdate: true,
                      existingData: a,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
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

  // ================= WEATHER TAB =================
  Widget _buildWeatherTable() {
    // get all weather IDs that already have alarms
    final alarmWeatherIds = alarms
        .where((a) => a['weather_id'] != null)
        .map((a) => a['weather_id'])
        .toSet();

    // filter weather list
    final filteredWeather = weather
        .where((w) => !alarmWeatherIds.contains(w['id']))
        .toList();

    if (filteredWeather.isEmpty) {
      return const Center(child: Text("No weather data"));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingTextStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
        dataTextStyle: const TextStyle(color: Colors.black),
        columns: const [
          DataColumn(label: Text("City")),
          DataColumn(label: Text("Temperature")),
          DataColumn(label: Text("Rain Fall")),
          DataColumn(label: Text("Humidity")),
          DataColumn(label: Text("AQI")),
          DataColumn(label: Text("Wind Speed")),
          DataColumn(label: Text("Risk")),
          DataColumn(label: Text("Actions")),
        ],
        rows: filteredWeather.map((w) {
          return DataRow(
            cells: [
              DataCell(Text(w['city'] ?? '')),
              DataCell(Text("${w['temperature'] ?? ''}")),
              DataCell(Text("${w['rainFall'] ?? ''}")),
              DataCell(Text("${w['humidity'] ?? ''}")),
              DataCell(Text("${w['aqi'] ?? ''}")),
              DataCell(Text("${w['windSpeed'] ?? ''}")),
              DataCell(Text(w['risk'] ?? '')),

              DataCell(
                IconButton(
                  icon: const Icon(Icons.add_alert),
                  onPressed: () => _showAlarmDialog(
                    isUpdate: false,
                    weatherData: w,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _showAlarmDialog({
    required bool isUpdate,
    Map? weatherData,
    Map? existingData,
  }) {
    final descCtrl = TextEditingController();
    final valueCtrl = TextEditingController();

    String selectedType = isUpdate
        ? existingData!['type']
        : "Heatwave";

    String riskLevel = "Low";

    if (isUpdate && existingData != null) {
      descCtrl.text = existingData['description'] ?? '';
      final override = existingData['override_data'] ?? {};
      if (override.isNotEmpty) {
        valueCtrl.text = override.values.first.toString();
      }
    }

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(isUpdate ? "Update Alarm" : "Create Alarm"),

            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                // TYPE
                DropdownButtonFormField<String>(
                  value: selectedType,
                  items: const [
                    DropdownMenuItem(value: "Heatwave", child: Text("Heatwave")),
                    DropdownMenuItem(value: "Unhealthy Air", child: Text("Unhealthy Air")),
                    DropdownMenuItem(value: "Flood Risk", child: Text("Flood Risk")),
                    DropdownMenuItem(value: "Strong Wind", child: Text("Strong Wind")),
                  ],
                  onChanged: (value) {
                    setStateDialog(() {
                      selectedType = value!;
                      valueCtrl.clear();
                      riskLevel = "Low";
                    });
                  },
                  decoration: const InputDecoration(labelText: "Type"),
                ),

                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: "Description"),
                ),

                const SizedBox(height: 10),

                TextField(
                  controller: valueCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: getFieldLabel(selectedType),
                  ),
                  onChanged: (val) {
                    double? v = double.tryParse(val);
                    if (v != null) {
                      setStateDialog(() {
                        riskLevel = calculateRiskLevel(selectedType, v);
                      });
                    }
                  },
                ),

                const SizedBox(height: 10),

                Text(
                  "Risk Level: $riskLevel",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),

            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),

              ElevatedButton(
                onPressed: () async {

                  double? value = double.tryParse(valueCtrl.text);

                  if (value == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Invalid value")),
                    );
                    return;
                  }

                  String field = getFieldKey(selectedType);

                  Map<String, dynamic> overrideData = {
                    field: value
                  };

                  String risk = calculateRiskLevel(selectedType, value);

                  if (risk != "High") {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Risk level is $risk. Only HIGH is allowed."),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  if (isUpdate) {
                    await DbService.update('alarms', 'id', existingData!['id'], {
                      "type": selectedType,
                      "description": descCtrl.text,
                      "override_data": overrideData,
                      "risk": risk,
                      "is_override": true,
                    });
                  } else {
                    Map<String, dynamic> fullData = {
                      "temperature": weatherData!['temperature'],
                      "humidity": weatherData['humidity'],
                      "rainFall": weatherData['rainFall'],
                      "aqi": weatherData['aqi'],
                      "windSpeed": weatherData['windSpeed'],
                    };

                    await DbService.create('alarms', {
                      "city": weatherData['city'],
                      "type": selectedType,
                      "description": descCtrl.text,
                      "time_bucket": DateTime.now().toIso8601String(),
                      "is_override": true,
                      "weather_id": weatherData['id'],
                      "data": fullData,
                      "override_data": overrideData,
                      "risk": risk,
                    });
                  }

                  Navigator.pop(context);
                  fetchAll();
                },
                child: Text(isUpdate ? "Update" : "Create"),
              )
            ],
          );
        },
      ),
    );
  }

  // ================= DELETE =================
  Future<void> _deleteAlarm(id) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this alarm?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // cancel
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // close dialog

              await DbService.delete('alarms', 'id', id);
              fetchAll(); // refresh list
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }


  //used by chongyi's city CRUD
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
        return "AQI";
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
      if (value >= 35) return "High";
      if (value >= 30) return "Medium";
      return "Low";

    case "Unhealthy Air":
      if (value >= 4) return "High";
      if (value >= 3) return "Medium";
      return "Low";

    case "Flood Risk":
      if (value >= 50) return "High";
      if (value >= 20) return "Medium";
      return "Low";

    case "Strong Wind":
      if (value >= 60) return "High";
      if (value >= 30) return "Medium";
      return "Low";

    default:
      return "Low";
  }
}