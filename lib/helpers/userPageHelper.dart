import 'package:facetime/helpers/notificationHelper.dart';
import 'package:facetime/models/userDetails.dart';
import 'package:facetime/pages/userPage.dart';
import 'package:facetime/providers/rootProvider.dart';
import 'package:facetime/services/database/firebaseDatabase.dart';
import 'package:facetime/utils/errors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

//Helper class for userPage
//All fucntion that communicate with database(firebase) and fcm(firebase cloud messge)
//will be here

class UserPageHelper {
  final BuildContext context;
  final Function changeFriendshipStatus;
  final UserDetails userDetails;
  UserPageHelper({this.context, this.changeFriendshipStatus, this.userDetails});

  //check frindship with given user
  void checkFriendship() async {
    try {
      String currentUserId =
          Provider.of<RootProvider>(context, listen: false).currentUserId;

      bool _isFriend = await FirebaseDatabase.checkIsFriend(
          currentUserId: currentUserId, userId: userDetails.userId);
      if (_isFriend) {
        changeFriendshipStatus(FriendshipStatus.friend);
      } else {
        int _requestStatus = await FirebaseDatabase.requestStatus(
            currentUserId: currentUserId, userId: userDetails.userId);
        //_requestStatus can hold three value 1,2,3
        //1 if there is not request
        //2 if current user sent request to given user
        //3 if given user sent request to current user
        if (_requestStatus == 1) {
          //sendRequest
          changeFriendshipStatus(FriendshipStatus.sendRequest);
        } else if (_requestStatus == 2) {
          //requested
          changeFriendshipStatus(FriendshipStatus.requested);
        } else {
          //acceptRequest
          changeFriendshipStatus(FriendshipStatus.acceptRequest);
        }
      }
    } catch (e) {}
  }

  ///
  ///to send friend request and notification
  ///
  void sendFriendRequest() {
    //changing friendship status to requested
    changeFriendshipStatus(FriendshipStatus.requested);
    final UserDetails currentUserDetails =
        Provider.of<RootProvider>(context, listen: false).userDetails;

    //send friend request
    FirebaseDatabase.sendFriendRequest(
            currentUserId: currentUserDetails.userId,
            userId: userDetails.userId,
            userImageUrl: currentUserDetails.userImageUrl,
            username: currentUserDetails.username)
        .then((_) {
      //fetch fcmToken to send notification
      FirebaseDatabase.fetchFcmToken(userDetails.userId).then((fcmToken) {
        if (fcmToken.isNotEmpty) {
          NotificationHelper.sendFriendRequestNotification(
              fcmToken: fcmToken,
              title: "New friend request",
              body: "${currentUserDetails.username} sent you friend request");
        } else {
          print("Fcm token not found for this user");
        }
      }).catchError((e) {
        ///
        ///Error while fetching fcm token
        ///
        print(e.toString());
      });
    }).catchError((e) {
      //error while sending friend request
      changeFriendshipStatus(FriendshipStatus.sendRequest);
      Errors.showErrorDialog(context, "Could not send friend request");
    });
  }

  ///
  /// Cancel frined request
  ///
  void cancelFriendRequest() {
    final String currentUserId =
        Provider.of<RootProvider>(context, listen: false).currentUserId;

    showDialog(
        context: context,
        builder: (context) {
          return CupertinoAlertDialog(
            content: Text("Are you sure to cancel request?"),
            actions: [
              CupertinoButton(
                child: Text("Yes"),
                onPressed: () {
                  Navigator.of(context).pop();
                  //change friendship status
                  changeFriendshipStatus(FriendshipStatus.sendRequest);
                  //remove friend request
                  FirebaseDatabase.removeFriendRequest(
                          currentUserId: currentUserId,
                          userId: userDetails.userId)
                      .then((_) {})
                      .catchError((e) {
                    changeFriendshipStatus(FriendshipStatus.requested);
                    Errors.showErrorDialog(context, e.toString());
                  });
                },
              ),
              CupertinoButton(
                child: Text("No"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  ///
  ///Accept request (add friend)
  ///
  void acceptRequest() {
    changeFriendshipStatus(FriendshipStatus.friend);
    final UserDetails currentUserDetails =
        Provider.of<RootProvider>(context, listen: false).userDetails;
    //add friend
    FirebaseDatabase.addFriend(
            currentUserId: currentUserDetails.userId,
            currentUserImageUrl: currentUserDetails.userImageUrl,
            currnetUsername: currentUserDetails.username,
            userId: userDetails.userId,
            userImageUrl: userDetails.userImageUrl,
            username: userDetails.username)
        .then((_) {
      ///
      ///delete friend request form currentUser and given user
      ///
      FirebaseDatabase.removeFriendRequest(
              currentUserId: currentUserDetails.userId,
              userId: userDetails.userId)
          .catchError((e) {});

      ///
      ///fetch fcm token of given user
      ///
      FirebaseDatabase.fetchFcmToken(userDetails.userId).then((token) {
        if (token.isNotEmpty) {
          ///
          ///send friend request has been accepted notification
          ///
          NotificationHelper.sendFriendRequestAcceptedNotification(
              body:
                  "${currentUserDetails.username} accepted your friend request",
              fcmToken: token,
              title: "You have new friend",
              userId: currentUserDetails.userId,
              username: currentUserDetails.username,
              userImageUrl: currentUserDetails.userImageUrl);
        } else {
          print("Could not find fcm token of given ${userDetails.userId}");
        }
      }).catchError((e) {
        //error while fetching fcm token for given user
        print(e.toString());
      });
    }).catchError((e) {
      //error while adding friend
      changeFriendshipStatus(FriendshipStatus.acceptRequest);
      Errors.showErrorDialog(context, e.toString());
    });
  }

  ///
  ///unfirend user or remove user from current user's friend list
  ///

  void unfriendUser() {
    final String currentUserId =
        Provider.of<RootProvider>(context, listen: false).currentUserId;
    //to unfriend user
    showDialog(
        context: context,
        builder: (context) {
          return CupertinoAlertDialog(
            content: Text("Are you sure to unfriend ${userDetails.username}?"),
            actions: [
              CupertinoButton(
                child: Text("Yes"),
                onPressed: () {
                  Navigator.of(context).pop();
                  //send request
                  changeFriendshipStatus(FriendshipStatus.sendRequest);
                  FirebaseDatabase.removeFriend(
                          currentUserId: currentUserId,
                          userId: userDetails.userId)
                      .then((_) {})
                      .catchError((e) {
                    changeFriendshipStatus(FriendshipStatus.friend);
                    Errors.showErrorDialog(context, e.toString());
                  });
                },
              ),
              CupertinoButton(
                child: Text("No"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }
}
