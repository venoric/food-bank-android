library user_profile;

// User Profile Class
class UserProfile {
  // Member Variables
  late String _username;
  late String _firstName;
  late String _lastName;
  late String _email;
  late List<String> _userAllergies;
  // Constructor
  UserProfile(String username, String firstName, String lastName, String email) {
    this._username = username;
    this._firstName = firstName;
    this._lastName = lastName;
    this._email = email;
    this._userAllergies = [];
  }
  // Methods
  void addAllergy(String currentAllergy) {
    this._userAllergies.add(currentAllergy);
  }
  // Getters
  String get username => _username;
  String get firstName => _firstName;
  String get lastName => _lastName;
  String get email => _email;
  List<String> get userAllergies => _userAllergies;
}