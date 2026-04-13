import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:weather_app/Screens/login.dart';
import 'package:weather_app/widgets/app_responsive.dart';
import 'Services/notifications_services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://lbdwlvsnlcoubebsetbx.supabase.co',
    anonKey: 'sb_publishable_JCfnyFRdX-_k7-wptP3uKQ_DZhICRF9',
  );

  await NotificationService().init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return MaterialApp(
      title: 'Weather',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),

      builder: (context, child) {
        return AppResponsiveWrapper(
          child: child!,
        );
      },

      home: const LoginPage(),
    );
  }
}