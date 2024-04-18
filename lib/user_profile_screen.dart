import 'package:flutter/material.dart';
import 'package:postgres/postgres.dart';

import 'secure_storage.dart';
import 'user_profile.dart';

// User Profile Screen
class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final List<String> allergyList = <String>['dairy', 'eggs', 'fish', 'peanuts', 'wheat'];
  String? selectedAllergy;
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserProfile> (
      future: _fetchUserProfile(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          // Case: Something went wrong with fetching user profile data from DB
          return const Center(child: Text('Error: Unable to access user information.'));
        } else if (snapshot.hasData) {
          // Case: User profile DB fetching successful
          // Get user profile information from DB
          UserProfile currentUser = snapshot.data!;
          return Scaffold(
            appBar: AppBar(
              title: const Text('User Profile'),
            ),
            body: SingleChildScrollView(
              child: Align(
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Display username
                    const Text('Username', style: TextStyle(decoration: TextDecoration.underline)),
                    Text(currentUser.username),
                    const SizedBox(height: 10),
                    // Display first name
                    const Text('First Name', style: TextStyle(decoration: TextDecoration.underline)),
                    Text(currentUser.firstName),
                    const SizedBox(height: 10),
                    // Display last name
                    const Text('Last Name', style: TextStyle(decoration: TextDecoration.underline)),
                    Text(currentUser.lastName),
                    const SizedBox(height: 10),
                    // Display email
                    const Text('Email', style: TextStyle(decoration: TextDecoration.underline)),
                    Text(currentUser.email),
                    const SizedBox(height: 10),
                    // Display user allergies
                    const Text('Allergies', style: TextStyle(decoration: TextDecoration.underline)),
                    Align(
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ...currentUser.userAllergies.map((allergy) => Align(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(allergy),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () async {
                                    // Remove the user's allergy from the user profile list
                                    currentUser.userAllergies.remove(allergy);
                                    // Remove the user's allergy from the 'user_allergy' table
                                    final conn = await Connection.open(
                                        Endpoint(
                                          host: 'food-bank-database.c72m8ic4gtlt.us-east-1.rds.amazonaws.com',
                                          database: 'food-bank-database',
                                          username: 'postgres',
                                          password: 'Aminifoodbank123',
                                        )
                                    );
                                    // Remove row from DB table with allergy for this user
                                    final removeAllergyFromUserDBResult = await conn.execute(
                                      Sql.named('DELETE FROM user_allergy WHERE username = @username AND allergy = @allergy'),
                                      parameters: {'username': currentUser.username, 'allergy': allergy},
                                    );
                                    // Close connection to DB
                                    await conn.close();
                                    // Refresh state
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),
                          )).toList(),
                        ],
                      ),
                    ),
                    DropdownButton<String>(
                      hint: const Text('Add Allergy'),
                      value: selectedAllergy,
                      onChanged: (value) async {
                        if (value != null && !currentUser.userAllergies.contains(value)) {
                          // Add new allergy to user profile
                          currentUser.userAllergies.add(value);
                          // Add row with new allergy to user_allergy for this user
                          final conn = await Connection.open(
                              Endpoint(
                                host: 'food-bank-database.c72m8ic4gtlt.us-east-1.rds.amazonaws.com',
                                database: 'food-bank-database',
                                username: 'postgres',
                                password: 'Aminifoodbank123',
                              )
                          );
                          final addAllergyToUserDBResult = await conn.execute(
                            Sql.named('INSERT INTO user_allergy VALUES (@username, @allergy)'),
                            parameters: {'username': currentUser.username, 'allergy': value},
                          );
                          // Close connection to DB
                          await conn.close();
                          // Refresh state
                          setState(() {});
                        } else {
                          // Display error message
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('You cannot add the same allergy more than once.'))
                            );
                          }
                        }
                      },
                      items: allergyList.map((allergy) => DropdownMenuItem<String>(
                        value: allergy,
                        child: Text(allergy),
                      )).toList(),
                    ),
                  ],
                ),
              ),
            ),
          );
        } else {
          // Case: User Profile Data Still Being Fetched
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

  // Method to Fetch User Profile from DB
  Future<UserProfile> _fetchUserProfile() async {
    // Fetch currently logged in user's username
    final currentUsername = await SecureStorage().retrieveLoggedInUser('loggedInUser');
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
      Sql.named('SELECT * FROM users WHERE username = @username'),
      parameters: {'username': currentUsername},
    );
    final fetchedUsername = userProfileFetchResult[0][0].toString();
    final fetchedFirstName = userProfileFetchResult[0][2].toString();
    final fetchedLastName = userProfileFetchResult[0][3].toString();
    final fetchedEmail = userProfileFetchResult[0][4].toString();
    // Now, get user allergy information
    final userAllergiesFetchResult = await conn.execute(
      Sql.named('SELECT * FROM user_allergy WHERE username = @username'),
      parameters: {'username': currentUsername},
    );
    // Close connection to DB
    await conn.close();
    // Create variable of type 'UserProfile' with the fetched data
    late UserProfile currentUserProfile = UserProfile(fetchedUsername, fetchedFirstName, fetchedLastName, fetchedEmail);
    int numberOfAllergies = userAllergiesFetchResult.length;
    // Now, add this user's allergies to the UserProfile variable
    for (int i = 0; i < numberOfAllergies; ++i) {
      // Add current allergy
      final String currentAllergy = userAllergiesFetchResult[i][1].toString();
      currentUserProfile.addAllergy(currentAllergy);
    }
    return currentUserProfile;
  }
}