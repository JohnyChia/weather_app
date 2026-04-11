import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bcrypt/bcrypt.dart';
import 'forgot_password.dart';
import 'weather_screen.dart';
import 'register.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> login() async {
    if (usernameController.text.isEmpty || passwordController.text.isEmpty) {
      _showMessage("Please enter username and password", true);
      return;
    }

    setState(() => isLoading = true);

    try {
      final res = await Supabase.instance.client
          .from('users')
          .select()
          .eq('username', usernameController.text.trim())
          .maybeSingle();

      if (res == null) {
        _showMessage("User not found", true);
      } else {
        final hash = res['password'];
        final isValid =
        BCrypt.checkpw(passwordController.text.trim(), hash);

        if (isValid) {
          _showMessage("Login success", false);

          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('LoggedIn', true);
          await prefs.setString('username', res['username']);
          await prefs.setString('role', res['role']);
          await prefs.setString('userId', res['id'].toString());

          if(!mounted){
            return;
          }

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => WeatherScreen(
                username: res['username'],
                email: res['email'] ?? '',
                role: res['role'],
                userId: res['id'].toString(),
              ),
            ),
          );
        } else {
          _showMessage("Incorrect password", true);
        }
      }
    } catch (e) {
      _showMessage("Error: $e", true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showMessage(String msg, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 10),
      ),
    );
  }

  Future<void> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool('LoggedIn') ?? false;

    if (loggedIn) {
      final username = prefs.getString('username') ?? '';
      final role = prefs.getString('role') ?? 'User';
      final userId = prefs.getString('userId') ?? '';

      final res = await Supabase.instance.client
          .from('users')
          .select()
          .eq('username', username)
          .maybeSingle();

      final email = res?['email'] ?? '';
      final actualUserId = res?['id']?.toString() ?? userId;

      if(!mounted){
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => WeatherScreen(
            username: username,
            email: email,
            role: role,
            userId: actualUserId,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: "Username"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isLoading ? null : login,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text("Login"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ForgotPasswordScreen(
                      ),
                    ),
                  );
                },
                child: const Text("Forgot Password"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const RegisterPage()));
                },
                child: const Text("Don't have an account? Register"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}