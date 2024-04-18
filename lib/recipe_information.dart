import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:postgres/postgres.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import 'recipe.dart';
import 'secure_storage.dart';

// Recipe Information Screen
class RecipeInformationScreen extends StatefulWidget {
  late final Recipe _currentRecipe;

  RecipeInformationScreen(Recipe recipe, {super.key}) {
    _currentRecipe = recipe;
  }

  @override
  State<RecipeInformationScreen> createState() => _RecipeInformationScreenState();
}

class _RecipeInformationScreenState extends State<RecipeInformationScreen> {
  final _formKey = GlobalKey<FormState>();

  late double _rating;
  final int _starCount = 5;

  bool _ratingLoaded = false;

  @override
  void initState() {
    super.initState();
    // Fetch star rating for current recipe (if applicable)
    _fetchRating();
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
              key: _formKey,
              appBar: AppBar(),
              body: _ratingLoaded ? CustomScrollView(
                slivers: <Widget>[
                  SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          // Actual Recipe Information Section
                          children: [
                            // Display recipe name
                            const Text('Recipe', style: TextStyle(decoration: TextDecoration.underline)),
                            Text(widget._currentRecipe.poster != 'N/A' ? ('${widget._currentRecipe.name} by ${widget._currentRecipe.poster}') : ('${widget._currentRecipe.name}')),
                            const SizedBox(height: 10),
                            // Display category
                            const Text('Category', style: TextStyle(decoration: TextDecoration.underline)),
                            Text(widget._currentRecipe.category),
                            const SizedBox(height: 10),
                            // Display servings
                            const Text('Servings', style: TextStyle(decoration: TextDecoration.underline)),
                            Text(widget._currentRecipe.servings),
                            const SizedBox(height: 10),
                            // Display recipe image
                            Image.network(widget._currentRecipe.imageURL),
                            const SizedBox(height: 10),
                            // Display ingredient list
                            const Text('Ingredients', style: TextStyle(decoration: TextDecoration.underline)),
                            Text('* ${widget._currentRecipe.ingredients.replaceAll(r'\r\n', '\n* ').replaceAll(';', '')}'),  // Remove semi-colons, and add asterisks as bullet points
                            const SizedBox(height: 10),
                            // Display instructions
                            const Text('Instructions', style: TextStyle(decoration: TextDecoration.underline)),
                            Text('* ${widget._currentRecipe.instructions.replaceAll(r'\r\n', '\n* ').replaceAll(';', '')}'),  // Remove semi-colons, and add asterisks as bullet points
                            const SizedBox(height: 10),
                            // Display Three Suggested Recipes Based on Category
                            Text(suggestedRecipes.isEmpty ? '' : 'Suggested Recipes', style: TextStyle(decoration: TextDecoration.underline)),  // Remove semi-colons, and add asterisks as bullet points
                            const SizedBox(height: 10),
                          ],
                        ),
                      )
                  ),
                  // Suggested Recipes Section (Based on Current Recipe Category)
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
                  ),
                  // Star-Based Review Section
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const Text('Your Rating for This Recipe', style: TextStyle(decoration: TextDecoration.underline)),
                        const SizedBox(height: 10),
                        Center(
                            child: RatingBar.builder(
                              initialRating: _rating,
                              itemCount: _starCount,
                              allowHalfRating: true,
                              itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                              itemBuilder: (context, _) => const Icon(
                                Icons.star,
                                color: Colors.amber,
                              ),
                              onRatingUpdate: (rating) async {
                                // Don't update the DB if the same rating is given to the current recipe
                                if (rating == _rating) {
                                  return;
                                }
                                // Connect to DB to set rating value in DB
                                final conn = await Connection.open(
                                    Endpoint(
                                      host: 'food-bank-database.c72m8ic4gtlt.us-east-1.rds.amazonaws.com',
                                      database: 'food-bank-database',
                                      username: 'postgres',
                                      password: 'Aminifoodbank123',
                                    )
                                );
                                // Fetch currently logged in user's username
                                final currentUsername = await SecureStorage().retrieveLoggedInUser('loggedInUser');
                                // First check to see if the user already has a rating for the current recipe
                                final getRatingForCurrentRecipe = await conn.execute(
                                  Sql.named('SELECT * FROM recipe_rating WHERE recipe_id = @recipeID AND username = @username'),
                                  parameters: {'recipeID': widget._currentRecipe.recipeID, 'username': currentUsername},
                                );
                                final getRatingForCurrentRecipeList = getRatingForCurrentRecipe.toList();
                                if (getRatingForCurrentRecipeList.isEmpty) {
                                  // Case: Current user has not rated the current recipe yet
                                  // Now, add the recipe rating in the DB
                                  final addRatingForCurrentRecipe = await conn.execute(
                                      Sql.named('INSERT INTO recipe_rating VALUES (@recipeID, @username, @rating)'),
                                      parameters: {'recipeID': widget._currentRecipe.recipeID, 'username': currentUsername, 'rating': rating}
                                  );
                                } else {
                                  // Case: Current user previously rated the current recipe
                                  // Now, update rating to the DB again with new rating
                                  final updateRatingForCurrentRecipe = await conn.execute(
                                      Sql.named('UPDATE recipe_rating SET rating = @rating WHERE recipe_id = @recipeID AND username = @username'),
                                      parameters: {'recipeID': widget._currentRecipe.recipeID, 'username': currentUsername, 'rating': rating}
                                  );
                                }
                                // Check once more if DB table add/update was successful
                                final getRatingForCurrentRecipeAgain = await conn.execute(
                                  Sql.named('SELECT * FROM recipe_rating WHERE recipe_id = @recipeID AND username = @username'),
                                  parameters: {'recipeID': widget._currentRecipe.recipeID, 'username': currentUsername},
                                );
                                final getRatingForCurrentRecipeAgainList = getRatingForCurrentRecipeAgain.toList();
                                // Close connection to DB
                                await conn.close();
                                // Display toast message depending on result of rating attempt
                                if (getRatingForCurrentRecipeAgainList.length == 1) {
                                  // Case: Successful Rating
                                  Fluttertoast.showToast(
                                      msg: 'Rated the current recipe successfully with a $rating/${_starCount.toDouble()}!',
                                      toastLength: Toast.LENGTH_SHORT,
                                      gravity: ToastGravity.BOTTOM,
                                      timeInSecForIosWeb: 1,
                                      backgroundColor: Colors.grey,
                                      textColor: Colors.black
                                  );
                                } else {
                                  // Case: Unsuccessful Rating
                                  Fluttertoast.showToast(
                                      msg: 'Could not rate the current recipe.',
                                      toastLength: Toast.LENGTH_SHORT,
                                      gravity: ToastGravity.BOTTOM,
                                      timeInSecForIosWeb: 1,
                                      backgroundColor: Colors.grey,
                                      textColor: Colors.black
                                  );
                                }
                                // Set local rating value
                                setState(() {
                                  _rating = rating;
                                });
                              },
                            )
                        )
                      ],
                    ),
                  )
                  // Comment Section
                ],
              ) : Container(
                color: Colors.white,
                child: const Center(
                    child: CircularProgressIndicator()
                ),
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
      parameters: {'category': widget._currentRecipe.category},
    );
    final fetchSuggestedRecipesList = fetchSuggestedRecipes.toList();
    // Close connection to DB
    await conn.close();
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
      if (suggestedRecipes.elementAt(i).recipeID == widget._currentRecipe.recipeID) {
        indexOfCurrentRecipe = i;
      }
    }
    suggestedRecipes.removeAt(indexOfCurrentRecipe);
    // Randomly select three recipes from the above list
    List<Recipe> threeSuggestedRecipes = suggestedRecipes.sample(3);
    return threeSuggestedRecipes;
  }

  // Method to Get Pre-Existing Rating Value (If Applicable)
  Future<void> _fetchRating() async {
    // Fetch currently logged in user's username
    final currentUsername = await SecureStorage().retrieveLoggedInUser('loggedInUser');
    // Connect to DB to fetch rating for current recipe by current user (if any)
    final conn = await Connection.open(
        Endpoint(
          host: 'food-bank-database.c72m8ic4gtlt.us-east-1.rds.amazonaws.com',
          database: 'food-bank-database',
          username: 'postgres',
          password: 'Aminifoodbank123',
        )
    );
    // Get recipe rating
    final fetchRatingForCurrentRecipe = await conn.execute(
      Sql.named('SELECT rating FROM recipe_rating WHERE recipe_id = @reviewID AND username = @username'),
      parameters: {'reviewID': widget._currentRecipe.recipeID, 'username': currentUsername},
    );
    final fetchRatingForCurrentRecipeList = fetchRatingForCurrentRecipe.toList();
    // Set local rating value
    if (fetchRatingForCurrentRecipeList.isNotEmpty) {
      _rating = fetchRatingForCurrentRecipeList[0][0] as double;
    } else {
      _rating = 0.0;
    }
    // Close connection to DB
    await conn.close();
    setState(() {
      _ratingLoaded = true;
    });
  }
}