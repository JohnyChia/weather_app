import 'package:flutter/material.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  Future<void> register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final hash = BCrypt.hashpw(
        passwordController.text.trim(),
        BCrypt.gensalt(),
      );

      await Supabase.instance.client.from('users').insert({
        'username': usernameController.text.trim(),
        'email': emailController.text.trim(),
        'password': hash,
        'role': 'User',
      });

      _showMessage("Register success", isError: false);

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      _showMessage("Error: $e", isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showMessage(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue,

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),

            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Icon(Icons.person, size: 80, color: Colors.white),

                  const SizedBox(height: 20),

                  const Text(
                    "Create Account",
                    style: TextStyle(
                      fontSize: 28,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 30),

                  TextFormField(
                    controller: usernameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Username",
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                  ),

                  const SizedBox(height: 15),

                  TextFormField(
                    controller: emailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Email",
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                  ),

                  const SizedBox(height: 15),

                  TextFormField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Password",
                      labelStyle: const TextStyle(color: Colors.white70),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.white,
                        ),
                        onPressed: () =>
                            setState(() => obscurePassword = !obscurePassword),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: obscureConfirmPassword,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Confirm Password",
                      labelStyle: const TextStyle(color: Colors.white70),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.white,
                        ),
                        onPressed: () => setState(() =>
                        obscureConfirmPassword = !obscureConfirmPassword),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : register,
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Register"),
                    ),
                  ),

                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Back to Login",
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