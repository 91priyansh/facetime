import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:facetime/helpers/ringtoneHelper.dart';
import 'package:facetime/models/userDetails.dart';
import 'package:facetime/services/database/firebaseDatabase.dart';
import 'package:facetime/utils/keys.dart';
import 'package:facetime/utils/routes.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:facetime/utils/constants.dart' as constants;
import 'package:http/http.dart' as http;
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

///
///All background message related fucntion must be globl or static
///

//Receiver port for Fcm background message isolate
final ReceivePort backgroundMessageport = ReceivePort()
  ..listen(backgroundMessagePortHandler); //adding listener to receiver port

//isolate name
const String backgroundMessageIsolateName = 'fcm_background_msg_isolate';

//listener for background message isolate
void backgroundMessagePortHandler(message) {
  print("From isolate background message handler");
  print(message);
  print("===========================================================");
  //Message to stop ringtone when user accept or reject call
  if (message == "stopRingtone") {
    FlutterRingtonePlayer.stop();
  }
}

class NotificationHelper {
  static final String _fcmUrl = "https://fcm.googleapis.com/fcm/send";
  static final _headers = {
    'content-type': 'application/json',
    'Authorization': 'key= $fcmServerKey'
  };

  //to add current user's fcm token
  static void addFcmToken(String currentUserId) async {
    try {
      await FirebaseDatabase.addFcmToken(currentUserId);
      print("fcm token added for $currentUserId");
    } catch (e) {
      print(e.toString());
      //add shared pref that indicate fcm has not been added for this user
    }
  }

  //remove user's fcm token
  static Future<void> removeFcmToken(String currentUserId) async {
    try {
      await FirebaseDatabase.removeFcmToken(currentUserId);
      print("fcm token removed for $currentUserId");
    } catch (e) {
      print(e.toString());
      //add shared pref that indicate fcm has not been removed for this user
    }
  }

  ///initialization of awesome local notification
  static Future<void> initializeAwesomeNotification() async {
    await AwesomeNotifications().initialize(null, [
      NotificationChannel(
          channelKey: constants.notificationChannelKey,
          channelName: 'Basic notifications',
          channelDescription: 'Notification channel for basic tests',
          defaultColor: Color(0xFF9D50DD),
          vibrationPattern: highVibrationPattern,
          ledColor: Colors.white),
      NotificationChannel(
          channelKey: constants.callNotificationChannelKey,
          channelName: 'Call notifications',
          channelDescription:
              'Notification channel for video call notification',
          defaultColor: Color(0xFF9D50DD),
          locked: true,
          importance: NotificationImportance.High,
          vibrationPattern: highVibrationPattern,
          ledColor: Colors.white)
    ]);
  }

  ///
  ///initialization of firebase cloud messaging
  ///
  static void initializeFirebaseCloudMessaging() {
    FirebaseMessaging().configure(
        onBackgroundMessage: Platform.isIOS ? null : backgroundMessageHandler,
        onLaunch: (message) async {
          print("onLaunch");
          print(message);
        },
        onMessage: (message) async {
          print("onMessage");
          if (message['data']['notificationType'] ==
              constants.callNotificationType) {
            RingtonePlayer.playRingtone();
          } else {
            print(message);
            showLocalNotification(message);
          }
        },
        onResume: (message) async {
          print("onResume");
          print(message);
        });
  }

  ///firebase backgroundMessageHandler
  static Future<dynamic> backgroundMessageHandler(
      Map<String, dynamic> message) async {
    //
    IsolateNameServer.registerPortWithName(
      backgroundMessageport.sendPort,
      backgroundMessageIsolateName,
    );

    print("Handle background message");
    print(message);
    if (message['data']['notificationType'].toString() ==
        constants.callNotificationType) {
      FlutterRingtonePlayer.playRingtone(
          looping: false, asAlarm: false, volume: 1.0);
      //show local notification
      showLocalCallNotification(message['data']);
    } else if (message['data']['notificationType'].toString() ==
        constants.callEndedNotificationType) {
      ///cancel call notification
      await AwesomeNotifications().cancel(1);
      await FlutterRingtonePlayer.stop();
    }
  }

  ///
  ///Navigate to page based on notification
  ///This will be in use to navigate user to other screen based on notification
  ///

  static void navigateToPage(
      BuildContext context, ReceivedAction receivedAction) {
    if (receivedAction.payload['notificationType'] ==
        constants.callNotificationType) {
      print(receivedAction);
    } else if (receivedAction.payload['notificationType'] ==
        constants.friendRequestAcceptedNotificationType) {
      Navigator.of(context).pushNamed(Routes.userPage, arguments: {
        "userDetails": UserDetails(
            userId: receivedAction.payload['userId'],
            userImageUrl: receivedAction.payload['userImageUrl'],
            username: receivedAction.payload['username']),
        "checkForFriendship": false
      });
    } else if (receivedAction.payload['notificationType'] ==
        constants.friendRequestNotificationType) {
      Navigator.of(context).pushNamed(Routes.friendRequestPage);
    }
  }

