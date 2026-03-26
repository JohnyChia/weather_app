import 'package:flutter/material.dart';

class UserAlarms extends StatefulWidget {
  final String username;
  final String email;

  const UserAlarms({
    super.key,
    required this.username,
    required this.email,
  });

  @override
  State<UserAlarms> createState() => _UserAlarmsState();
}

class _UserAlarmsState extends State<UserAlarms> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
