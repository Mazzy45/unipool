import 'dart:convert';
import 'dart:math' as math;
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; 
import 'otp_verify_page.dart';
import 'login_page.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  UserRole _currentRole = UserRole.passenger; // Use the enum
  String? licenseFileName;
  bool sendingOtp = false;

  // Placeholder images provided by the original code
  static const String _passengerIconUrl = "https://storage.googleapis.com/tagjs-prod.appspot.com/v1/tTDeXqFOUJ/hid6fyeh_expires_30_days.png";
  static const String _driverIconUrl = "https://storage.googleapis.com/tagjs-prod.appspot.com/v1/tTDeXqFOUJ/fm2fw7gz_expires_30_days.png";
  static const String _logoIconUrl = "https://storage.googleapis.com/tagjs-prod.appspot.com/v1/tTDeXqFOUJ/1vfnjyz3_expires_30_days.png";

  // Use explicit types
  final Map<String, String> passenger = {
    "name": "",
    "email": "",
    "phone": "",
    "matricNumber": "",
    "graduationDate": "",
    "password": "",
    "confirmPassword": "",
  };

  final Map<String, String> driver = {
    "name": "",
    "email": "",
    "phone": "",
    "matricNumber": "",
    "graduationDate": "",
    "licenseNumber": "",
    "password": "",
    "confirmPassword": "",
  };

  Future<void> pickLicenseFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ["jpg", "png", "jpeg", "pdf"],
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          licenseFileName = result.files.first.name;
        });
        log('Picked license file: $licenseFileName');
      } else {
        log('File picker returned null or empty');
      }
    } catch (e, st) {
      log('File pick error: $e', error: e, stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to pick file'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String generateOtp() {
    final rand = math.Random();
    return (100000 + rand.nextInt(900000)).toString(); // 6-digit OTP
  }

  Future<bool> sendOtpEmail(String email, String otp) async {
    try {
      final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "service_id": "service_6rn22x8",
          "template_id": "template_9hwe1um",
          "user_id": "rq_vxhtJNM2Kgt9fb",
          "template_params": {
            "to_email": email,
            "otp": otp,
          }
        }),
      );

      log('EmailJS response: ${response.statusCode} ${response.body}');
      return response.statusCode == 200;
    } catch (e, st) {
      log('sendOtpEmail error: $e', error: e, stackTrace: st);
      return false;
    }
  }

  /// Basic validation: check required fields and enforce constraints
  String? validateFields(Map<String, String> userData, bool isPassenger) {
  // Required keys:
    final required = [
      "name",
      "email",
      "phone",
      "matricNumber",
      "graduationDate",
      "password",
      "confirmPassword"
    ];
    
    // --- 1. Check for Empty Fields ---
    for (final key in required) {
      if ((userData[key] ?? "").trim().isEmpty) {
        return 'Please enter your ${key.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[0]}').toLowerCase().trim()}.';
      }
    }
    
    // --- 2. Driver Specific Field Checks ---
    if (!isPassenger) {
      if ((userData["licenseNumber"] ?? "").trim().isEmpty) {
        return 'Please enter your driver license number.';
      }
      if (licenseFileName == null) {
        return 'Please upload your license file.';
      }
    }
    
    // --- 3. Password Match Check ---
    final password = userData["password"] ?? "";
    if (password != userData["confirmPassword"]) {
      return 'Passwords do not match.';
    }

    // --- 4. Password Strength Check (New Rule) ---
    if (password.length < 8) {
      return 'Password must be at least 8 characters long.';
    }
    // Must contain an uppercase letter
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password must contain at least one uppercase letter.';
    }
    // Must contain a lowercase letter
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Password must contain at least one lowercase letter.';
    }
    // Must contain a number
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Password must contain at least one number.';
    }
    // Must contain a symbol (non-alphanumeric character)
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      return 'Password must contain at least one symbol (e.g., !, @, #).';
    }

    // --- 5. Email Format Check (Updated with Specific Domain Rule) ---
    final email = userData["email"] ?? "";

    // Check for the specific USM student domain
    const usmStudentDomain = '@student.usm.my';
    if (!email.toLowerCase().endsWith(usmStudentDomain)) {
      return 'Email must be a valid USM student email (ending in $usmStudentDomain).';
    }
    
    // Basic email format check for the part before the domain (already enforced implicitly by the endswith check, but good practice)
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@').hasMatch(email)) {
      return 'Please enter a valid email address (username part is invalid).';
    }
    return null; // All checks passed
  }

  void handleSignup(bool isPassenger) async {
    final userData = isPassenger ? passenger : driver;

    final validationMessage = validateFields(userData, isPassenger);
    if (validationMessage != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationMessage),
          backgroundColor: Colors.red,
        ),
      );
      log('Signup validation failed: $validationMessage');
      return;
    }
    
    final email = userData["email"]!; 

    // --- ACCOUNT DUPLICATION CHECK (NEW LOGIC) ---
    final prefs = await SharedPreferences.getInstance();
    final existingUserData = prefs.getString(email);

    if (existingUserData != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account already exists for this email. Please log in.'),
          backgroundColor: Colors.orange,
        ),
      );
      log('Signup failed: Attempted to register existing email: $email');
      return; // Stop the sign-up process
    }
    // --- END ACCOUNT DUPLICATION CHECK ---


    // Ok start sending OTP
    setState(() {
      sendingOtp = true;
    });

    final otp = generateOtp();
    log('Generated OTP for ${userData["email"]}: $otp');

    final emailSent = await sendOtpEmail(userData["email"]!, otp);

    // guard context after async call
    if (!mounted) return;

    setState(() {
      sendingOtp = false;
    });

    if (emailSent) {
      log('OTP sent successfully to ${userData["email"]}');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerifyPage(
            email: userData["email"]!,
            role: isPassenger ? "passenger" : "driver",
            userData: userData,
            otp: otp,
          ),
        ),
      );
    } else {
      log('Failed to send OTP to ${userData["email"]}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send OTP. Try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --- UI Builder Methods (Adapted from LoginPage) ---

  Widget _buildRoleToggle() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: const Color(0xFFD9D9D9),
      ),
      padding: const EdgeInsets.all(3),
      margin: const EdgeInsets.only(bottom: 28, left: 28, right: 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Passenger Toggle Button
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _currentRole = UserRole.passenger),
              child: _buildRoleButton(
                role: UserRole.passenger,
                iconUrl: _passengerIconUrl,
                text: "Passenger",
              ),
            ),
          ),
          // Driver Toggle Button
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _currentRole = UserRole.driver),
              child: _buildRoleButton(
                role: UserRole.driver,
                iconUrl: _driverIconUrl,
                text: "Driver",
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleButton({
    required UserRole role,
    required String iconUrl,
    required String text,
  }) {
    final bool isActive = _currentRole == role;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isActive ? Colors.white : Colors.transparent,
        boxShadow: isActive
            ? const [
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 4,
                  offset: Offset(0, 4),
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Using a placeholder image for the icon
          Image.network(
            iconUrl,
            width: 20,
            height: 20,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.person,
              size: 20,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF000000),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  // Reusable input builder (styled like LoginPage's text field)
  Widget _buildTextField(
      String label, String hint, ValueChanged<String> onChanged, bool isPassword, {TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 37),
          child: Text(
            label,
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
            color: const Color(0xFFD9D9D9),
          ),
          margin: const EdgeInsets.only(bottom: 25, left: 28, right: 28),
          width: double.infinity,
          child: TextField(
            obscureText: isPassword,
            keyboardType: keyboardType,
            style: const TextStyle(
              color: Color(0xFF898686),
              fontSize: 13,
            ),
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              isDense: true,
              contentPadding:
                  const EdgeInsets.only(top: 7, bottom: 7, left: 14, right: 14),
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
            ),
          ),
        ),
      ],
    );
  }

  // --- Main Build Method ---

  @override
  Widget build(BuildContext context) {
    final isPassenger = _currentRole == UserRole.passenger;
    final userData = isPassenger ? passenger : driver;
    final signupButtonText = isPassenger ? "Create Account as Passenger" : "Create Account as Driver";
    final signupButtonColor = const Color(0xFF15273C);

    // List of common fields
    final List<Widget> commonFields = [
      _buildTextField(
        "Full Name",
        "Enter your full name",
        (v) => userData["name"] = v,
        false,
      ),
      _buildTextField(
        "Email",
        "Enter your email",
        (v) => userData["email"] = v,
        false,
        keyboardType: TextInputType.emailAddress,
      ),
      _buildTextField(
        "Phone Number",
        "Enter your phone number",
        (v) => userData["phone"] = v,
        false,
        keyboardType: TextInputType.phone,
      ),
      _buildTextField(
        "Matric Number",
        "Enter your matric number",
        (v) => userData["matricNumber"] = v,
        false,
      ),
      _buildTextField(
        "Graduation Date",
        "mm/yyyy",
        (v) => userData["graduationDate"] = v,
        false,
      ),
    ];

    // Driver specific fields
    final List<Widget> driverFields = [
      _buildTextField(
        "Driver License Number",
        "Enter your license number",
        (v) => userData["licenseNumber"] = v,
        false,
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 37),
        child: const Text(
          "License File",
          style: TextStyle(
            color: Color(0xFF000000),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      Container(
        margin: const EdgeInsets.only(bottom: 25, left: 28, right: 28),
        child: OutlinedButton.icon(
          onPressed: pickLicenseFile,
          icon: const Icon(Icons.upload_file, color: Color(0xFF15273C)),
          label: Text(
            licenseFileName ?? "Choose File",
            style: const TextStyle(color: Color(0xFF15273C)),
          ),
          style: OutlinedButton.styleFrom(
            backgroundColor: const Color(0xFFD9D9D9),
            minimumSize: const Size.fromHeight(40),
            side: const BorderSide(color: Color(0xFFD9D9D9)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    ];
    
    // Password fields (common for both roles)
    final List<Widget> passwordFields = [
      _buildTextField(
        "Password",
        "Create a password",
        (v) => userData["password"] = v,
        true,
      ),
      _buildTextField(
        "Confirm Password",
        "Confirm your password",
        (v) => userData["confirmPassword"] = v,
        true,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Container(
          constraints: const BoxConstraints.expand(),
          color: const Color(0xFFFFFFFF),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // Spacer to center the content vertically
                SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  decoration: BoxDecoration(
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
                      // UniPool Logo
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.network(
                              _logoIconUrl,
                              width: 30,
                              height: 30,
                              fit: BoxFit.fill,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.car_rental, size: 30),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              "UniPool",
                              style: TextStyle(
                                color: Color(0xFF000000),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Welcome Message
                      const Padding(
                        padding: EdgeInsets.only(bottom: 29, top: 10),
                        child: Text(
                          "Create your account to get started.",
                          style: TextStyle(
                            color: Color(0xFF898686),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      
                      // Role Toggle
                      _buildRoleToggle(),
                      
                      // --- Form Fields ---
                      ...commonFields,
                      if (!isPassenger) ...driverFields,
                      ...passwordFields,

                      // Sign Up Button
                      Padding(
                        padding: const EdgeInsets.only(bottom: 26, left: 28, right: 28),
                        child: InkWell(
                          onTap: sendingOtp ? null : () => handleSignup(isPassenger),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: signupButtonColor.withAlpha(sendingOtp ? 153 : 255),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            width: double.infinity,
                            child: Center(
                              child: sendingOtp
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      signupButtonText,
                                      style: const TextStyle(
                                        color: Color(0xFFFFFDFD),
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                      
                      // Back to Login Link
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Already have an account?",
                              style: TextStyle(
                                color: Color(0xFF898686),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () => Navigator.pop(context), // Go back to LoginPage
                              child: const Text(
                                "Log In",
                                style: TextStyle(
                                  color: Color(0xFF000000),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Spacer at the bottom to ensure vertical centering is nice
                SizedBox(height: MediaQuery.of(context).size.height * 0.05),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
