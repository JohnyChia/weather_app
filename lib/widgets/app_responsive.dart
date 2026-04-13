import 'package:flutter/material.dart';

class AppResponsiveWrapper extends StatelessWidget {
  final Widget child;

  const AppResponsiveWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.height < 600;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 10 : 20,
        vertical: 10,
      ),
      child: child,
    );
  }
}