import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:weather_app/Screens/weather_screen.dart';
import '../Alarms/Admin/admin_Alarms.dart';
import '../Alarms/User/user_Alarms.dart';
import 'register.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final usernameFocus = FocusNode();
  final passwordFocus = FocusNode();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _warmUpServer();
  }

  Future<void> _warmUpServer() async {
    try {
      final url = Uri.parse('https://weather-api-nf24.onrender.com/health');
      await http.get(url).timeout(const Duration(seconds: 5));
      debugPrint("Server warmup completed");
    } catch (e) {
      debugPrint("Server warmup failed: $e");
    }
  }


  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    usernameFocus.dispose();
    passwordFocus.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final res = await Supabase.instance.client
          .from('users')
          .select()
          .eq('username', usernameController.text.trim())
          .maybeSingle();

      if (res == null) {
        _showMessage("User not found", isError: true);
        return;
      }

      debugPrint('Supabase login response: $res');

      final hash = res['password'];

      final isValid = await checkPassword(passwordController.text.trim(), hash);

      if (isValid) {
        _showMessage("Login success", isError: false);

        final role = res['role'];

        await Future.delayed(const Duration(milliseconds: 300));

        if(!mounted){
          return;
        }

        // 根据角色跳转页面
        if (role == 'User') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => WeatherScreen(
                username: res['username'],
                email: res['email'] ?? '',
                role: role,
              ),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => WeatherScreen(
                username: res['username'],
                email: res['email'] ?? '',
                role: role,
              ),
            ),
          );
        }

      } else {
        _showMessage("Incorrect password", isError: true);
      }
    } catch (e) {
      _showMessage("Error: $e", isError: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<bool> checkPassword(String plain, String hash) async {
    return _check({'plain': plain, 'hash': hash});
  }

  bool _check(Map<String, String> args) {
    return BCrypt.checkpw(args['plain']!, args['hash']!);
  }

  void _showMessage(String message, {required bool isError}) {
    debugPrint("SnackBar message: $message | isError: $isError");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Icon(Icons.person, size: 80, color: Colors.white),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: usernameController,
                    textInputAction: TextInputAction.next,
                    focusNode: usernameFocus,
                    onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(passwordFocus),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Username",
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                    validator: (value) => (value == null || value.isEmpty) ? "Username is required" : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: passwordController,
                    focusNode: passwordFocus,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => login(),
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Password",
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                    validator: (value) => (value == null || value.isEmpty) ? "Password is required" : null,
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : login,
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Login"),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage()));
                    },
                    child: const Text(
                      "Don't have an account? Register",
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}