import 'package:flutter/material.dart';
import 'package:postgres/postgres.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
        title: Text('Welcome to FoodBank!'),
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
                print("DEBUG: Has connection!");
                // Check for existing account with inputted username and password

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
  late String _username = "", _password = "", _confirmPassword = "", _firstName = "", _lastName = "";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registration'),
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
                // Set username
                _lastName = lastName;
              },
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                // --- User Registration ---

                // Check for empty username, password, confirmPassword, firstName, or lastName
                if (_username.isEmpty || _password.isEmpty || _confirmPassword.isEmpty || _firstName.isEmpty || _lastName.isEmpty) {
                  // Display error message to user

                  return;
                }
                // Validate input

                // Connect to DB
                final conn = await Connection.open(
                  Endpoint(
                    host: 'food-bank-database.c72m8ic4gtlt.us-east-1.rds.amazonaws.com',
                    database: 'food-bank-database',
                    username: 'postgres',
                    password: 'Aminifoodbank123',
                  )
                );
                print("DEBUG: Has connection!");
                // Check for existing account details (such as username and email)

                // Show registration success message

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
    );
  }
}