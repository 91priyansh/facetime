import 'package:cloud_firestore/cloud_firestore.dart';

class UserDetails {
  final String userId;
  final String username;
  final String userImageUrl;
  final String email;

  UserDetails({this.userId, this.userImageUrl, this.username, this.email});

  static UserDetails fromSnapshot(DocumentSnapshot documentSnapshot) {
    return UserDetails(
      userId: documentSnapshot.id,
      email: documentSnapshot.data()['email'] ?? "",
      username: documentSnapshot.data()['username'] ?? "",
      userImageUrl: documentSnapshot.data()['userImageUrl'] ?? "",
    );
  }
}
