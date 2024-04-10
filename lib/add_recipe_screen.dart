import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:postgres/postgres.dart';

import 'secure_storage.dart';

// Add Own Recipe Screen
class AddRecipeScreen extends StatefulWidget {
  final Function() refreshRecipeList;

  const AddRecipeScreen({super.key, required this.refreshRecipeList});

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _recipeName, _recipeCategory, _recipeIngredients, _recipeInstructions;
  late int _recipeNumberServings;
  // Temporary Image URL for User-Submitted Recipes
  // Attribution:
  // - RossPlaysAC, CC BY-SA 4.0 <https://creativecommons.org/licenses/by-sa/4.0>, via Wikimedia Commons
  final String _recipeImageURL = 'https://upload.wikimedia.org/wikipedia/commons/3/3b/PlaceholderRoss.png';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Recipe')),
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
                    labelText: 'Recipe Name',
                  ),
                  validator: (inputtedRecipeName) {
                    if (inputtedRecipeName == null || inputtedRecipeName.isEmpty) {
                      return 'Please enter a recipe name';
                    }
                    // Set _recipeName for later use (DB query)
                    _recipeName = inputtedRecipeName;
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
                    labelText: 'Category',
                  ),
                  validator: (inputtedCategory) {
                    if (inputtedCategory == null || inputtedCategory.isEmpty) {
                      return 'Please enter a category for this recipe';
                    }
                    // Set _recipeCategory for later use (DB query)
                    _recipeCategory = inputtedCategory;
                    return null;
                  },
                ),
              ),
              const SizedBox(
                height: 30.0,
              ),
              SizedBox(
                width: 300.0,
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Servings',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (inputtedServings) {
                    if (inputtedServings == null || inputtedServings.isEmpty) {
                      return 'Please enter the number of servings for this recipe';
                    }
                    // Set _recipeCategory for later use (DB query)
                    _recipeNumberServings = int.parse(inputtedServings);
                    return null;
                  },
                ),
              ),
              const SizedBox(
                height: 30.0,
              ),
              SizedBox(
                width: 300.0,
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Ingredients',
                  ),
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  validator: (inputtedIngredients) {
                    if (inputtedIngredients == null || inputtedIngredients.isEmpty) {
                      return 'Please enter the ingredients for this recipe';
                    }
                    // Set _recipeIngredients for later use (DB query)
                    _recipeIngredients = inputtedIngredients;
                    return null;
                  },
                ),
              ),
              const SizedBox(
                height: 30.0,
              ),
              SizedBox(
                width: 300.0,
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Instructions',
                  ),
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  validator: (inputtedInstructions) {
                    if (inputtedInstructions == null || inputtedInstructions.isEmpty) {
                      return 'Please enter the instructions for this recipe';
                    }
                    // Set _recipeInstructions for later use (DB query)
                    _recipeInstructions = inputtedInstructions;
                    return null;
                  },
                ),
              ),
              const SizedBox(
                height: 30.0,
              ),
              // NOTE: Still need to implement UI elements for an image picker
              ElevatedButton(
                child: const Text('Submit Recipe'),
                onPressed: () async {
                  // Validate and submit recipe form
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
                    // Determine 'id' for current recipe
                    final getRecipesResult = await conn.execute('SELECT id FROM recipe');
                    final getRecipesResultList = getRecipesResult.toList();
                    final int idToSet = int.parse(getRecipesResultList.elementAt(getRecipesResultList.length - 1)[0]!.toString()) + 1;
                    // Submit recipe under current user
                    final currentUsername = await SecureStorage().retrieveLoggedInUser('loggedInUser');
                    final addRecipeCurrentUserResult = await conn.execute(
                      Sql.named('INSERT INTO recipe VALUES (@id, @recipe_name, @recipe_ingredients, @recipe_instructions, @recipe_category, @recipe_servings, @image_url, @poster)'),
                      parameters: {'id': idToSet, 'recipe_name': _recipeName, 'recipe_ingredients': _recipeIngredients, 'recipe_instructions': _recipeInstructions, 'recipe_category': _recipeCategory, 'recipe_servings': _recipeNumberServings, 'image_url': _recipeImageURL, 'poster': currentUsername},
                    );
                    // Refresh recipe list
                    widget.refreshRecipeList();
                    // Exit to main menu
                    Navigator.pop(context);
                  } else {
                    // Display message
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Error: Could not submit recipe.'))
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