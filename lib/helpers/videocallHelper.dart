import 'dart:math';

import 'package:facetime/helpers/notificationHelper.dart';
import 'package:facetime/models/userDetails.dart';
import 'package:facetime/providers/rootProvider.dart';
import 'package:facetime/services/database/firebaseDatabase.dart';
import 'package:facetime/utils/errors.dart';
import 'package:flutter/cupertino.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class VideoCallHelper {
  //To generate random string for videocall channel name
  static String generateChannelName(int len) {
    var r = Random.secure();
    const _chars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    return List.generate(len, (index) => _chars[r.nextInt(_chars.length)])
        .join();
  }

  static Future<void> handleCameraAndMicPermission(
      Permission permission) async {
    final status = await permission.request();
    print(status);
  }

  static void addCurrentCall({
    String channelName,
    UserDetails friendDetails,
    BuildContext context,
    //friendDetails
  }) async {
    UserDetails currentUserDetails =
        Provider.of<RootProvider>(context, listen: false).userDetails;
    FirebaseDatabase.addCurrentCall(
            callerId: currentUserDetails.userId,
            channelName: channelName,
            currentUserDetails: currentUserDetails,
            friendDetails: friendDetails)
        .then((_) {
      ///
      ///Sending friend video call notification
      ///
      print("Video call added");
      print("Fetching fcmToken");
      //send call notification
      FirebaseDatabase.fetchFcmToken(friendDetails.userId).then((fcmToken) {
        //if fcmtoken is available
        if (fcmToken.isNotEmpty) {
          print("fcmToken fetched and sending call notification");
          NotificationHelper.sendCallNotification(
              callerId: currentUserDetails.userId,
              callerName: currentUserDetails.username,
              channelName: channelName,
              fcmToken: fcmToken,
              body: "Incoming video call",
              title: currentUserDetails.username);
        }
      }).catchError((e) {});

      ///
      ///Add call history
      ///
      FirebaseDatabase.addCallHistory(
              callerId: currentUserDetails.userId,
              currentUserDetails: currentUserDetails,
              friendDetails: friendDetails)
          .catchError((e) {});

      ///
      ///
    }).catchError((e) {
      Navigator.pop(context);
      Errors.showErrorDialog(
          context, "Could not make video call, Please try again later!!");
    });
  }

  static void sendMissedCallNotification(String userId) {
    FirebaseDatabase.fetchFcmToken(userId).then((fcmToken) {
      if (fcmToken.isNotEmpty) {
        NotificationHelper.sendCallEndedNotification(
            body: "call ended", title: "call ended", fcmToken: fcmToken);
      }
    }).catchError((e) {
      //
      ///Error while getting fcmToken
    });
  }
}
