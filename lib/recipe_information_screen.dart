import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:postgres/postgres.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:youtube_data_api/models/video.dart';
import 'package:youtube_data_api/youtube_data_api.dart';
import 'package:url_launcher/url_launcher.dart';

import 'recipe.dart';
import 'recipe_comments_screen.dart';
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

  final YoutubeDataApi youtubeDataApi = new YoutubeDataApi();
  final String apiKey = '';

  late double _rating;
  late double _averageRating;
  final int _starCount = 5;
  List<Video> _relatedVideos = [];
  late bool _isFavorite;

  bool _ratingLoaded = false;
  bool _averageRatingLoaded = false;
  bool _currentFavoriteStatusLoaded = false;

  @override
  void initState() {
    super.initState();
    // Fetch rating value for current recipe (if applicable)
    _fetchRating();
    // Fetch average rating value for current recipe
    _fetchAverageRating();
    // Fetch three YouTube videos that are related to current recipe
    _fetchRecipeVideos('${widget._currentRecipe.name} recipe');
    // Fetch favorite status for current user and current recipe
    _fetchFavoriteStatus();
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
            return (_ratingLoaded && _averageRatingLoaded && _currentFavoriteStatusLoaded) ? Scaffold(
              key: _formKey,
              appBar: AppBar(
                actions: [
                  IconButton(
                    icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
                    onPressed: _setNewFavoriteStatus,
                  )
                ],
              ),
              body: CustomScrollView(
                slivers: <Widget>[
                  SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          // Actual Recipe Information Section
                          children: [
                            // Display recipe name
                            Text(widget._currentRecipe.poster != 'N/A' ? ('${widget._currentRecipe.name} by ${widget._currentRecipe.poster}') : (widget._currentRecipe.name),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 30.0,
                                )
                            ),
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
                            const SizedBox(height: 10),
                            Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(10),  // Set the background color to grey
                                ),
                                padding: EdgeInsets.all(8.0), // Add some padding around the text
                                child: Text('* ${widget._currentRecipe.ingredients.replaceAll(r'\r\n', '\n* ').replaceAll(';', '')}'),  // Remove semi-colons, and add asterisks as bullet points
                            ),
                            const SizedBox(height: 10),
                            // Display instructions
                            const Text('Instructions', style: TextStyle(decoration: TextDecoration.underline)),
                            const SizedBox(height: 10),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(10),  // Set the background color to grey
                              ),
                              padding: EdgeInsets.all(8.0), // Add some padding around the text
                              child: Text('* ${widget._currentRecipe.instructions.replaceAll(r'\r\n', '\n* ').replaceAll(';', '')}'),  // Remove semi-colons, and add asterisks as bullet points
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      )
                  ),
                  // Related YouTube Videos Section
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        Text(suggestedRecipes.isEmpty ? '' : 'Related YouTube Videos', style: const TextStyle(decoration: TextDecoration.underline)),  // Remove semi-colons, and add asterisks as bullet points
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                  SliverList.separated(
                    itemCount: _relatedVideos.length,
                    itemBuilder: (context, index) {
                      return Column(
                        children: [
                          ListTile(
                            title: Text(_relatedVideos.elementAt(index).title as String),
                            leading: Image.network(_relatedVideos.elementAt(index).thumbnails?.elementAt(0).url as String),
                            onTap: () {
                              // Open link to related YouTube video
                              launchUrl(Uri.parse('https://www.youtube.com/watch?v=${_relatedVideos.elementAt(index).videoId}'));
                            },
                          ),
                          const SizedBox(height: 10),
                        ],
                      );
                    },
                    separatorBuilder: (context, index) => Divider(),
                  ),
                  // Suggested Recipes Section (Based on Current Recipe Category)
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        Text(suggestedRecipes.isEmpty ? '' : 'Suggested Recipes', style: const TextStyle(decoration: TextDecoration.underline)),  // Remove semi-colons, and add asterisks as bullet points
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                  SliverList.separated(
                    itemCount: suggestedRecipes.length,
                    itemBuilder: (context, index) {
                      return Column(
                        children: [
                          ListTile(
                            title: Text(suggestedRecipes.elementAt(index).name),
                            leading: Image.network(suggestedRecipes.elementAt(index).imageURL, height: 100.0, width: 100.0, fit: BoxFit.cover),
                            onTap: () {
                              // Go to screen for suggested recipe and pass over the chosen recipe's 'Recipe' instance as well
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => RecipeInformationScreen(suggestedRecipes.elementAt(index))),
                              );
                            },
                          ),
                          const SizedBox(height: 10),
                        ],
                      );
                    },
                    separatorBuilder: (context, index) => Divider(),
                  ),
                  // Rating Bar, Average Rating, and Comments Section
                  SliverToBoxAdapter(
                    child: Center(
                      child: Column(
                        children: [
                          // Display rating bar
                          Column(
                            children: [
                              const Text('Your Rating', style: TextStyle(decoration: TextDecoration.underline)),
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
                          const SizedBox(height: 10),
                          // Display average rating for current recipe
                          Text('(Average Rating: ${_averageRating.toStringAsFixed(2)}/${_starCount.toDouble()})'),
                          const SizedBox(height: 10),
                          // Button That Leads to Current Recipe's Comment Section
                          ElevatedButton(
                            onPressed: () {
                              // Navigate to current recipe's comment section
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => RecipeCommentsScreen(currentRecipeID: widget._currentRecipe.recipeID)),
                              );
                            },
                            child: const Text('Go to Comments'),
                          ),
                          const SizedBox(height: 10),
                        ],
                      )
                    ),
                  ),
                ],
              ),
            ) : Container(
              color: Colors.white,
              child: const Center(
                  child: CircularProgressIndicator()
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
    // Fetch currently logged in user's username
    final currentUsername = await SecureStorage().retrieveLoggedInUser('loggedInUser');
    // Connect to DB to fetch suggested recipes
    final conn = await Connection.open(
        Endpoint(
          host: 'food-bank-database.c72m8ic4gtlt.us-east-1.rds.amazonaws.com',
          database: 'food-bank-database',
          username: 'postgres',
          password: 'Aminifoodbank123',
        )
    );
    // Get all recipes under the same category (except for those that contain ingredients the user is allergic to - set in the 'User Profile' screen)
    final fetchSuggestedRecipes = await conn.execute(
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
          ) AND category = @category
          '''
      ),
      parameters: {'username': currentUsername, 'category': widget._currentRecipe.category}
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
    // Now, variable for rating for current recipe by current user has been set
    setState(() {
      _ratingLoaded = true;
    });
  }

  // Method to Get Average Rating Value
  Future<void> _fetchAverageRating() async {
    // Connect to DB to fetch average rating value for current recipe
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
      Sql.named('SELECT AVG(rating) AS average_rating FROM recipe_rating WHERE recipe_id = @reviewID'),
      parameters: {'reviewID': widget._currentRecipe.recipeID},
    );
    final fetchRatingForCurrentRecipeList = fetchRatingForCurrentRecipe.toList();
    // Set local average rating value
    if (fetchRatingForCurrentRecipeList.isNotEmpty && fetchRatingForCurrentRecipeList[0][0].runtimeType != Null) {
      _averageRating = fetchRatingForCurrentRecipeList[0][0] as double;
    } else {
      _averageRating = 0.0;
    }
    // Close connection to DB
    await conn.close();
    // Now, variable for average rating has been set
    setState(() {
      _averageRatingLoaded = true;
    });
  }

  // Method to Get Three Videos Related to the Current Recipe
  void _fetchRecipeVideos(String query) async {
    List results = await youtubeDataApi.fetchSearchVideo(query, apiKey);
    // Only get three videos
    int videoCounter = 0;
    for (var i = 0; i < results.length && videoCounter < 3; ++i) {
      // Only grab videos
      if (results.elementAt(i) is Video) {
        // Add video to '_relatedVideos'
        _relatedVideos.add(results.elementAt(i));
        // Increment 'videoCounter'
        videoCounter++;
      }
    }
  }

  // Method to Get Favorite Status from DB
  void _fetchFavoriteStatus() async {
    // Connect to DB to fetch favorite status from DB for current user and current recipe
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
    // Check DB to see if current user has favorited current recipe
    final fetchFavoriteStatusDBResult = await conn.execute(
      Sql.named('SELECT * FROM user_favorite WHERE username = @username AND recipe_id = @recipeID'),
      parameters: {'username': currentUsername, 'recipeID': widget._currentRecipe.recipeID}
    );
    final fetchFavoriteStatusDBResultList = fetchFavoriteStatusDBResult.toList();
    if (fetchFavoriteStatusDBResultList.isNotEmpty) {
      // Case: User favorited current recipe previously
      _isFavorite = true;
    } else {
      // Case: User did not favorite current recipe previously
      _isFavorite = false;
    }
    // Set '_currentFavoriteStatusLoaded' to true
    _currentFavoriteStatusLoaded = true;
    // Close connection to DB
    await conn.close();
  }

  // Method to Set New Favorite Status
  void _setNewFavoriteStatus() async {
    // Get new current favorite status using '_isFavorite'
    final newFavoriteStatus = !_isFavorite;
    // Connect to DB to set new favorite status in DB for current user and current recipe
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
    // Add new DB table entry for 'user_favorite' table or remove existing entry depending on _isFavorite
    if (_isFavorite) {
      // Case: DB entry exists in DB
      // Delete table entry
      await conn.execute(
          Sql.named('DELETE FROM user_favorite WHERE username = @username AND recipe_id = @recipeID'),
          parameters: {'username': currentUsername, 'recipeID': widget._currentRecipe.recipeID}
      );
      // Check if entry has been successfully deleted
      final checkForFavoriteStatusDBResult = await conn.execute(
        Sql.named('SELECT * FROM user_favorite WHERE username = @username AND recipe_id = @recipeID'),
        parameters: {'username': currentUsername, 'recipeID': widget._currentRecipe.recipeID}
      );
      final checkForFavoriteStatusDBResultList = checkForFavoriteStatusDBResult.toList();
      if (checkForFavoriteStatusDBResultList.isEmpty) {
        Fluttertoast.showToast(
            msg: 'Successfully unfavorited recipe!',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.grey,
            textColor: Colors.black
        );
      } else {
        Fluttertoast.showToast(
            msg: 'Error: Could not unfavorite current recipe!',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.grey,
            textColor: Colors.black
        );
      }
    } else {
      // Case: DB entry does not in DB yet
      // Add new table entry in DB
      await conn.execute(
          Sql.named('INSERT INTO user_favorite VALUES (@username, @recipeID)'),
          parameters: {'username': currentUsername, 'recipeID': widget._currentRecipe.recipeID}
      );
      // Check if table entry was successfully added to DB
      final checkForFavoriteStatusDBResult = await conn.execute(
          Sql.named('SELECT * FROM user_favorite WHERE username = @username AND recipe_id = @recipeID'),
          parameters: {'username': currentUsername, 'recipeID': widget._currentRecipe.recipeID}
      );
      final checkForFavoriteStatusDBResultList = checkForFavoriteStatusDBResult.toList();
      if (checkForFavoriteStatusDBResultList.isNotEmpty) {
        Fluttertoast.showToast(
            msg: 'Successfully favorited recipe!',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.grey,
            textColor: Colors.black
        );
      } else {
        Fluttertoast.showToast(
            msg: 'Error: Could not favorite current recipe!',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.grey,
            textColor: Colors.black
        );
      }
    }
    // Close connection to DB
    await conn.close();
    // Update local variable '_isFavorite'
    _isFavorite = newFavoriteStatus;
    // Refresh screen
    setState(() {});
  }
}