import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'landing_screen.dart';
import 'secure_storage.dart';

void main() {
  runApp(const FoodBankApp());
}

class FoodBankApp extends StatelessWidget {
  const FoodBankApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FoodBank',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: FutureBuilder(
        future: SecureStorage().retrieveLoggedInUser('loggedInUser'),
        builder: (context, snapshot) {
          // Redirect user based on whether or not they are logged in
          if (snapshot.hasData && snapshot.data != 'null') {
            return const HomeScreen();
          } else {
            return const LandingScreen();
          }
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}