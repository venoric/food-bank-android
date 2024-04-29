import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:postgres/postgres.dart';

import 'home_screen.dart';
import 'secure_storage.dart';

// Registration Screen
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _username, _password, _confirmPassword, _firstName, _lastName, _email;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Register')),
        body: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const SizedBox(
                    height: 20.0,
                  ),
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
                    height: 10.0,
                  ),
                  SizedBox(
                    width: 300.0,
                    child: TextFormField(
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirm Password',
                      ),
                      validator: (inputtedConfirmPassword) {
                        if (inputtedConfirmPassword == null || inputtedConfirmPassword.isEmpty) {
                          return 'Please enter your password a second time';
                        }
                        // Set '_confirmPassword' for later use (matching password check)
                        _confirmPassword = inputtedConfirmPassword;
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
                      decoration: const InputDecoration(
                        labelText: 'First Name',
                      ),
                      validator: (inputtedFirstName) {
                        if (inputtedFirstName == null || inputtedFirstName.isEmpty) {
                          return 'Please enter your first name';
                        }
                        // Set '_firstName' for later use (DB query)
                        _firstName = inputtedFirstName;
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
                      decoration: const InputDecoration(
                        labelText: 'Last Name',
                      ),
                      validator: (inputtedLastName) {
                        if (inputtedLastName == null || inputtedLastName.isEmpty) {
                          return 'Please enter your last name';
                        }
                        // Set '_lastName' for later use (DB query)
                        _lastName = inputtedLastName;
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
                      decoration: const InputDecoration(
                        labelText: 'Email',
                      ),
                      validator: (inputtedEmail) {
                        if (inputtedEmail == null || inputtedEmail.isEmpty) {
                          return 'Please enter your email';
                        }
                        // Set '_email' for later use (DB query)
                        _email = inputtedEmail;
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(
                    height: 10.0,
                  ),
                  ElevatedButton(
                      child: const Text('Register'),
                      onPressed: () async {
                        // Validate and submit registration form
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
                          // Check if account with the provided username already exists using DB query
                          final existingUsernameResult = await conn.execute(
                            Sql.named('SELECT * FROM users WHERE username = @username'),
                            parameters: {'username': _username},
                          );
                          final existingUsernameResultList = existingUsernameResult.toList();
                          // Check if user with the provided email already exists using DB query
                          final existingEmailResult = await conn.execute(
                            Sql.named('SELECT * FROM users WHERE email = @email'),
                            parameters: {'email': _email},
                          );
                          final existingEmailResultList = existingEmailResult.toList();
                          if (existingUsernameResultList.isNotEmpty) {
                            // Case: An account with the provided username already exists in the DB
                            // Display message
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('An account with the provided username already exists'))
                              );
                            }
                            return;
                          }
                          if (existingEmailResultList.isNotEmpty) {
                            // Case: An account with the provided email already exists in the DB
                            // Display message
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('An account with the provided email already exists'))
                              );
                            }
                            return;
                          }
                          // Check for un-matching passwords
                          if (_password != _confirmPassword) {
                            // Display message
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please type in matching passwords'))
                              );
                            }
                            return;
                          }
                          // Create an account with the provided details
                          await conn.execute(
                            Sql.named('INSERT INTO users (username, password, first_name, last_name, email) VALUES (@username, @password, @firstName, @lastName, @email)'),
                            parameters: {'username': _username, 'password': _password, 'firstName': _firstName, 'lastName': _lastName, 'email': _email},
                          );
                          // Check if account exists now in the DB
                          final accountExistsNowResult = await conn.execute(
                            Sql.named('SELECT * FROM users WHERE username = @username AND password = @password AND first_name = @firstName AND last_name = @lastName AND email = @email'),
                            parameters: {'username': _username, 'password': _password, 'firstName': _firstName, 'lastName': _lastName, 'email': _email},
                          );
                          final accountExistsNowResultList = accountExistsNowResult.toList();
                          // Close connection to DB
                          await conn.close();
                          if (accountExistsNowResultList.isNotEmpty) {
                            // Case: Account now exists in the DB
                            // Display message
                            if (context.mounted) {
                              Fluttertoast.showToast(
                                  msg: 'Registration Successful',
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
                            // Case: Account was not successfully created
                            // Display message
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Registration Failed!'))
                              );
                            }
                          }
                        }
                      }
                  ),
                ],
              ),
            ),
          ),
        )
    );
  }
}