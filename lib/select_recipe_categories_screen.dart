import 'package:flutter/material.dart';
import 'package:postgres/postgres.dart';

import 'secure_storage.dart';

class SelectRecipeCategoriesScreen extends StatefulWidget {
  final Function() refreshRecipeList;

  SelectRecipeCategoriesScreen({
    super.key,
    required this.refreshRecipeList,
  });

  @override
  _SelectRecipeCategoriesScreenState createState() => _SelectRecipeCategoriesScreenState();
}

class _SelectRecipeCategoriesScreenState extends State<SelectRecipeCategoriesScreen> {
  late List<String> _selectedCategories;

  @override
  void initState() {
    super.initState();
    // Fetch selected recipe categories from SecureStorage
    _fetchSelectedRecipeCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Recipe Categories'),
      ),
      body: FutureBuilder<List<String>>(
        future: _fetchCategories(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            // Case: Something went wrong with fetching recipe categories from DB
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            // Case: Recipe category data fetching from DB successful
            // Populate allRecipeCategories
            final allRecipeCategories = snapshot.data!;
            // Display list of checkboxes, one per recipe category
            return ListView.builder(
              itemCount: allRecipeCategories.length,
              itemBuilder: (context, index) {
                final category = allRecipeCategories[index];
                return CheckboxListTile(
                  title: Text(category),
                  value: _selectedCategories.contains(category),
                  onChanged: (value) {
                    setState(() {
                      if (value!) {
                        _selectedCategories.add(category);
                      } else {
                        _selectedCategories.remove(category);
                      }
                      // Remove empty strings from _selectedCategories
                      _selectedCategories = _selectedCategories.where((item) => item.isNotEmpty).toList();
                    });
                  },
                );
              },
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
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Update selected categories list (using Flutter Secure Storage)
          await SecureStorage().updateSelectedRecipeCategories(_selectedCategories);
          // Refresh main screen's recipe list
          widget.refreshRecipeList();
          // Go back to home screen
          Navigator.of(context).pop(context);
        },
        child: const Icon(Icons.save),
      ),
    );
  }

  // Method to Fetch All of the Current Recipe Categories
  Future<List<String>> _fetchCategories() async {
    List<String> categories = [];
    // Connect to DB to fetch recipe categories
    final conn = await Connection.open(
        Endpoint(
          host: 'food-bank-database.c72m8ic4gtlt.us-east-1.rds.amazonaws.com',
          database: 'food-bank-database',
          username: 'postgres',
          password: 'Aminifoodbank123',
        )
    );
    // Get category names using DB query
    final categoryNamesFetchResult = await conn.execute('SELECT DISTINCT category FROM recipe');
    final categoryNamesFetchResultList = categoryNamesFetchResult.toList();
    // Close connection to DB
    await conn.close();
    // Convert to List of String
    for (var i = 0; i < categoryNamesFetchResultList.length; ++i) {
      // Remove beginning and ending square brackets from each of the category names
      String currentCategory = categoryNamesFetchResultList[i].toString().substring(1, categoryNamesFetchResultList[i].toString().length - 1);
      categories.add(currentCategory);
    }
    // Remove 'random' from list of categories
    categories.remove('random');
    // Return List
    return categories;
  }

  // Method to Fetch All Selected Recipe Categories from SecureStorage
  void _fetchSelectedRecipeCategories() async {
    _selectedCategories = await SecureStorage().retrieveSelectedRecipeCategories();
    print(_selectedCategories); // DEBUG
  }
}