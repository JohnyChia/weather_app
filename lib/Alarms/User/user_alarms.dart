import 'package:flutter/material.dart';

class UserAlarms extends StatefulWidget {
  final String username;
  final String email;
  final List<dynamic> triggeredAlarms;

  const UserAlarms({
    super.key,
    required this.username,
    required this.email,
    required this.triggeredAlarms,
  });

  @override
  State<UserAlarms> createState() => _UserAlarmsState();
}

class _UserAlarmsState extends State<UserAlarms> {
  List alarms = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    setState(() {
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
        appBar: AppBar(
          title: const Text(
            "User Alarms",
            style: TextStyle(color: Colors.black),
          ),
        ),

        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildAlarmsTable(),
      ),
    );
  }

  Widget _buildAlarmsTable() {
    if (widget.triggeredAlarms.isEmpty) {
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
        ],
        rows: widget.triggeredAlarms.map((a) {
          final original = Map<String, dynamic>.from(a['data'] ?? {});
          final override = Map<String, dynamic>.from(a['override_data'] ?? {});
          final data = {...original, ...override};

          return DataRow(
            color: override.isNotEmpty
                ? WidgetStateProperty.all(Colors.yellow.shade100)
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
            ],
          );
        }).toList(),
      ),
    );
  }
}