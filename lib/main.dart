import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'Screens/login.dart';
import 'Screens/reset_password.dart';
import 'Services/notifications_services.dart';
import 'package:timezone/data/latest.dart' as tzdata;

import 'Utils/translator.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  await NotificationService().init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AppLinks _appLinks = AppLinks();
  DateTime? _lastLinkTime;

  @override
  void initState() {
    super.initState();
    _loadLang();
    _initDeepLinks();
  }

  Future<void> _loadLang() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString("lang") ?? "en";

    appLang.value = lang;
  }

  void _initDeepLinks() async {
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri != null) {
        _handle(uri);
      }
    } catch (e) {
      debugPrint("init error: $e");
    }

    _appLinks.uriLinkStream.listen((uri) {
      _handle(uri);
    });
  }

  void _handle(Uri uri) {
    final now = DateTime.now();

    if (_lastLinkTime != null &&
        now.difference(_lastLinkTime!).inMilliseconds < 1500) {
        return;
    }
    _lastLinkTime = now;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nav = navigatorKey.currentState;
      if (nav == null) return;

      if (uri.host == "reset-password") {
        final code = uri.queryParameters['code'];

        nav.pushNamedAndRemoveUntil(
          '/reset-password',
              (_) => false,
          arguments: code,
        );
        return;
      }

      if (uri.host == "auth-callback") {
        nav.pushNamedAndRemoveUntil(
          '/login',
              (_) => false,
        );
        return;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: const LoginPage(),

      routes: {
        '/reset-password': (context) {
          final code =
          ModalRoute.of(context)?.settings.arguments as String?;
          return ResetPasswordScreen(code: code);
        },
        '/login': (_) => const LoginPage(),
      },
    );
  }
}