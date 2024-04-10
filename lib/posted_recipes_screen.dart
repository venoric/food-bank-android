import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:postgres/postgres.dart';

import 'recipe.dart';
import 'recipe_information.dart';
import 'secure_storage.dart';

// Posted Recipes Screen
class PostedRecipesScreen extends StatefulWidget {
  final Function() refreshRecipeList;

  const PostedRecipesScreen({super.key, required this.refreshRecipeList});

  @override
  State<PostedRecipesScreen> createState() => _PostedRecipesScreenState();
}

class _PostedRecipesScreenState extends State<PostedRecipesScreen> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Recipe>> (
        future: _fetchPostedRecipes(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            // Case: Something went wrong with fetching posted recipe data from DB
            return const Center(child: Text('Error: Unable to fetch posted recipes for current user.'));
          } else if (snapshot.hasData) {
            // Case: Recipe data DB fetching successful
            // Get posted recipe information from DB
            List<Recipe> postedRecipes = snapshot.data!;
            return Scaffold(
                body: CustomScrollView(
                  slivers: <Widget>[
                    const SliverAppBar(
                      title: Text('Posted Recipes'),
                    ),
                    SliverList.separated(
                      itemCount: postedRecipes.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(postedRecipes.elementAt(index).name),
                          leading: Image.network(postedRecipes.elementAt(index).imageURL),
                          onTap: () {
                            // Go to screen for selected posted recipe and pass over the chosen recipe's Recipe instance as well
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => RecipeInformationScreen(postedRecipes.elementAt(index))),
                            );
                          },
                          trailing: GestureDetector(
                            onTap: () async {
                              // Remove posted recipe from DB for current user
                              final conn = await Connection.open(
                                  Endpoint(
                                    host: 'food-bank-database.c72m8ic4gtlt.us-east-1.rds.amazonaws.com',
                                    database: 'food-bank-database',
                                    username: 'postgres',
                                    password: 'Aminifoodbank123',
                                  )
                              );
                              // Remove posted recipe from other users' lists of favorite recipes
                              final removeFavoriteRecipeFromFavoritesTableResult = await conn.execute(
                                Sql.named('DELETE FROM user_favorite WHERE recipe_id = @recipe_id'),
                                parameters: {'recipe_id': postedRecipes.elementAt(index).recipeID},
                              );
                              // Fetch currently logged in user's username
                              final currentUsername = await SecureStorage().retrieveLoggedInUser('loggedInUser');
                              final removeFavoriteRecipeFromRecipeTableResult = await conn.execute(
                                Sql.named('DELETE FROM recipe WHERE poster = @username AND id = @recipe_id'),
                                parameters: {'username': currentUsername, 'recipe_id': postedRecipes.elementAt(index).recipeID},
                              );
                              // Remove posted recipe from local list
                              postedRecipes.removeAt(index);
                              // Refresh main screen's recipe list
                              widget.refreshRecipeList();
                              // Refresh state
                              setState(() {});
                            },
                            child: Icon(Icons.delete),
                          ),
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

  // Method to Fetch Posted Recipes from DB
  Future<List<Recipe>> _fetchPostedRecipes() async {
    late List<Recipe> postedRecipes = <Recipe>[];
    // Fetch currently logged in user's username
    final currentUsername = await SecureStorage().retrieveLoggedInUser('loggedInUser');
    // Connect to DB to fetch a user's posted recipes
    final conn = await Connection.open(
        Endpoint(
          host: 'food-bank-database.c72m8ic4gtlt.us-east-1.rds.amazonaws.com',
          database: 'food-bank-database',
          username: 'postgres',
          password: 'Aminifoodbank123',
        )
    );
    // Get all recipe names and image URLs for display
    final recipeFetchResult = await conn.execute(
      Sql.named('SELECT * FROM recipe WHERE poster = @poster ORDER BY id ASC'),
      parameters: {'poster': currentUsername},
    );
    final recipeFetchResultList = recipeFetchResult.toList();
    if (recipeFetchResultList.isEmpty) {
      // Error Message
      Fluttertoast.showToast(
          msg: 'You have not posted any recipes.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.grey,
          textColor: Colors.black
      );
      return postedRecipes;
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
      postedRecipes.add(Recipe(recipeID, recipeName, recipeIngredients, recipeInstructions, recipeCategory, recipeServings, recipeImageURL, recipePoster));
    }
    return postedRecipes;
  }
}