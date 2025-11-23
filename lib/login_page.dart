import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Login()));
  }
}

class Login extends StatelessWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 390,
      height: 844,
      child: Stack(
        children: [
          Positioned(
            left: 131,
            top: 344,
            child: SizedBox(
              width: 108,
              child: Text(
                'WHO ARE',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),

          Positioned(
            left: 168,
            top: 367,
            child: Text('YOU', style: TextStyle(fontSize: 28)),
          ),

          // BACK button → go back
          Positioned(
            left: 138,
            top: 403,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                width: 120,
                height: 50,
                decoration: BoxDecoration(
                  color: Color(0xFF2C2C2C),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  "BACK",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
