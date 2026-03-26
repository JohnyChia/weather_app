import 'package:flutter/material.dart';

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

class _AdminAlarmsState extends State<AdminAlarms> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
