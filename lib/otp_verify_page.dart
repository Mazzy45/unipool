import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';

class OtpVerifyPage extends StatefulWidget {
  final String email;
  final String role;
  final Map<String, String> userData;
  final String otp;

  const OtpVerifyPage({
    super.key,
    required this.email,
    required this.role,
    required this.userData,
    required this.otp,
  });

  @override
  State<OtpVerifyPage> createState() => _OtpVerifyPageState();
}

class _OtpVerifyPageState extends State<OtpVerifyPage> {
  final _otpController = TextEditingController();

  void verifyOtp() async {
    if (_otpController.text == widget.otp) {
      final prefs = await SharedPreferences.getInstance();

      final userDatatoSave = {
        "role": widget.role,
        "isVerified": "true", // Mark as verified
        ...widget.userData,
      };

      prefs.setString(widget.email, jsonEncode(userDatatoSave));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid OTP. Try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: SafeArea(
      child: Container(
        constraints: const BoxConstraints.expand(),
        color: const Color(0xFFFFFFFF),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              // Use a Spacer to position the card similarly
              SizedBox(height: MediaQuery.of(context).size.height * 0.15),
              
              Container(
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  // MATCH THE BORDER AND ROUNDED CORNERS
                  border: Border.all(
                    color: const Color(0xFF000000),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  color: const Color(0xFFFFFFFF),
                ),
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    // UniPool Logo and Text (COPY FROM LOGIN PAGE)
                    // ... (Add your Logo and "UniPool" text here) ...

                    // Title
                    const Padding(
                      padding: EdgeInsets.only(bottom: 29, top: 10),
                      child: Text(
                        "Verify Your Account",
                        style: TextStyle(
                          color: Color(0xFF898686),
                          fontSize: 13,
                        ),
                      ),
                    ),

                    // OTP FIELD
                    _buildOtpTextField(),
                    
                    // VERIFY BUTTON
                    _buildVerifyButton(),

                    // Resend Link/Hint
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        "Code sent to ${widget.email}",
                        style: TextStyle(fontSize: 12, color: Color(0xFF898686)),
                      ),
                    ),
                  ],
                ),
              ),
              // Use a Spacer at the bottom
              SizedBox(height: MediaQuery.of(context).size.height * 0.15),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildOtpTextField() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 37),
        child: Text(
          "Verification Code",
          style: const TextStyle(
            color: Color(0xFF000000),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: const Color(0xFFD9D9D9), // MATCHES INPUT BACKGROUND
        ),
        margin: const EdgeInsets.only(bottom: 25, left: 28, right: 28),
        width: double.infinity,
        child: TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center, // Center the OTP numbers
          style: const TextStyle(
            color: Color(0xFF000000), // Change color from grey to black for entry
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 10.0, // Space out the digits
          ),
          decoration: const InputDecoration(
            hintText: "••••••",
            isDense: true,
            contentPadding:
                EdgeInsets.only(top: 7, bottom: 7, left: 14, right: 14),
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
          ),
        ),
      ),
    ],
  );
}

Widget _buildVerifyButton() {
  const loginButtonColor = Color(0xFF15273C); // MATCHES BUTTON COLOR

  return Padding(
    padding: const EdgeInsets.only(bottom: 26, left: 28, right: 28),
    child: InkWell(
      onTap: verifyOtp,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: loginButtonColor,
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        width: double.infinity,
        child: const Center(
          child: Text(
            "Verify Account",
            style: TextStyle(
              color: Color(0xFFFFFDFD),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ),
  );
}
}
