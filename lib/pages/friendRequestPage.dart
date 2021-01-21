import 'package:facetime/helpers/notificationHelper.dart';
import 'package:facetime/models/friendRequest.dart';
import 'package:facetime/models/userDetails.dart';
import 'package:facetime/pages/userPage.dart';
import 'package:facetime/providers/rootProvider.dart';
import 'package:facetime/services/database/firebaseDatabase.dart';
import 'package:facetime/utils/errors.dart';
import 'package:facetime/widgets/profilePictureContainer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class FriendRequestPage extends StatelessWidget {
  const FriendRequestPage({Key key}) : super(key: key);

  void _acceptRequest(UserDetails currentUserDetails,
      FriendRequest friendRequest, BuildContext context) {
    FirebaseDatabase.addFriend(
            currentUserId: currentUserDetails.userId,
            currentUserImageUrl: currentUserDetails.userImageUrl,
            currnetUsername: currentUserDetails.username,
            userId: friendRequest.by,
            userImageUrl: friendRequest.userImageUrl,
            username: friendRequest.username)
        .then((_) {
      ///
      ///delete friend request form currentUser and given user
      ///
      FirebaseDatabase.removeFriendRequest(
              currentUserId: currentUserDetails.userId,
              userId: friendRequest.by)
          .catchError((e) {});

      ///
      ///fetch fcm token of given user
      ///
      FirebaseDatabase.fetchFcmToken(friendRequest.by).then((token) {
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
          print("Could not find fcm token of given ${friendRequest.by}");
        }
      }).catchError((e) {
        //error while fetching fcm token for given user
        print(e.toString());
      });
    }).catchError((e) {
      //error while adding friend
      Errors.showErrorDialog(context, e.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    final UserDetails currentUserDetails =
        Provider.of<RootProvider>(context, listen: false).userDetails;
    return Scaffold(
      appBar: AppBar(
        title: Text("Friend Request"),
      ),
      body: StreamBuilder<List<FriendRequest>>(
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text("Could not get friend requests"),
            );
          }
          snapshot.data.sort((request1, request2) =>
              request2.timestamp.compareTo(request1.timestamp));
          return ListView.builder(
            padding: EdgeInsets.only(top: 10.0),
            itemCount: snapshot.data.length,
            itemBuilder: (context, index) {
              FriendRequest friendRequest = snapshot.data[index];
              String requestTime = timeago.format(
                  friendRequest.timestamp.toDate(),
                  allowFromNow: true,
                  locale: 'en_short');

              return ListTile(
                title: Text(friendRequest.username),
                subtitle: Text(requestTime),
                leading: ProfilePictureContainer(
                  imageUrl: friendRequest.userImageUrl,
                ),
                trailing: Container(
                  width: MediaQuery.of(context).size.width * 0.45,
                  child: Row(
                    children: [
                      SizedBox(
                        height: 30,
                        child: CustomRoundedButton(
                          title: "Accept",
                          size: 0.2,
                          function: () {
                            _acceptRequest(
                                currentUserDetails, friendRequest, context);
                          },
                        ),
                      ),
                      SizedBox(
                        width: 10.0,
                      ),
                      SizedBox(
                        height: 30,
                        child: CustomRoundedButton(
                          title: "Cancel",
                          size: 0.2,
                          function: () {
                            FirebaseDatabase.removeFriendRequest(
                              currentUserId: currentUserDetails.userId,
                              userId: friendRequest.by,
                            ).catchError((e) {
                              Errors.showErrorDialog(context, e.toString());
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        stream: FirebaseDatabase.friendRequestStream(currentUserDetails.userId),
      ),
    );
  }
}
