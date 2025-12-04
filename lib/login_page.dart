import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer';
import 'dart:convert';
import 'home_page.dart';
import 'create_account_page.dart';

// Define the two roles for clarity
enum UserRole {
  passenger,
  driver,
}

// --- Login Screen ---

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Login()));
  }
}

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LOGINState();
}

class _LOGINState extends State<Login> {
  // Initial state is set to passenger, mimicking the first file's focus
  UserRole _currentRole = UserRole.passenger;
  String _email = '';
  String _password = '';

  // Placeholder images provided by the original code
  static const String _passengerIconUrl = "https://storage.googleapis.com/tagjs-prod.appspot.com/v1/tTDeXqFOUJ/hid6fyeh_expires_30_days.png";
  static const String _driverIconUrl = "https://storage.googleapis.com/tagjs-prod.appspot.com/v1/tTDeXqFOUJ/fm2fw7gz_expires_30_days.png";
  static const String _logoIconUrl = "https://storage.googleapis.com/tagjs-prod.appspot.com/v1/tTDeXqFOUJ/1vfnjyz3_expires_30_days.png";
  
  // Role-specific button logic
  void _handleLogin() async {
    String requestedRole = _currentRole == UserRole.passenger ? 'passenger' : 'driver';

    // 1. Check for empty fields
    if (_email.isEmpty || _password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both your email and password.'),
          backgroundColor: Colors.red,
        ),
      );
      log('Login failed: Email or Password field is empty.');
      return;
    }

    // 2. Check for required email domain
    const String requiredDomain = '@student.usm.my';
    if (!_email.toLowerCase().endsWith(requiredDomain)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login requires a valid student email ending with $requiredDomain.'),
          backgroundColor: Colors.orange,
        ),
      );
      log('Login failed: Invalid email domain.');
      return;
    }

    // 3. Check SharedPreferences for registered account
    final prefs = await SharedPreferences.getInstance();
    final userDataJSon = prefs.getString(_email);

    if (userDataJSon == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account does not exist.'),
          backgroundColor: Colors.red,
        ),
      );
      log('Login failed: Account not found.');
      return;
    }

    final userData = jsonDecode(userDataJSon) as Map<String, dynamic>;
    final savedRole = (userData['role'] as String).toLowerCase();
    final savedPassword = userData['password'];
    final isVerified = userData['isVerified'] == 'true';

    if (!isVerified) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account not verified. Please verify your account first.'),
          backgroundColor: Colors.red,
        ),
      );
      log('Login failed: Account not verified.');
      return;
    }

    if (savedRole != requestedRole.toLowerCase()) {
      if (!mounted) return;
      String displayRole = savedRole;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please log in as a $displayRole. Please switch your role selection.'),
          backgroundColor: Colors.orange,
        ),
      );
      log('Login failed: Role mismatch. Saved: $savedRole. Requested: $requestedRole.');
      return;
    }

    if (savedPassword != _password) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incorrect password.'),
          backgroundColor: Colors.red,
        ),
      );
      log('Login failed: Wrong password.');
      return;
    }

    // --- LOGIN SUCCESS ---
    log('Login successful as ${requestedRole.toLowerCase()} with Email: $_email');

    if (_currentRole == UserRole.passenger) {
      if (!mounted) return;
      // Navigate to Dashboard for passenger
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
  }

  // --- UI Builder Methods ---

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

  Widget _buildTextField(
      String label, String hint, ValueChanged<String> onChanged, bool isPassword) {
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

  @override
  Widget build(BuildContext context) {
    final isPassenger = _currentRole == UserRole.passenger;
    final loginButtonText = isPassenger ? "Log In as Passenger" : "Log In as Driver";
    final loginButtonColor = const Color(0xFF15273C);

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
                SizedBox(height: MediaQuery.of(context).size.height * 0.15),
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
                          "Welcome back! Log in to your account.",
                          style: TextStyle(
                            color: Color(0xFF898686),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      
                      // Role Toggle
                      _buildRoleToggle(),

                      // Email Field
                      _buildTextField(
                        "Email",
                        "Enter your email",
                        (value) => setState(() => _email = value),
                        false,
                      ),

                      // Password Field
                      _buildTextField(
                        "Password",
                        "Enter your password",
                        (value) => setState(() => _password = value),
                        true,
                      ),

                      // Forgot Password Link
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 34, right: 32),
                          child: InkWell(
                            onTap: () => log('Forgot Password clicked'),
                            child: const Text(
                              "Forgot Password?",
                              style: TextStyle(
                                color: Color(0xFF000000),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Login Button
                      Padding(
                        padding: const EdgeInsets.only(bottom: 26, left: 28, right: 28),
                        child: InkWell(
                          onTap: _handleLogin, // Calls the navigation logic
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: loginButtonColor,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            width: double.infinity,
                            child: Center(
                              child: Text(
                                loginButtonText,
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

                      // Create Account Link
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Don’t have an account?",
                              style: TextStyle(
                                color: Color(0xFF898686),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const CreateAccountPage()),
                              ),
                              child: const Text(
                                "Create Account",
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
                SizedBox(height: MediaQuery.of(context).size.height * 0.15),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
