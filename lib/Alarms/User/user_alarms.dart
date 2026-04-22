import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../Utils/translator.dart';

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
  late final RealtimeChannel _realtime;

  @override
  void initState() {
    super.initState();
    fetchAlarms();
    listenAlarms();
  }


  @override
  void dispose() {
    Supabase.instance.client.removeChannel(_realtime);
    super.dispose();
  }

  void listenAlarms() {
    final user = Supabase.instance.client.auth.currentUser;

    _realtime = Supabase.instance.client
        .channel('alarms-channel')
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'alarms',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: user!.id,
      ),
      callback: (payload) {
        fetchAlarms();
      },
    )
        .subscribe();
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
          title: const AutoText(
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

  Future<void> fetchAlarms() async {
    setState(() => isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;

      final res = await Supabase.instance.client
          .from('alarms')
          .select()
          .eq('user_id', user!.id)
          .order('created_at', ascending: false);

      setState(() {
        alarms = List<Map<String, dynamic>>.from(res);
        isLoading = false;
      });

    } catch (e) {
      print("ERROR: $e");

      setState(() => isLoading = false);
    }
  }

  Widget _buildAlarmsTable() {
    if (alarms.isEmpty) {
      return const Center(child: AutoText("No alarms"));
    }

    return SingleChildScrollView(
      scrollDirection: .horizontal,
      child: DataTable(
        headingTextStyle: const TextStyle(
          color: Colors.black,
          fontWeight: .bold,
        ),
        dataTextStyle: const TextStyle(color: Colors.black),
        columns: const [
          DataColumn(label: AutoText("City")),
          DataColumn(label: AutoText("Temperature")),
          DataColumn(label: AutoText("Rain Fall")),
          DataColumn(label: AutoText("Humidity")),
          DataColumn(label: AutoText("AQI")),
          DataColumn(label: AutoText("Wind Speed")),
          DataColumn(label: AutoText("Type")),
          DataColumn(label: AutoText("Description")),
          DataColumn(label: AutoText("Risk")),
        ],
        rows: alarms.map((a) {
          final original = Map<String, dynamic>.from(a['data'] ?? {});
          final override = Map<String, dynamic>.from(a['override_data'] ?? {});
          final data = {...original, ...override};

          return DataRow(
            color: override.isNotEmpty
                ? WidgetStateProperty.all(Colors.yellow.shade100)
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
            ],
          );
        }).toList(),
      ),
    );
  }
}