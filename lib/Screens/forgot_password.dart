import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Services/otp_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirm = true;
  bool isLoading = false;

  final supabase = Supabase.instance.client;

  Future<void> sendOTP() async {
    final email = emailController.text.trim();
    final rawPassword = passwordController.text.trim();
    final confirm = confirmController.text.trim();

    if (email.isEmpty || rawPassword.isEmpty || confirm.isEmpty) {
      _show("Field must not be empty", true);
      return;
    }

    if (rawPassword != confirm) {
      _show("Passwords do not match", true);
      return;
    }

    setState(() => isLoading = true);

    try {
      final res = await supabase.functions.invoke(
        'forgot-password',
        body: {'email': email},
      );

      if (res.data != null && res.data['error'] != null) {
        _show(res.data['error'], true);
        return;
      }

      _show("OTP sent to your email", false);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OTPScreen(
            email: email,
            newPassword: rawPassword,
          ),
        ),
      );
    } catch (e) {
      _show("Error: $e", true);
    } finally {
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
    passwordController.dispose();
    confirmController.dispose();
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

                // EMAIL
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

                // NEW PASSWORD
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "New Password",
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
                        setState(() => obscurePassword = !obscurePassword);
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // CONFIRM PASSWORD
                TextField(
                  controller: confirmController,
                  obscureText: obscureConfirm,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Confirm Password",
                    labelStyle: const TextStyle(color: Colors.white),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white70),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirm
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() => obscureConfirm = !obscureConfirm);
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.lightBlue,
                    ),
                    onPressed: isLoading ? null : sendOTP,
                    child: isLoading
                        ? const CircularProgressIndicator(
                      color: Colors.lightBlue,
                    )
                        : const Text("Send OTP"),
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