import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  bool isLoading = false;
  bool _lock = false;

  final supabase = Supabase.instance.client;

  Future<void> sendResetEmail() async {
    final email = emailController.text.trim();

    if (_lock) {
      _show("Please wait", true);
      return;
    }

    if (email.isEmpty) {
      _show("Email cannot be empty", true);
      return;
    }

    _lock = true;
    setState(() => isLoading = true);

    try {
      await supabase.auth.resetPasswordForEmail(
        email,
        redirectTo:
        'https://weather-app-rose-omega-82.vercel.app/reset_redirect.html',
      );

      _show("Reset email sent", false);

      Future.delayed(const Duration(seconds: 30), () {
        if (!mounted) return;
        setState(() => _lock = false);
      });

    } catch (e) {
      _show("Error: $e", true);
      _lock = false;
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  void _show(String msg, bool err) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: err ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue.shade300,

      appBar: AppBar(
        backgroundColor: Colors.lightBlue.shade300,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text("Forgot Password"),
      ),

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),

            child: Column(
              children: [
                const Icon(Icons.lock_reset, size: 80, color: Colors.white),
                const SizedBox(height: 30),

                TextField(
                  controller: emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Email",
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

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.lightBlue,
                    ),
                    onPressed: isLoading ? null : sendResetEmail,
                    child: isLoading
                        ? const CircularProgressIndicator(
                      color: Colors.lightBlue,
                    )
                        : const Text("Submit"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}