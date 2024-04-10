library secure_storage;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// "Secure Storage" Class for Login Check
class SecureStorage {
  final _storage = const FlutterSecureStorage();

  // Store the username of the user who logged in
  setLoggedInUser(String key, String loggedInUser) async {
    await _storage.write(key: 'loggedInUser', value: loggedInUser);
  }

  // Retrieve the username of the user who logged in (if applicable)
  Future<String> retrieveLoggedInUser(String key) async {
    String? loggedInUser = await _storage.read(key: key);
    if (loggedInUser != null) {
      // Case: User is logged in
      return loggedInUser;
    } else {
      // Case: No user is logged in
      return 'null';
    }
  }

  // Delete the username of the user who logged out
  unsetLoggedInUser(String key) async {
    await _storage.delete(key: key);
  }
}