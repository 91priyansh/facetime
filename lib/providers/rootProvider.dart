import 'package:facetime/helpers/notificationHelper.dart';
import 'package:facetime/models/userDetails.dart';
import 'package:facetime/services/authService.dart';
import 'package:facetime/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

///Root provider for app to store currentUserDetails
///authentication details

class RootProvider with ChangeNotifier {
  bool _isLoggedIn;
  String _currentUserId;
  UserDetails _userDetails;

  SharedPreferences _sharedPreferences;

  RootProvider(SharedPreferences sharedPreferences) {
    _sharedPreferences = sharedPreferences;
    //Fetching auth status
    _isLoggedIn = _sharedPreferences.getBool(sharedPrefIsLogIn) ?? false;
    _currentUserId =
        _sharedPreferences.getString(sharedPrefCurrentUserId) ?? "";
    fetchUserDetails();
  }

  void fetchUserDetails() {
    _userDetails = UserDetails(
        email: _sharedPreferences.get(sharedPrefCurrentUserEmail) ?? "",
        userId: _currentUserId,
        userImageUrl:
            _sharedPreferences.getString(sharedPrefCurrentUserImageUrl) ?? "",
        username:
            _sharedPreferences.getString(sharedPrefCurrentUserName) ?? "");
  }

  bool get isLoggedIn => _isLoggedIn;
  String get currentUserId => _currentUserId;
  SharedPreferences get sharedPreferences => _sharedPreferences;
  UserDetails get userDetails => _userDetails;

  void setCurrentUserId(String currentUserId) {
    _currentUserId = currentUserId;
    notifyListeners();
  }

  void changeIsLoggedIn() {
    _isLoggedIn = !_isLoggedIn;
    notifyListeners();
  }

  //changing auth status
  void changeAuthStatus(String currentUserId,
      {String userImageUrl, String email, String username}) {
    ///add fcm token of user to database
    NotificationHelper.addFcmToken(currentUserId);

    ///
    _currentUserId = currentUserId;
    _isLoggedIn = !_isLoggedIn;
    _sharedPreferences.setBool(sharedPrefIsLogIn, _isLoggedIn);
    _sharedPreferences.setString(sharedPrefCurrentUserId, _currentUserId);
    _sharedPreferences.setString(sharedPrefCurrentUserName, username);
    _sharedPreferences.setString(sharedPrefCurrentUserImageUrl, userImageUrl);
    _sharedPreferences.setString(sharedPrefCurrentUserEmail, email);

    _userDetails = UserDetails(
        email: email,
        userId: _currentUserId,
        userImageUrl: userImageUrl,
        username: username);
    notifyListeners();
  }

  //Signing out user
  void signOut() async {
    //Removing fcmtoken for signed out user
    await NotificationHelper.removeFcmToken(_currentUserId);
    AuthService.signOut();
    _currentUserId = "";
    _isLoggedIn = false;
    _sharedPreferences.setBool(sharedPrefIsLogIn, _isLoggedIn);
    _sharedPreferences.setString(sharedPrefCurrentUserId, _currentUserId);
    _sharedPreferences.setString(sharedPrefCurrentUserName, "");
    _sharedPreferences.setString(sharedPrefCurrentUserImageUrl, "");
    _sharedPreferences.setString(sharedPrefCurrentUserEmail, "");
    _userDetails =
        UserDetails(email: "", userId: "", userImageUrl: "", username: "");
    print("sign out");
    notifyListeners();
  }
}
