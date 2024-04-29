import 'package:comment_box/comment/comment.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:postgres/postgres.dart';

import 'recipe_comment.dart';
import 'secure_storage.dart';

// Recipe Comments Screen
class RecipeCommentsScreen extends StatefulWidget {
  final int currentRecipeID;

  RecipeCommentsScreen({
    super.key,
    required this.currentRecipeID,
  });

  @override
  State<RecipeCommentsScreen> createState() => _RecipeCommentsScreenState();
}

class _RecipeCommentsScreenState extends State<RecipeCommentsScreen> {
  final formKey = GlobalKey<FormState>();
  final TextEditingController commentController = TextEditingController();

  // Widget for Displaying Comments
  Widget commentChild(List<RecipeComment> commentData) {
    return ListView(
      children: [
        for (var i = 0; i < commentData.length; i++)
          Padding(
            padding: const EdgeInsets.fromLTRB(2.0, 8.0, 2.0, 0.0),
            child: ListTile(
              title: Text(
                commentData.elementAt(i).posterUsername,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(commentData.elementAt(i).comment),
              trailing: Text(commentData.elementAt(i).timestampFormatted, style: const TextStyle(fontSize: 10)),
            ),
          )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<RecipeComment>>(
      future: _fetchAllCommentsCurrentRecipe(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          // Case: Something went wrong with fetching suggested recipe data from DB
          return const Center(child: Text('Error: Unable to fetch comments for current recipe.'));
        } else if (snapshot.hasData) {
          // Case: Recipe comment fetching successful
          // Get comments for current recipe from DB
          List<RecipeComment> commentsCurrentRecipe = snapshot.data!;
          return Scaffold(
            appBar: AppBar(),
            body: CommentBox(
              child: commentChild(commentsCurrentRecipe),
              labelText: 'Write a comment...',
              errorText: 'Comment cannot be blank',
              withBorder: false,
              sendButtonMethod: () async {
                if (formKey.currentState!.validate()) {
                  // Fetch currently logged in user's username
                  final currentUsername = await SecureStorage().retrieveLoggedInUser('loggedInUser');
                  // Add comment to local list and DB
                  // Construct new RecipeComment object with current recipe's ID, current user's username, comment, and timestamp
                  RecipeComment newComment = RecipeComment(widget.currentRecipeID, currentUsername, commentController.text, DateTime.now());
                  // Add to local list for current recipe's comments
                  commentsCurrentRecipe.add(newComment);
                  // Connect to DB to add new comment for current recipe
                  _addCommentCurrentRecipeToDB(newComment);
                  commentController.clear();
                  FocusScope.of(context).unfocus();
                }
              },
              formKey: formKey,
              commentController: commentController,
              backgroundColor: Colors.green,
              textColor: Colors.white,
              sendWidget: Icon(Icons.send_sharp, size: 30, color: Colors.white),
            ),
          );
        } else {
          // Case: Recipe Comment Data Still Being Fetched
          // Display loading indicator
          return Container(
            color: Colors.white,
            child: const Center(
                child: CircularProgressIndicator()
            ),
          );
        }
      },
    );
  }

  // Method to Fetch All Current Comments for Current Recipe
  Future<List<RecipeComment>> _fetchAllCommentsCurrentRecipe() async {
    List<RecipeComment> commentsCurrentRecipe = [];
    // Connect to DB to fetch all comments for current recipe
    final conn = await Connection.open(
        Endpoint(
          host: 'food-bank-database.c72m8ic4gtlt.us-east-1.rds.amazonaws.com',
          database: 'food-bank-database',
          username: 'postgres',
          password: 'Aminifoodbank123',
        )
    );
    // Get all comments under current recipe
    final fetchAllCommentsCurrentRecipeResult = await conn.execute(
      Sql.named('SELECT username, comment, timestamp FROM recipe_comment WHERE recipe_id = @recipeID'),
      parameters: {'recipeID': widget.currentRecipeID}
    );
    final fetchAllCommentsCurrentRecipeResultList = fetchAllCommentsCurrentRecipeResult.toList();
    // Close connection to DB
    await conn.close();
    if (fetchAllCommentsCurrentRecipeResultList.isEmpty) {
      // Error Message
      Fluttertoast.showToast(
          msg: 'No comments found for current recipe.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.grey,
          textColor: Colors.black
      );
      return commentsCurrentRecipe;
    }
    // Populate commentsCurrentRecipe
    for (var i = 0; i < fetchAllCommentsCurrentRecipeResultList.length; ++i) {
      String currentPosterUsername = fetchAllCommentsCurrentRecipeResultList.elementAt(i)[0]!.toString();
      String currentComment = fetchAllCommentsCurrentRecipeResultList.elementAt(i)[1]!.toString();
      DateTime currentTimestamp = DateTime.parse(fetchAllCommentsCurrentRecipeResultList.elementAt(i)[2]!.toString());
      // Add to commentsCurrentRecipe
      commentsCurrentRecipe.add(RecipeComment(widget.currentRecipeID, currentPosterUsername, currentComment, currentTimestamp));
    }
    return commentsCurrentRecipe;
  }

  // Method to Add New Comment for Current Recipe to DB
  void _addCommentCurrentRecipeToDB(RecipeComment newComment) async {
    final conn = await Connection.open(
      Endpoint(
        host: 'food-bank-database.c72m8ic4gtlt.us-east-1.rds.amazonaws.com',
        database: 'food-bank-database',
        username: 'postgres',
        password: 'Aminifoodbank123',
      )
    );
    // Add new comment to DB
    final addNewCommentCurrentRecipeResult = await conn.execute(
        Sql.named('INSERT INTO recipe_comment VALUES (@recipeID, @posterUsername, @comment, @timestamp)'),
        parameters: {'recipeID': newComment.recipeID, 'posterUsername': newComment.posterUsername, 'comment': newComment.comment, 'timestamp': newComment.timestamp}
    );
    // Now, check if comment has been added to DB
    final checkForNewCommentCurrentRecipeResult = await conn.execute(
        Sql.named('SELECT * FROM recipe_comment WHERE recipe_id = @recipeID AND username = @posterUsername AND comment = @comment AND timestamp = @timestamp'),
        parameters: {'recipeID': newComment.recipeID, 'posterUsername': newComment.posterUsername, 'comment': newComment.comment, 'timestamp': newComment.timestamp}
    );
    final checkForNewCommentCurrentRecipeResultList = checkForNewCommentCurrentRecipeResult.toList();
    if (checkForNewCommentCurrentRecipeResultList.isNotEmpty) {
      // Case: Comment posted successfully
      Fluttertoast.showToast(
          msg: 'Comment posted successfully!',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.grey,
          textColor: Colors.black
      );
    } else {
      // Case: Comment not posted successfully
      Fluttertoast.showToast(
          msg: 'Error: Unable to post comment.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.grey,
          textColor: Colors.black
      );
    }
    // Close connection to DB
    await conn.close();
  }
}