import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:postgres/postgres.dart';

import 'add_recipe_screen.dart';
import 'favorite_recipes_screen.dart';
import 'landing_screen.dart';
import 'posted_recipes_screen.dart';
import 'recipe.dart';
import 'recipe_information_screen.dart';
import 'secure_storage.dart';
import 'select_recipe_categories_screen.dart';
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
                    title: const Text('FoodBank Home', style: TextStyle(color: Colors.white)),
                    backgroundColor: Colors.green,
                    centerTitle: true,
                    pinned: true,
                    actions: <Widget>[
                      PopupMenuButton(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        itemBuilder: (context) {
                          return [
                            PopupMenuItem(
                              child: const Text('User Profile'),
                              onTap: () {
                                // Navigate to the user profile screen
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const UserProfileScreen()),
                                ).then((value) => setState(() {
                                  _fetchRecipes();
                                }));
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
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 10),
                  ),
                  SliverList.separated(
                    itemCount: recipes.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(recipes.elementAt(index).name),
                        leading: Image.network(recipes.elementAt(index).imageURL, height: 100.0, width: 100.0), // Align images
                        onTap: () {
                          // Go to screen for selected recipe and pass over the chosen recipe's 'Recipe' instance as well
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => RecipeInformationScreen(recipes.elementAt(index))),
                          );
                        },
                      );
                    },
                    separatorBuilder: (context, index) => Divider(),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 10),
                  ),
                ],
              ),
              floatingActionButton: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Floating Action Button for Adding Recipe
                  FloatingActionButton(
                    backgroundColor: Colors.green,
                    onPressed: () {
                      // Let user add their own recipe to the DB
                      Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AddRecipeScreen(refreshRecipeList: _refreshRecipeList))
                      );
                    },
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                  const SizedBox(
                    height: 30.0,
                  ),
                  // Floating Action Button for Filtering Recipes on Home Screen Based on Category
                  FloatingActionButton(
                    backgroundColor: Colors.green,
                    onPressed: () {
                      // Let user select filters for the available recipe categories
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SelectRecipeCategoriesScreen(refreshRecipeList: _refreshRecipeList)),
                      );
                    },
                    child: const Icon(Icons.filter_list, color: Colors.white),
                  ),
                ],
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
    // Fetch currently logged in user's username
    final currentUsername = await SecureStorage().retrieveLoggedInUser('loggedInUser');
    // Connect to DB to fetch recipes
    final conn = await Connection.open(
        Endpoint(
          host: 'food-bank-database.c72m8ic4gtlt.us-east-1.rds.amazonaws.com',
          database: 'food-bank-database',
          username: 'postgres',
          password: 'Aminifoodbank123',
        )
    );
    // Get all recipe names and image URLs for display (in ascending alphabetical order)
    // (except for those that contain ingredients the user is allergic to - set in the 'User Profile' screen)
    final dynamic recipeFetchResult;
    // Change SQL query to only show recipes that belong to categories the user selected (if applicable)
    final storedSelectedCategories = await SecureStorage().retrieveSelectedRecipeCategories();
    if (storedSelectedCategories.isNotEmpty) {
      // Case: User selected recipe categories
      recipeFetchResult = await conn.execute(
          Sql.named(
              '''
            SELECT * FROM recipe
            WHERE recipe.id NOT IN (
              SELECT recipe_allergy.recipe_id
              FROM recipe_allergy
              WHERE recipe_allergy.allergy IN (
                SELECT user_allergy.allergy
                FROM user_allergy
                WHERE user_allergy.username = @username
              )
            ) AND category = ANY(@categories)
            ORDER BY recipe.name ASC 
            '''
          ),
          parameters: {'username': currentUsername, 'categories': storedSelectedCategories},
      );
    } else {
      // Case: User did not select recipe categories
      recipeFetchResult = await conn.execute(
          Sql.named(
            '''
            SELECT * FROM recipe
            WHERE recipe.id NOT IN (
              SELECT recipe_allergy.recipe_id
              FROM recipe_allergy
              WHERE recipe_allergy.allergy IN (
                SELECT user_allergy.allergy
                FROM user_allergy
                WHERE user_allergy.username = @username
              )
            )
            ORDER BY recipe.name ASC 
            '''
          ),
          parameters: {'username': currentUsername}
      );
    }
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