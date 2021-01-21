import 'package:facetime/pages/friendRequestPage.dart';
import 'package:facetime/pages/homePage.dart';
import 'package:facetime/pages/incomingVideoCallPage.dart';
import 'package:facetime/pages/loginPage.dart';
import 'package:facetime/pages/moreCallHistoryPage.dart';
import 'package:facetime/pages/moreFriendsPage.dart';
import 'package:facetime/pages/rootPage.dart';
import 'package:facetime/pages/signupPage.dart';
import 'package:facetime/pages/userPage.dart';
import 'package:facetime/pages/videoCallPage.dart';
import 'package:facetime/utils/errors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Routes {
  //Routes name
  static String currentRoute = "/";
  static const String homePage = "/home";
  static const String logInPage = "/login";
  static const String signUpPage = "/signup";
  static const String userPage = "/user";
  static const String incomingVideoCallPage = "/incomingVideoCall";
  static const String videocallPage = "/videoCall";
  static const String friendRequestPage = "/friendRequest";
  static const String moreCallHistoryPage = "/moreCallHistory";
  static const String moreFriendsPage = "/moreFriends";

  //Ongenerate function
  static Route<dynamic> onGenerateRoute(RouteSettings routeSettings) {
    currentRoute = routeSettings.name;
    switch (routeSettings.name) {
      case "/":
        {
          return CupertinoPageRoute(builder: (context) => RootPage());
        }

      case logInPage:
        {
          return CupertinoPageRoute(builder: (context) => LoginPage());
        }
      case signUpPage:
        {
          return CupertinoPageRoute(builder: (context) => SignUpPage());
        }
      case homePage:
        {
          return CupertinoPageRoute(builder: (context) => HomePage());
        }
      case userPage:
        {
          return UserPage.route(routeSettings);
        }
      case incomingVideoCallPage:
        {
          return IncomingVideoCallPage.route(routeSettings);
        }
      case videocallPage:
        {
          return VideoCallPage.route(routeSettings);
        }
      case friendRequestPage:
        {
          return CupertinoPageRoute(builder: (context) => FriendRequestPage());
        }

      case moreCallHistoryPage:
        {
          return MoreCallHistoryPage.route(routeSettings);
        }

      case moreFriendsPage:
        {
          return MoreFriendsPage.route(routeSettings);
        }

      default:
        {
          return CupertinoPageRoute(
              builder: (context) => Errors.getErrorPage());
        }
    }
  }
}
