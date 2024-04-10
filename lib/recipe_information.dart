import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:postgres/postgres.dart';

import 'recipe.dart';

// Recipe Information Screen
class RecipeInformationScreen extends StatelessWidget {
  late final Recipe _currentRecipe;

  RecipeInformationScreen(Recipe recipe, {super.key}) {
    this._currentRecipe = recipe;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Recipe>> (
        future: _fetchSuggestedRecipes(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            // Case: Something went wrong with fetching suggested recipe data from DB
            return const Center(child: Text('Error: Unable to fetch suggested recipes.'));
          } else if (snapshot.hasData) {
            // Case: Recipe data DB fetching successful
            // Get suggested recipes from DB
            List<Recipe> suggestedRecipes = snapshot.data!;
            return Scaffold(
              appBar: AppBar(),
              body: CustomScrollView(
                slivers: <Widget>[
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          // Display recipe name
                          const Text('Recipe', style: TextStyle(decoration: TextDecoration.underline)),
                          Text(_currentRecipe.poster != 'N/A' ? ('${_currentRecipe.name} by ${_currentRecipe.poster}') : ('${_currentRecipe.name}')),
                          const SizedBox(height: 10),
                          // Display category
                          const Text('Category', style: TextStyle(decoration: TextDecoration.underline)),
                          Text(_currentRecipe.category),
                          const SizedBox(height: 10),
                          // Display servings
                          const Text('Servings', style: TextStyle(decoration: TextDecoration.underline)),
                          Text(_currentRecipe.servings),
                          const SizedBox(height: 10),
                          // Display recipe image
                          Image.network(_currentRecipe.imageURL),
                          const SizedBox(height: 10),
                          // Display ingredient list
                          const Text('Ingredients', style: TextStyle(decoration: TextDecoration.underline)),
                          Text('* ${_currentRecipe.ingredients.replaceAll(r'\r\n', '\n* ').replaceAll(';', '')}'),  // Remove semi-colons, and add asterisks as bullet points
                          const SizedBox(height: 10),
                          // Display instructions
                          const Text('Instructions', style: TextStyle(decoration: TextDecoration.underline)),
                          Text('* ${_currentRecipe.instructions.replaceAll(r'\r\n', '\n* ').replaceAll(';', '')}'),  // Remove semi-colons, and add asterisks as bullet points
                          const SizedBox(height: 10),
                          // Display Three Suggested Recipes Based on Category
                          const Text('Suggested Recipes', style: TextStyle(decoration: TextDecoration.underline)),  // Remove semi-colons, and add asterisks as bullet points
                          const SizedBox(height: 10),
                        ],
                      ),
                    )
                  ),
                  SliverList.separated(
                    itemCount: suggestedRecipes.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(suggestedRecipes.elementAt(index).name),
                        leading: Image.network(suggestedRecipes.elementAt(index).imageURL),
                        onTap: () {
                          // Go to screen for suggested recipe and pass over the chosen recipe's Recipe instance as well
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => RecipeInformationScreen(suggestedRecipes.elementAt(index))),
                          );
                        },
                      );
                    },
                    separatorBuilder: (context, index) => Divider(),
                  )
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

  // Method to Fetch Three Suggested Recipes
  Future<List<Recipe>> _fetchSuggestedRecipes() async {
    late List<Recipe> suggestedRecipes = <Recipe>[];
    // Connect to DB to fetch suggested recipes
    final conn = await Connection.open(
        Endpoint(
          host: 'food-bank-database.c72m8ic4gtlt.us-east-1.rds.amazonaws.com',
          database: 'food-bank-database',
          username: 'postgres',
          password: 'Aminifoodbank123',
        )
    );
    // Get all recipes under the same category
    final fetchSuggestedRecipes = await conn.execute(
      Sql.named('SELECT * FROM recipe WHERE category = @category'),
      parameters: {'category': _currentRecipe.category},
    );
    final fetchSuggestedRecipesList = fetchSuggestedRecipes.toList();
    if (fetchSuggestedRecipesList.isEmpty) {
      // Error Message
      Fluttertoast.showToast(
          msg: 'No other recipes with the same category could be found.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.grey,
          textColor: Colors.black
      );
      return suggestedRecipes;
    }
    // Extract each recipe's details from the DB call results
    for (var i = 0; i < fetchSuggestedRecipesList.length; ++i) {
      int recipeID = int.parse(fetchSuggestedRecipesList.elementAt(i)[0]!.toString());
      String recipeName = fetchSuggestedRecipesList.elementAt(i)[1]!.toString();
      String recipeIngredients = fetchSuggestedRecipesList.elementAt(i)[2]!.toString();
      String recipeInstructions = fetchSuggestedRecipesList.elementAt(i)[3]!.toString();
      String recipeCategory = fetchSuggestedRecipesList.elementAt(i)[4]!.toString();
      String recipeServings = fetchSuggestedRecipesList.elementAt(i)[5]!.toString();
      String recipeImageURL = fetchSuggestedRecipesList.elementAt(i)[6]!.toString();
      String recipePoster = fetchSuggestedRecipesList.elementAt(i)[7]!.toString();
      suggestedRecipes.add(Recipe(recipeID, recipeName, recipeIngredients, recipeInstructions, recipeCategory, recipeServings, recipeImageURL, recipePoster));
    }
    // Remove current recipe from list
    int indexOfCurrentRecipe = -1;
    for (var i = 0; i < suggestedRecipes.length; ++i) {
      if (suggestedRecipes.elementAt(i).recipeID == _currentRecipe.recipeID) {
        indexOfCurrentRecipe = i;
      }
    }
    suggestedRecipes.removeAt(indexOfCurrentRecipe);
    // Randomly select three recipes from the above list
    List<Recipe> threeSuggestedRecipes = suggestedRecipes.sample(3);
    return threeSuggestedRecipes;
  }
}