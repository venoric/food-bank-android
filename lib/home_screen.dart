import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:postgres/postgres.dart';

import 'add_recipe_screen.dart';
import 'favorite_recipes_screen.dart';
import 'landing_screen.dart';
import 'posted_recipes_screen.dart';
import 'recipe.dart';
import 'recipe_information.dart';
import 'secure_storage.dart';
import 'user_profile_screen.dart';

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
        future: _fetchRecipes(),
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
                              child: const Text('User Profile'),
                              onTap: () {
                                // Navigate to the user profile screen
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const UserProfileScreen()),
                                );
                              },
                            ),
                            PopupMenuItem(
                              child: const Text('My Posted Recipes'),
                              onTap: () {
                                // Navigate to the screen with my posted recipes
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => PostedRecipesScreen(refreshRecipeList: _refreshRecipeList)),
                                );
                              },
                            ),
                            PopupMenuItem(
                              child: const Text('Favorite Recipes'),
                              onTap: () {
                                // Navigate to the favorite recipes screen
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const FavoriteRecipesScreen()),
                                );
                              },
                            ),
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
                            ),
                          ];
                        },
                      )
                    ],
                  ),
                  SliverList.separated(
                    itemCount: recipes.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(recipes.elementAt(index).name),
                        leading: Image.network(recipes.elementAt(index).imageURL),
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
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  // Let user add their own recipe to the DB
                  Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AddRecipeScreen(refreshRecipeList: _refreshRecipeList))
                  );
                },
                child: Icon(Icons.add),
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
        }
    );
  }

  // Method to Fetch Recipes from DB
  Future<List<Recipe>> _fetchRecipes() async {
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
    final recipeFetchResult = await conn.execute('SELECT * FROM recipe ORDER BY id ASC');
    final recipeFetchResultList = recipeFetchResult.toList();
    // Close connection to DB
    await conn.close();
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
      int recipeID = int.parse(recipeFetchResultList.elementAt(i)[0]!.toString());
      String recipeName = recipeFetchResultList.elementAt(i)[1]!.toString();
      String recipeIngredients = recipeFetchResultList.elementAt(i)[2]!.toString();
      String recipeInstructions = recipeFetchResultList.elementAt(i)[3]!.toString();
      String recipeCategory = recipeFetchResultList.elementAt(i)[4]!.toString();
      String recipeServings = recipeFetchResultList.elementAt(i)[5]!.toString();
      String recipeImageURL = recipeFetchResultList.elementAt(i)[6]!.toString();
      String recipePoster = recipeFetchResultList.elementAt(i)[7]!.toString();
      recipes.add(Recipe(recipeID, recipeName, recipeIngredients, recipeInstructions, recipeCategory, recipeServings, recipeImageURL, recipePoster));
    }
    return recipes;
  }

  // Method to Refresh Recipes List
  void _refreshRecipeList() {
    setState(() {});
  }
}