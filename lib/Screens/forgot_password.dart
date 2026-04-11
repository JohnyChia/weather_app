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

  final emailFocus = FocusNode();
  final passwordFocus = FocusNode();
  final confirmFocus = FocusNode();

  bool obscurePassword = true;
  bool obscureConfirm = true;
  bool isLoading = false;

  final supabase = Supabase.instance.client;

  String generateOtp() {
    return (1000 + (DateTime.now().millisecondsSinceEpoch % 9000))
        .toString()
        .substring(0, 4);
  }

  Future<void> sendOTP() async {
    final email = emailController.text.trim();
    final rawPassword = passwordController.text.trim();
    final confirm = confirmController.text.trim();

    if (email.isEmpty || rawPassword.isEmpty || confirm.isEmpty) {
      _show("Field must not be empty", true);
      return;
    }

    setState(() => isLoading = true);

    try {
      final res = await supabase.functions.invoke(
        'forgot-password',
        body: {
          'email': email,
        },
      );

      if (res.data != null && res.data['error'] != null) {
        _show(res.data['error'], true);
        return;
      }

      _show("OTP sent to your email", false);

      if(!mounted){
        return;
      }

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
        content: Text(msg),
        backgroundColor: err ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    confirmFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Forgot Password")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              focusNode: emailFocus,
              decoration: const InputDecoration(labelText: "Email"),
              textInputAction: TextInputAction.next,
              onSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(passwordFocus),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: passwordController,
              focusNode: passwordFocus,
              obscureText: obscurePassword,
              decoration: InputDecoration(
                labelText: "New Password",
                suffixIcon: IconButton(
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() => obscurePassword = !obscurePassword);
                  },
                ),
              ),
              textInputAction: TextInputAction.next,
              onSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(confirmFocus),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: confirmController,
              focusNode: confirmFocus,
              obscureText: obscureConfirm,
              decoration: InputDecoration(
                labelText: "Confirm Password",
                suffixIcon: IconButton(
                  icon: Icon(
                    obscureConfirm
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() => obscureConfirm = !obscureConfirm);
                  },
                ),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => sendOTP(),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: isLoading ? null : sendOTP,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text("Send OTP"),
            ),
          ],
        ),
      ),
    );
  }
}