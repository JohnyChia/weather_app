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

      if(!mounted){
        return;
      }

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
        content: Text(msg),
        backgroundColor: err ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verify OTP")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Enter OTP (4 digit)",
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: isLoading ? null : resetPassword,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text("Reset Password"),
            ),
          ],
        ),
      ),
    );
  }
}