import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:postgres/postgres.dart';

import 'home_screen.dart';
import 'secure_storage.dart';

// Login Screen
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _username, _password;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Form(
        key: _formKey,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                width: 300.0,
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Username',
                  ),
                  validator: (inputtedUsername) {
                    if (inputtedUsername == null || inputtedUsername.isEmpty) {
                      return 'Please enter a username';
                    }
                    // Set '_username' for later use (DB query)
                    _username = inputtedUsername;
                    return null;
                  },
                ),
              ),
              const SizedBox(
                height: 10.0,
              ),
              SizedBox(
                width: 300.0,
                child: TextFormField(
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                  ),
                  validator: (inputtedPassword) {
                    if (inputtedPassword == null || inputtedPassword.isEmpty) {
                      return 'Please enter a password';
                    }
                    // Set '_password' for later use (DB query)
                    _password = inputtedPassword;
                    return null;
                  },
                ),
              ),
              const SizedBox(
                height: 30.0,
              ),
              ElevatedButton(
                child: const Text('Login'),
                onPressed: () async {
                  // Validate and submit login form
                  if (_formKey.currentState!.validate()) {
                    // DB Connection Info
                    final conn = await Connection.open(
                        Endpoint(
                          host: 'food-bank-database.c72m8ic4gtlt.us-east-1.rds.amazonaws.com',
                          database: 'food-bank-database',
                          username: 'postgres',
                          password: 'Aminifoodbank123',
                        )
                    );
                    // Check if account with the provided credentials exists using DB query
                    final validAccountResult = await conn.execute(
                      Sql.named('SELECT username, password FROM users WHERE username = @username AND password = @password'),
                      parameters: {'username': _username, 'password': _password},
                    );
                    final validAccountResultList = validAccountResult.toList();
                    // Close connection to DB
                    await conn.close();
                    // Check DB for matching username and password
                    if (validAccountResultList.isNotEmpty) {
                      // Case: Found an account with the provided credentials
                      // Display message
                      if (context.mounted) {
                        Fluttertoast.showToast(
                            msg: 'Login Successful',
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                            timeInSecForIosWeb: 1
                        );
                      }
                      // Store user session
                      SecureStorage().setLoggedInUser('loggedInUser', _username);
                      // Navigate to home screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HomeScreen()),
                      );
                    } else {
                      // Case: No account with the provided credentials exists
                      // Display message
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No account with the provided credentials exists'))
                        );
                      }
                    }
                  } else {
                    // Display message
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a username and/or password'))
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}