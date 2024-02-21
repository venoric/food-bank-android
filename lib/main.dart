import 'package:flutter/material.dart';
import 'package:postgres/postgres.dart';
import 'package:fluttertoast/fluttertoast.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: FToastBuilder(),
      title: 'FoodBank',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LandingScreen(title: 'FoodBank'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key, required this.title});

  final String title;

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome to FoodBank'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                // Go to login screen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              child: Text('Login'),
            ),
            SizedBox(height: 8.0),
            ElevatedButton(
              onPressed: () {
                // Go to registration screen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegistrationScreen()),
                );
              },
              child: Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatelessWidget {
  // Necessary Variables for Logging In
  late String _username = "", _password = "";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Username',
              ),
              onChanged: (username) {
                // Set username
                _username = username;
              },
            ),
            SizedBox(height: 16.0),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
              ),
              onChanged: (password) {
                // Set password
                _password = password;
              },
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                // --- User Login ---

                // Check for empty username or password
                if (_username.isEmpty || _password.isEmpty) {
                  // Display error message to user
                  Fluttertoast.showToast(
                      msg: 'Please type in a username and password.',
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                      timeInSecForIosWeb: 1,
                      backgroundColor: Colors.grey,
                      textColor: Colors.black
                  );
                  return;
                }
                // Connect to DB
                final conn = await Connection.open(
                  Endpoint(
                    host: 'food-bank-database.c72m8ic4gtlt.us-east-1.rds.amazonaws.com',
                    database: 'food-bank-database',
                    username: 'postgres',
                    password: 'Aminifoodbank123',
                  )
                );
                // Check for existing account with inputted username and password
                final result = await conn.execute(
                  Sql.named('SELECT * FROM users WHERE username = @username AND password = @password'),
                  parameters: {'username': _username, 'password': _password},
                );
                if (result.toList().isEmpty) {
                  // Case: No user with the specified username and password exists in the database
                  Fluttertoast.showToast(
                      msg: 'No user with the supplied credentials exists.',
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                      timeInSecForIosWeb: 1,
                      backgroundColor: Colors.grey,
                      textColor: Colors.black
                  );
                  return;
                }
                // Close connection
                await conn.close();
                // Go to home screen if user details were entered correctly
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HomeScreen(title: 'FoodBank Home Screen')),
                );
              },
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}

class RegistrationScreen extends StatelessWidget {
  // Necessary Variables for User Registration
  late String _username = "", _password = "", _confirmPassword = "", _firstName = "", _lastName = "", _email = "";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registration'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Username',
              ),
              onChanged: (username) {
                // Set username
                _username = username;
              },
            ),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
              ),
              onChanged: (password) {
                // Set password
                _password = password;
              },
            ),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
              ),
              onChanged: (confirmPassword) {
                // Set confirmPassword
                _confirmPassword = confirmPassword;
              },
            ),
            TextField(
              decoration: InputDecoration(
                labelText: 'First Name',
              ),
              onChanged: (firstName) {
                // Set firstName
                _firstName = firstName;
              },
            ),
            TextField(
              decoration: InputDecoration(
                labelText: 'Last Name',
              ),
              onChanged: (lastName) {
                // Set lastName
                _lastName = lastName;
              },
            ),
            TextField(
              decoration: InputDecoration(
                labelText: 'Email',
              ),
              onChanged: (email) {
                // Set email
                _email = email;
              },
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                // --- User Registration ---

                // Check for empty _username, _password, _confirmPassword, _firstName, _lastName, or _email
                if (_username.isEmpty || _password.isEmpty || _confirmPassword.isEmpty || _firstName.isEmpty || _lastName.isEmpty || _email.isEmpty) {
                  // Display error message to user
                  Fluttertoast.showToast(
                      msg: 'Please fill out every field.',
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                      timeInSecForIosWeb: 1,
                      backgroundColor: Colors.grey,
                      textColor: Colors.black
                  );
                  return;
                }
                // Validate input
                // - Check for whitespaces in any of the fields

                // - Check for un-matching passwords
                if (_password != _confirmPassword) {
                  // Display error message to user
                  Fluttertoast.showToast(
                      msg: 'Please type in matching passwords.',
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                      timeInSecForIosWeb: 1,
                      backgroundColor: Colors.grey,
                      textColor: Colors.black
                  );
                  return;
                }
                // Connect to DB
                final conn = await Connection.open(
                  Endpoint(
                    host: 'food-bank-database.c72m8ic4gtlt.us-east-1.rds.amazonaws.com',
                    database: 'food-bank-database',
                    username: 'postgres',
                    password: 'Aminifoodbank123',
                  )
                );
                // Check for existing account details (i.e. username and email)
                final accountCheckResult = await conn.execute(
                  Sql.named('SELECT * FROM users WHERE username = @username OR email = @email'),
                  parameters: {'username': _username, 'email': _email},
                );
                if (accountCheckResult.toList().isNotEmpty) {
                  // Case: A user with the specified username and/or email already exists in the database
                  Fluttertoast.showToast(
                      msg: 'A user with the specified username and/or email already exists.',
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                      timeInSecForIosWeb: 1,
                      backgroundColor: Colors.grey,
                      textColor: Colors.black
                  );
                  return;
                }
                // Add user to the database
                final addUserResult = await conn.execute(
                  Sql.named('INSERT INTO users (username, password, first_name, last_name, email) VALUES (@username, @password, @first_name, @last_name, @email)'),
                  parameters: {'username': _username, 'password': _password, 'first_name': _firstName, 'last_name': _lastName, 'email': _email},
                );
                // Show registration success message
                Fluttertoast.showToast(
                    msg: 'Registration successful!',
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                    timeInSecForIosWeb: 1,
                    backgroundColor: Colors.grey,
                    textColor: Colors.black
                );
                // Close connection
                await conn.close();
                // Go to home screen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HomeScreen(title: 'FoodBank Home Screen')),
                );
              },
              child: Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title});

  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('FoodBank'),
      ),
      body: Column(
        children: [
          Center(
            child: Container(
              child: Text('Welcome to FoodBank'),
            ),
          ),
        ],
      ),
    );
  }
}