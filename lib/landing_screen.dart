import 'dart:io';
import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'registration_screen.dart';

// Landing Screen
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome to FoodBank')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 100.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Image.asset(
                'assets/icon/foodbank_logo.png',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
              const SizedBox(
                height: 50,
              ),
              ElevatedButton(
                child: const Text('Login'),
                onPressed: () {
                  // Go to the login screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
              ),
              const SizedBox(
                height: 10,
              ),
              ElevatedButton(
                child: const Text('Register'),
                onPressed: () {
                  // Go to the registration screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegistrationScreen()),
                  );
                },
              ),
            ],
          ),
        )
      )
    );
  }
}