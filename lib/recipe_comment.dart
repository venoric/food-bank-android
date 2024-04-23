library recipe_comment;

import 'package:intl/intl.dart';

// Comment Class
class RecipeComment {
  // Member Variables
  late int _recipeID;
  late String _posterUsername;
  late String _comment;
  late DateTime _timestamp;
  // Constructors
  RecipeComment(int recipeID, String posterUsername, String comment, DateTime timestamp) {
    _recipeID = recipeID;
    _posterUsername = posterUsername;
    _comment = comment;
    _timestamp = timestamp;
  }
  // Getters
  int get recipeID => _recipeID;
  String get posterUsername => _posterUsername;
  String get comment => _comment;
  DateTime get timestamp => _timestamp; // Just returns the timestamp in original format
  String get timestampFormatted => DateFormat('MMMM d, yyyy @ HH:mm').format(_timestamp); // Returns the timestamp as a String in the specified format meant for displaying to users
}