import 'package:flutter/material.dart';
import 'package:postgres/postgres.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Recipe Class
class Recipe {
  // Member Variables
  late String _name;
  late String _ingredients;
  late String _instructions;
  late String _category;
  late String _servings;
  late String _imageURL;
  // Constructor
  Recipe(String recipeName, String recipeIngredients, String recipeInstructions, String recipeCategory, String recipeServings, String recipeImageURL) {
    this._name = recipeName;
    this._ingredients = recipeIngredients;
    this._instructions = recipeInstructions;
    this._category = recipeCategory;
    this._servings = recipeServings;
    this._imageURL = recipeImageURL;
  }
}

// User Profile Class
class UserProfile {
  // Member Variables
  late String _username;
  late String _firstName;
  late String _lastName;
  late List<String> _userAllergies;
  // Constructor
  UserProfile(String username, String firstName, String lastName) {
    this._username = username;
    this._firstName = firstName;
    this._lastName = lastName;
  }
  // Methods
  void addAllergy(String currentAllergy) {
    this._userAllergies.add(currentAllergy);
  }
}

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
        future: SecureStorage().retrieveLoggedInUser("loggedInUser"),
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

// "Secure Storage" Class for Login Check
class SecureStorage {
  final _storage = const FlutterSecureStorage();

  // Store the username of the user who logged in
  setLoggedInUser(String key, String loggedInUser) async {
    await _storage.write(key: 'loggedInUser', value: loggedInUser);
  }

  // Retrieve the username of the user who logged in (if applicable)
  Future<String> retrieveLoggedInUser(String key) async {
    String? loggedInUser = await _storage.read(key: key);
    if (loggedInUser != null) {
      // Case: User is logged in
      return loggedInUser;
    } else {
      // Case: No user is logged in
      return 'null';
    }
  }

  // Delete the username of the user who logged out
  unsetLoggedInUser(String key) async {
    await _storage.delete(key: key);
  }
}

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
        appBar: AppBar(title: const Text('FoodBank')),
        body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
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
            )
        )
    );
  }
}

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
                    // Set _username for later use (DB query)
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
                    // Set _password for later use (DB query)
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
                        // Set _username for later use (DB query)
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
                        // Set _password for later use (DB query)
                        _password = inputtedPassword;
                        return null;
                      },
                    ),
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
                        // Set _confirmPassword for later use (matching password check)
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
                        // Set _firstName for later use (DB query)
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
                        // Set _lastName for later use (DB query)
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
                        // Set _email for later use (DB query)
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

// Home Screen
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Recipe>> (
        future: fetchRecipes(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            // Case: Something went wrong with fetching recipe data from DB
            return const Center(child: Text('Error: Unable to fetch recipes.'));
          } else if (snapshot.hasData) {
            // Case: Recipe data DB fetching successful
            // Get recipe information from DB
            List<Recipe> recipes = snapshot.data!;
            return Scaffold(
                body: CustomScrollView(
                  slivers: <Widget>[
                    SliverAppBar(
                      automaticallyImplyLeading: false, // Remove back button
                      title: const Text('FoodBank Home'),
                      pinned: true,
                      actions: <Widget>[
                        PopupMenuButton(
                          icon: const Icon(Icons.more_vert),
                          itemBuilder: (context) {
                            return [
                              PopupMenuItem(
                                child: const Text('Log Out'),
                                onTap: () {
                                  // Remove user session
                                  SecureStorage().unsetLoggedInUser('loggedInUser');
                                  // Navigate back to landing screen
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(builder: (context) => const LandingScreen()),
                                        (_) => false,
                                  );
                                },
                              )
                            ];
                          },
                        )
                      ],
                    ),
                    SliverList.separated(
                      itemCount: recipes.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(recipes.elementAt(index)._name),
                          leading: Image.network(recipes.elementAt(index)._imageURL),
                          onTap: () {
                            // Go to screen for selected recipe and pass over the chosen recipe's Recipe instance as well
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => RecipeInformationScreen(recipes.elementAt(index))),
                            );
                          },
                        );
                      },
                      separatorBuilder: (context, index) => Divider(),
                    )
                  ],
                )
            );
          } else {
            // Case: Recipe Data Still Being Fetched
            // Display loading indicator
            return Container(
              color: Colors.white,
              child: const Center(
                child: CircularProgressIndicator()
              ),
            );
          }
        }
    );
  }
}

class RecipeInformationScreen extends StatelessWidget {
  late final Recipe _currentRecipe;

