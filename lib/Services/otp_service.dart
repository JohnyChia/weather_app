import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OTPScreen extends StatefulWidget {
  final String email;
  final String newPassword;

  const OTPScreen({
    super.key,
    required this.email,
    required this.newPassword,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final otpController = TextEditingController();
  bool isLoading = false;

  final supabase = Supabase.instance.client;

  Future<void> resetPassword() async {
    setState(() => isLoading = true);

    try {
      final res = await supabase.functions.invoke(
        'reset-password',
        body: {
          'email': widget.email,
          'otp': otpController.text.trim(),
          'newPassword': widget.newPassword,
        },
      );

      if (res.data['error'] != null) {
        _show(res.data['error'], true);
        return;
      }

      _show("Password reset success", false);

      if (!mounted) return;

      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      _show("Error: $e", true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _show(String msg, bool err) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: err ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ SAME BACKGROUND AS LOGIN
      backgroundColor: Colors.lightBlue.shade300,

      appBar: AppBar(
        title: const Text("Verify OTP"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),

            child: Padding(
              padding: const EdgeInsets.all(24),

              child: Column(
                children: [
                  const Icon(Icons.lock, size: 90, color: Colors.white),

                  const SizedBox(height: 30),

                  // OTP FIELD
                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),

                    decoration: const InputDecoration(
                      labelText: "Enter OTP (4 digit)",
                      labelStyle: TextStyle(color: Colors.white),

                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white70),
                      ),

                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
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
                      onPressed: isLoading ? null : resetPassword,

                      child: isLoading
                          ? const CircularProgressIndicator(
                        color: Colors.lightBlue,
                      )
                          : const Text("Reset Password"),
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