  ///Cloud notification (FCM)
  ///
  //send incoming video call notification
  static Future<void> sendCallNotification(
      {String fcmToken,
      String title,
      String body,
      String callerName,
      String callerId,
      String channelName}) async {
    final data = {
      "to": fcmToken,
      "priority": "high",
      "data": {
        "title": title,
        "body": body,
        "channelName": channelName,
        "callerName": callerName,
        "callerId": callerId,
        "notificationType": constants.callNotificationType
      }
    };
    try {
      //
      http.Response response =
          await http.post(_fcmUrl, headers: _headers, body: jsonEncode(data));
      print(response.statusCode);
      print("Notificaiton sent successfully");
    } on SocketException catch (e) {
      print("No internet");
      print(e.message);
    } catch (e) {
      print(e.toString());
    }
  }

  ///
  ///Send call ended(missedCall) notification
  ///
  static Future<void> sendCallEndedNotification({
    String fcmToken,
    String title,
    String body,
  }) async {
    final data = {
      "to": fcmToken,
      "priority": "high",
      "data": {
        "title": title,
        "body": body,
        "notificationType": constants.callEndedNotificationType
      }
    };
    try {
      //
      http.Response response =
          await http.post(_fcmUrl, headers: _headers, body: jsonEncode(data));
      print(response.statusCode);
      print("Notificaiton sent successfully");
    } on SocketException catch (e) {
      print("No internet");
      print(e.message);
    } catch (e) {
      print(e.toString());
    }
  }

  ///
  ///  send friend request notification
  ///
  static Future<void> sendFriendRequestNotification({
    String fcmToken,
    String title,
    String body,
  }) async {
    final data = {
      "to": fcmToken,
      "priority": "high",
      "notification": {
        "title": title,
        "body": body,
      },
      "data": {
        "click_action": "FLUTTER_NOTIFICATION_CLICK",
        "notificationType": constants.friendRequestNotificationType
      }
    };
    try {
      http.Response response =
          await http.post(_fcmUrl, headers: _headers, body: jsonEncode(data));
      print(response.statusCode);
      print("Notificaiton sent successfully");
    } on SocketException catch (e) {
      print("No internet");
      print(e.message);
    } catch (e) {
      print(e.toString());
    }
  }

  ///
  ///  send friend request has been accepted notification
  ///
  static Future<void> sendFriendRequestAcceptedNotification(
      {String fcmToken,
      String title,
      String body,
      String userId,
      String userImageUrl,
      String username}) async {
    final data = {
      "to": fcmToken,
      "priority": "high",
      "notification": {
        "title": title,
        "body": body,
      },
      "data": {
        "click_action": "FLUTTER_NOTIFICATION_CLICK",
        "notificationType": constants.friendRequestAcceptedNotificationType,
        "userId": userId,
        "username": username,
        "userImageUrl": userImageUrl
      }
    };
    try {
      http.Response response =
          await http.post(_fcmUrl, headers: _headers, body: jsonEncode(data));
      print(response.statusCode);
      print("Notificaiton sent successfully");
    } on SocketException catch (e) {
      print("No internet");
      print(e.message);
    } catch (e) {
      print(e.toString());
    }
  }

  ///
  ///Local call notification
  ///
  static Future<void> showLocalCallNotification(var message) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        title: message['title'],
        body: message['body'],
        id: 1,
        payload: {
          "channelName": message['channelName'],
          "callerName": message['callerName'],
          "callerId": message['callerId'],
          "notificationType": message['notificationType']
        },
        channelKey: constants.callNotificationChannelKey,
      ),
    );
  }

  ///
  ///Local notification
  ///
  static Future<void> showLocalNotification(var message) async {
    Map<String, String> payload = {};

    if (message['data']['notificationType'] ==
        constants.friendRequestAcceptedNotificationType) {
      payload = {
        "notificationType": message['data']['notificationType'],
        "username": message['data']['username'],
        "userId": message['data']['userId'],
        "userImageUrl": message['data']['userImageUrl']
      };
    } else if (message['data']['notificationType'] ==
        constants.friendRequestNotificationType) {
      print("Friend request notification");
      payload = {
        "notificationType": message['data']['notificationType'],
      };
    }
    print(payload);
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1,
        showWhen: true,
        title: message['notification']['title'],
        body: message['notification']['body'],
        payload: payload,
        channelKey: constants.notificationChannelKey,
      ),
    );
  }
}

/*
              print("Search user contacts");
              final String fcmToken = await FirebaseMessaging().getToken();
              print(fcmToken);
              await Future.delayed(
                  Duration(
                    seconds: 10,
                  ), () {
                print("Will send notification");
                NotificationHelper.sendCallNotification(
                    fcmToken: fcmToken,
                    callChannelId: "1234567890",
                    callerId: "abcd",
                    title: "Video call from piyudoo",
                    callerName: "Priyansh");
              });
              */
