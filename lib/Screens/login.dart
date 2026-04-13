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
  bool obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> login() async {
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
        final isValid =
        BCrypt.checkpw(passwordController.text.trim(), res['password']);

        if (isValid) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('LoggedIn', true);
          await prefs.setString('username', res['username']);
          await prefs.setString('role', res['role']);
          await prefs.setString('userId', res['id'].toString());

          if (!mounted) return;

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
        content: Text(
          msg,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('LoggedIn') == true) {
      final username = prefs.getString('username') ?? '';
      final role = prefs.getString('role') ?? 'User';
      final userId = prefs.getString('userId') ?? '';

      final res = await Supabase.instance.client
          .from('users')
          .select()
          .eq('username', username)
          .maybeSingle();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => WeatherScreen(
            username: username,
            email: res?['email'] ?? '',
            role: role,
            userId: userId,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue.shade300,

      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),

            child: Padding(
              padding: const EdgeInsets.all(24),

              child: Column(
                children: [
                  const Icon(Icons.person, size: 90, color: Colors.white),
                  const SizedBox(height: 30),

                  // USERNAME
                  TextField(
                    controller: usernameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Username",
                      labelStyle: TextStyle(color: Colors.white),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white70),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // PASSWORD
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Password",
                      labelStyle: const TextStyle(color: Colors.white),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white70),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // LOGIN BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.lightBlue,
                      ),
                      onPressed: isLoading ? null : login,
                      child: isLoading
                          ? const CircularProgressIndicator(
                        color: Colors.lightBlue,
                      )
                          : const Text("Login"),
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "Forgot Password",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),

                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterPage(),
                        ),
                      );
                    },
                    child: const Text(
                      "Don't have an account? Register",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}