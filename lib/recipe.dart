library recipe;

// Recipe Class
class Recipe {
  // Member Variables
  late int _recipeID;
  late String _name;
  late String _ingredients;
  late String _instructions;
  late String _category;
  late String _servings;
  late String _imageURL;
  late String _poster;
  // Constructor
  Recipe(int recipeID, String recipeName, String recipeIngredients, String recipeInstructions, String recipeCategory, String recipeServings, String recipeImageURL, String poster) {
    _recipeID = recipeID;
    _name = recipeName;
    _ingredients = recipeIngredients;
    _instructions = recipeInstructions;
    _category = recipeCategory;
    _servings = recipeServings;
    _imageURL = recipeImageURL;
    _poster = poster;
  }
  // Getters
  int get recipeID => _recipeID;
  String get name => _name;
  String get ingredients => _ingredients;
  String get instructions => _instructions;
  String get category => _category;
  String get servings => _servings;
  String get imageURL => _imageURL;
  String get poster => _poster;
}