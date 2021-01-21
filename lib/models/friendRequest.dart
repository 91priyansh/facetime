import 'package:cloud_firestore/cloud_firestore.dart';

class FriendRequest {
  final String by;
  final String username;
  final String userImageUrl;
  final Timestamp timestamp;

  FriendRequest({this.by, this.userImageUrl, this.username, this.timestamp});

  static FriendRequest fromSnapshot(DocumentSnapshot documentSnapshot) {
    return FriendRequest(
      by: documentSnapshot.data()['by'],
      username: documentSnapshot.data()['username'] ?? "",
      userImageUrl: documentSnapshot.data()['userImageUrl'] ?? "",
      timestamp: documentSnapshot.data()['timestamp'],
    );
  }
}