  RecipeInformationScreen(Recipe recipe, {super.key}) {
    this._currentRecipe = recipe;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              // Display recipe name
              const Text('Recipe', style: TextStyle(decoration: TextDecoration.underline)),
              Text(_currentRecipe._name),
              const SizedBox(height: 10),
              // Display category
              const Text('Category', style: TextStyle(decoration: TextDecoration.underline)),
              Text(_currentRecipe._category),
              const SizedBox(height: 10),
              // Display servings
              const Text('Servings', style: TextStyle(decoration: TextDecoration.underline)),
              Text(_currentRecipe._servings),
              const SizedBox(height: 10),
              // Display recipe image
              Image.network(_currentRecipe._imageURL),
              const SizedBox(height: 10),
              // Display ingredient list
              const Text('Ingredients', style: TextStyle(decoration: TextDecoration.underline)),
              Text('* ${_currentRecipe._ingredients.replaceAll(r'\r\n', '\n* ').replaceAll(';', '')}'),  // Remove semi-colons, and add asterisks as bullet points
              const SizedBox(height: 10),
              // Display instructions
              const Text('Instructions', style: TextStyle(decoration: TextDecoration.underline)),
              Text('* ${_currentRecipe._instructions.replaceAll(r'\r\n', '\n* ').replaceAll(';', '')}'),  // Remove semi-colons, and add asterisks as bullet points
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

// Method to Fetch Recipes from DB
Future<List<Recipe>> fetchRecipes() async {
  late List<Recipe> recipes = <Recipe>[];
  // Connect to DB to fetch recipes
  final conn = await Connection.open(
      Endpoint(
        host: 'food-bank-database.c72m8ic4gtlt.us-east-1.rds.amazonaws.com',
        database: 'food-bank-database',
        username: 'postgres',
        password: 'Aminifoodbank123',
      )
  );
  // Get all recipe names and image URLs for display
  final recipeFetchResult = await conn.execute('SELECT * FROM recipe');
  final recipeFetchResultList = recipeFetchResult.toList();
  if (recipeFetchResultList.isEmpty) {
    // Error Message
    Fluttertoast.showToast(
        msg: 'No recipes found.',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.grey,
        textColor: Colors.black
    );
    return recipes;
  }
  for (var i = 0; i < recipeFetchResultList.length; ++i) {
    // Extract each recipe's details from the DB call results
    String recipeName = recipeFetchResultList.elementAt(i)[1]!.toString();
    String recipeIngredients = recipeFetchResultList.elementAt(i)[2]!.toString();
    String recipeInstructions = recipeFetchResultList.elementAt(i)[3]!.toString();
    String recipeCategory = recipeFetchResultList.elementAt(i)[4]!.toString();
    String recipeServings = recipeFetchResultList.elementAt(i)[5]!.toString();
    String recipeImageURL = recipeFetchResultList.elementAt(i)[6]!.toString();
    recipes.add(Recipe(recipeName, recipeIngredients, recipeInstructions, recipeCategory, recipeServings, recipeImageURL));
  }
  return recipes;
}

/*
// User Profile Screen
class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserProfile> (
      future: fetchUserProfile(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          // Case: Something went wrong with fetching recipe data from DB
          return const Center(child: Text('Error: Unable to access user information.'));
        } else if (snapshot.hasData) {
          // Case: Recipe data DB fetching successful
          // Get recipe information from DB
          UserProfile currentUser = snapshot.data!;
          return Scaffold(
            body: SingleChildScrollView(

            ),
          );
        } else {
          // Case: Recipe Data Still Being Fetched
          // Display loading indicator
          return Container(
            color: Colors.white,
            child: const Center(
                child: CircularProgressIndicator()
            ),
          );
        }
      },
    );
  }
}

// Method to Fetch User Profile from DB
Future<UserProfile> fetchUserProfile(String currentUsername) async {
  // Connect to DB to fetch user information
  final conn = await Connection.open(
      Endpoint(
        host: 'food-bank-database.c72m8ic4gtlt.us-east-1.rds.amazonaws.com',
        database: 'food-bank-database',
        username: 'postgres',
        password: 'Aminifoodbank123',
      )
  );
  // Get user information using DB query
  final userProfileFetchResult = await conn.execute(
    Sql.named('SELECT * FROM allergy WHERE username = @username'),
    parameters: {'username': currentUsername},
  );
  late UserProfile currentUserProfile;
  return currentUserProfile;
}
 */