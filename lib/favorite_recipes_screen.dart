import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:postgres/postgres.dart';

import 'recipe.dart';
import 'recipe_information_screen.dart';
import 'secure_storage.dart';

// Favorite Recipes Screen
class FavoriteRecipesScreen extends StatefulWidget {
  const FavoriteRecipesScreen({super.key});

  @override
  State<FavoriteRecipesScreen> createState() => _FavoriteRecipesScreenState();
}

class _FavoriteRecipesScreenState extends State<FavoriteRecipesScreen> {
  @override
  void initState() {
    setState(() {
      super.initState();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Recipe>> (
        future: _fetchFavoriteRecipes(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            // Case: Something went wrong with fetching favorite recipe data from DB
            return const Center(child: Text('Error: Unable to fetch favorite recipes for current user.'));
          } else if (snapshot.hasData) {
            // Case: Recipe data DB fetching successful
            // Get favorite recipe information from DB
            List<Recipe> favoriteRecipes = snapshot.data!;
            return Scaffold(
                body: CustomScrollView(
                  slivers: <Widget>[
                    SliverAppBar(
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      title: const Text('Favorite Recipes', style: TextStyle(color: Colors.white)),
                      backgroundColor: Colors.green,
                      centerTitle: true,
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 10),
                    ),
                    SliverList.separated(
                      itemCount: favoriteRecipes.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(favoriteRecipes.elementAt(index).name),
                          leading: Image.network(favoriteRecipes.elementAt(index).imageURL, height: 100.0, width: 100.0, fit: BoxFit.cover), // Align images
                          onTap: () {
                            // Go to screen for selected favorite recipe and pass over the chosen recipe's 'Recipe' instance as well
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => RecipeInformationScreen(favoriteRecipes.elementAt(index))),
                            ).then((_) {
                              // Refresh screen in case any recipes get unfavorited
                              setState(() {});
                            });
                          }
                        );
                      },
                      separatorBuilder: (context, index) => Divider(),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 10),
                    ),
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

  // Method to Fetch Favorite Recipes from DB
  Future<List<Recipe>> _fetchFavoriteRecipes() async {
    late List<Recipe> favoriteRecipes = <Recipe>[];
    // Fetch currently logged in user's username
    final currentUsername = await SecureStorage().retrieveLoggedInUser('loggedInUser');
    // Connect to DB to fetch favorite recipes
    final conn = await Connection.open(
        Endpoint(
          host: 'food-bank-database.c72m8ic4gtlt.us-east-1.rds.amazonaws.com',
          database: 'food-bank-database',
          username: 'postgres',
          password: 'Aminifoodbank123',
        )
    );
    // Get all recipe id's that correspond to what recipes the user favorited
    final favoriteRecipesFetchResult = await conn.execute(
      Sql.named('SELECT recipe.* FROM user_favorite JOIN recipe ON recipe_id = recipe.id WHERE user_favorite.username = @username ORDER BY recipe.name ASC '),
      parameters: {'username': currentUsername},
    );
    final favoriteRecipesFetchResultList = favoriteRecipesFetchResult.toList();
    // Close connection to DB
    await conn.close();
    if (favoriteRecipesFetchResultList.isEmpty) {
      // Error Message
      Fluttertoast.showToast(
          msg: 'You don\'t have any favorite recipes.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.grey,
          textColor: Colors.black
      );
      return favoriteRecipes;
    }
    // Extract each recipe's details from the DB call results
    for (var i = 0; i < favoriteRecipesFetchResultList.length; ++i) {
      int recipeID = int.parse(favoriteRecipesFetchResultList.elementAt(i)[0]!.toString());
      String recipeName = favoriteRecipesFetchResultList.elementAt(i)[1]!.toString();
      String recipeIngredients = favoriteRecipesFetchResultList.elementAt(i)[2]!.toString();
      String recipeInstructions = favoriteRecipesFetchResultList.elementAt(i)[3]!.toString();
      String recipeCategory = favoriteRecipesFetchResultList.elementAt(i)[4]!.toString();
      String recipeServings = favoriteRecipesFetchResultList.elementAt(i)[5]!.toString();
      String recipeImageURL = favoriteRecipesFetchResultList.elementAt(i)[6]!.toString();
      String recipePoster = favoriteRecipesFetchResultList.elementAt(i)[7]!.toString();
      favoriteRecipes.add(Recipe(recipeID, recipeName, recipeIngredients, recipeInstructions, recipeCategory, recipeServings, recipeImageURL, recipePoster));
    }
    return favoriteRecipes;
  }
}