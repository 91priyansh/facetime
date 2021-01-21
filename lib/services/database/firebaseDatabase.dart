import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:facetime/models/callHistory.dart';
import 'package:facetime/models/customException.dart';
import 'package:facetime/models/friendRequest.dart';
import 'package:facetime/models/userDetails.dart';
import 'package:facetime/utils/constants.dart';
import 'package:facetime/utils/errors.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';

///
///Firestore database related functions
///
class FirebaseDatabase {
  //Firestore instance
  static final FirebaseFirestore _firebaseFirestore =
      FirebaseFirestore.instance;

  ///
  ///To fetch usernames(to check entered username is available or not)
  ///
  static Future<List<String>> fetchUsernames(String index) async {
    try {
      List<String> usernames = [];
      //fetcing usernames with given index
      QuerySnapshot querySnapshot = await _firebaseFirestore
          .collection(usernamesCollection)
          .where("index", isEqualTo: index)
          .get();
      querySnapshot.docs.forEach((doc) {
        usernames.add(doc.data()['username']);
      });
      return usernames;
    } on PlatformException catch (e) {
      throw CustomException(errorMessage: e.message);
    } on SocketException catch (_) {
      throw CustomException(errorMessage: "No Internet");
    } catch (e) {
      throw CustomException(errorMessage: Errors.defaultErrorMessage);
    }
  }

  ///
  ///Userdetails related function
  ///

  //adding user details after signup
  static Future<void> addUser({
    String email,
    String uid,
    String username,
  }) async {
    try {
      await _firebaseFirestore.collection(usersCollection).doc(uid).set(
          {"email": email, "username": username, "timestamp": Timestamp.now()});

      ///can use cloud function trigger (in future)
      _firebaseFirestore
          .collection(usernamesCollection)
          .add({"index": username[0], "username": username});
    } on PlatformException catch (e) {
      throw CustomException(errorMessage: e.message);
    } catch (e) {
      throw CustomException(errorMessage: Errors.defaultErrorMessage);
    }
  }

  ///
  ///Fetch userdata with given uid
  ///
  static Future<UserDetails> fetchUserData(String userId) async {
    try {
      DocumentSnapshot documentSnapshot = await _firebaseFirestore
          .collection(usersCollection)
          .doc(userId)
          .get();
      if (documentSnapshot.exists) {
        return UserDetails.fromSnapshot(documentSnapshot);
      }
      return UserDetails();
    } on PlatformException catch (e) {
      print(e.toString());
      throw CustomException(errorMessage: e.message);
    } on SocketException catch (e) {
      print(e.message);
      throw CustomException(errorMessage: "No Internet");
    } catch (e) {
      throw CustomException(errorMessage: Errors.defaultErrorMessage);
    }
  }

  ///
  ///FCM token related fucntions
  ///

  ///
  ///Add fcmToken of current user
  ///
  static Future<void> addFcmToken(String currentUserId) async {
    try {
      String fcmToken = await FirebaseMessaging().getToken();
      await _firebaseFirestore
          .collection(fcmTokensCollection)
          .doc(currentUserId)
          .set({
        "fcmToken": fcmToken,
        "timestamp": Timestamp.now(),
      });
    } on PlatformException catch (e) {
      throw CustomException(errorMessage: e.message);
    } catch (e) {
      throw CustomException(errorMessage: Errors.defaultErrorMessage);
    }
  }

  ///
  ///remove fcm token before signing out
  ///
  static Future<void> removeFcmToken(String currentUserId) async {
    try {
      await _firebaseFirestore
          .collection(fcmTokensCollection)
          .doc(currentUserId)
          .delete();
      print("Fcm token deleted successfully");
    } on PlatformException catch (e) {
      throw CustomException(errorMessage: e.message);
    } catch (e) {
      throw CustomException(errorMessage: Errors.defaultErrorMessage);
    }
  }

  ///
  ///Fetch given user's fcm token
  ///
  static Future<String> fetchFcmToken(String userId) async {
    try {
      DocumentSnapshot documentSnapshot = await _firebaseFirestore
          .collection(fcmTokensCollection)
          .doc(userId)
          .get();

      if (documentSnapshot.exists) {
        return documentSnapshot.data()['fcmToken'];
      }
      return "";
    } on PlatformException catch (e) {
      throw CustomException(errorMessage: e.message);
    } on SocketException catch (e) {
      print(e.message);
      throw CustomException(errorMessage: "No Internet");
    } catch (e) {
      throw CustomException(errorMessage: Errors.defaultErrorMessage);
    }
  }

  ///
  /// Search user
  ///

  ///
  ///Search User (This is not full text searching.To implement
  /// full text searching we need to use algolia or elastic search )
  ///

  static Future<List<DocumentSnapshot>> serachUser(String search) async {
    try {
      QuerySnapshot querySnapshot = await _firebaseFirestore
          .collection("users")
          .where("username", isGreaterThanOrEqualTo: search)
          .where("username", isLessThan: search + 'z')
          .get();

      return querySnapshot.docs;
    } on PlatformException catch (e) {
      print(e.toString());
      throw CustomException(errorMessage: "Could not complete search");
    } on SocketException catch (e) {
      print(e.message);
      throw CustomException(errorMessage: "No Internet");
    } catch (e) {
      throw CustomException(errorMessage: Errors.defaultErrorMessage);
    }
  }

  ///
  ///Video call detials
  ///

  ///
  ///Subscribe to current call (incoming or outgoing)
  ///
  static Stream<DocumentSnapshot> currentCall(String currentUserId) {
    print("Current call");
    return _firebaseFirestore
        .collection(currentCallsCollection)
        .doc(currentUserId)
        .snapshots();
  }

  ///
  ///Fetch call history of current user
  ///(This will be in use to implement pagination)

  static Future<List<DocumentSnapshot>> callHistory(
      String currentUserId, DocumentSnapshot lastDocumentSnapshot) async {
    try {
      List<DocumentSnapshot> calls;
      QuerySnapshot querySnapshot;
      querySnapshot = await _firebaseFirestore
          .collection(usersCollection)
          .doc(currentUserId)
          .collection(callHistoryCollection)
          .orderBy("timestamp", descending: true)
          .startAfterDocument(lastDocumentSnapshot)
          .limit(25)
          .get();
      calls = querySnapshot.docs;
      return calls;
    } on PlatformException catch (e) {
      print(e.toString());
      throw CustomException(errorMessage: e.message);
    } on SocketException catch (e) {
      print(e.message);
      throw CustomException(errorMessage: "No Internet");
    } catch (e) {
      throw CustomException(errorMessage: Errors.defaultErrorMessage);
    }
  }

  ///
  ///Call History Stream
  ///

  static Stream<List<DocumentSnapshot>> callHistoryStream(
      String currentUserId) {
    return _firebaseFirestore
        .collection(usersCollection)
        .doc(currentUserId)
        .collection(callHistoryCollection)
        .orderBy("timestamp", descending: true)
        .limit(25)
        .snapshots()
        .map((query) => query.docs);
  }

  ///
  ///Check user is busy with other call or not
  ///

  static Future<bool> isUserBusy({String userId}) async {
    try {
      DocumentSnapshot documentSnapshot = await _firebaseFirestore
          .collection(currentCallsCollection)
          .doc(userId)
          .get();
      return documentSnapshot.exists;
    } on PlatformException catch (e) {
      print(e.message);
      throw CustomException(errorMessage: "Could not make call");
    } on SocketException catch (_) {
      throw CustomException(errorMessage: "No Internet");
    } catch (e) {
      print(e.toString());
      throw CustomException(errorMessage: "Could not make call");
    }
  }

  ///
  ///Add current call (for caller and receiver )
  ///
  static Future<void> addCurrentCall(
      {String callerId,
      String channelName,
      UserDetails currentUserDetails,
      UserDetails friendDetails}) async {
    try {
      var myCurrentCallDetails = {
        "callerId": callerId,
        "toUsername": friendDetails.username,
        "toImageUrl": friendDetails.userImageUrl,
        "channelName": channelName,
        "to": friendDetails.userId,
        "timestamp": Timestamp.now()
      };
      var friendCurrentCallDetails = {
        "callerId": callerId,
        "toUsername": currentUserDetails.username,
        "toImageUrl": currentUserDetails.userImageUrl,
        "channelName": channelName,
        "to": currentUserDetails.userId,
        "timestamp": Timestamp.now()
      };
      await _firebaseFirestore
          .collection(currentCallsCollection)
          .doc(currentUserDetails.userId)
          .set(myCurrentCallDetails);
      await _firebaseFirestore
          .collection(currentCallsCollection)
          .doc(friendDetails.userId)
          .set(friendCurrentCallDetails);
    } on PlatformException catch (e) {
      print(e.message);
      throw CustomException(errorMessage: "Could not make call");
    } on SocketException catch (_) {
      throw CustomException(errorMessage: "No Internet");
    } catch (e) {
      print(e.toString());
      throw CustomException(errorMessage: "Could not make call");
    }
  }

  ///
  ///Remove current call (It will call when user cuts the call)
  ///
  static Future<void> removeCurrentCall(
      {String friendId, String currentUserId}) async {
    try {
      await _firebaseFirestore
          .collection(currentCallsCollection)
          .doc(currentUserId)
          .delete();
      await _firebaseFirestore
          .collection(currentCallsCollection)
          .doc(friendId)
          .delete();
    } on PlatformException catch (e) {
      print(e.message);
      throw CustomException(errorMessage: "Could not remove call");
    } on SocketException catch (_) {
      throw CustomException(errorMessage: "No Internet");
    } catch (e) {
      print(e.toString());
      throw CustomException(errorMessage: "Could not remove call");
    }
  }

  ///
  ///add call history
  ///
  static Future<void> addCallHistory(
      {UserDetails currentUserDetails,
      UserDetails friendDetails,
      String callerId}) async {
    try {
      //add call details to currnet user's call history
      await _firebaseFirestore
          .collection(usersCollection)
          .doc(currentUserDetails.userId)
          .collection(callHistoryCollection)
          .add({
        "callerId": callerId,
        "timestamp": Timestamp.now(),
        "to": friendDetails.userId,
        "toUsername": friendDetails.username,
        "toImageUrl": friendDetails.userImageUrl
      });

      ///
      /// Add call detials to friend's call history
      ///
      await _firebaseFirestore
          .collection(usersCollection)
          .doc(friendDetails.userId)
          .collection(callHistoryCollection)
          .add({
        "callerId": callerId,
        "timestamp": Timestamp.now(),
        "to": currentUserDetails.userId,
        "toUsername": currentUserDetails.username,
        "toImageUrl": currentUserDetails.userImageUrl
      });
    } on PlatformException catch (e) {
      print(e.message);
      throw CustomException(errorMessage: "Could not add call history");
    } on SocketException catch (_) {
      throw CustomException(errorMessage: "No Internet");
    } catch (e) {
      print(e.toString());
      throw CustomException(errorMessage: "Could not add call history");
    }
  }

  ///
  /// To remove call history
  ///
  static Future<void> removeCallHistory(
      {String callId, String currentUserId}) async {
    try {
      await _firebaseFirestore
          .collection(usersCollection)
          .doc(currentUserId)
          .collection(callHistoryCollection)
          .doc(callId)
          .delete();
    } on PlatformException catch (e) {
      print(e.message);
      throw CustomException(errorMessage: "Could not remove call history");
    } on SocketException catch (_) {
      throw CustomException(errorMessage: "No Internet");
    } catch (e) {
      print(e.toString());
      throw CustomException(errorMessage: "Could not remove call history");
    }
  }

  ///
  ///fetch call history between current user and friend
  ///

  static Future<List<CallHistory>> callHistoryWithFriend(
      String currentUserId, String userId) async {
    try {
      print("Fetching call history with friend");
      QuerySnapshot querySnapshot = await _firebaseFirestore
          .collection(usersCollection)
          .doc(currentUserId)
          .collection(callHistoryCollection)
          .where("to", isEqualTo: userId)
          .orderBy("timestamp", descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => CallHistory.fromSnapshot(doc))
          .toList();
    } on PlatformException catch (e) {
      print(e.message);
      throw CustomException(errorMessage: "Could not fetch call history");
    } on SocketException catch (_) {
      throw CustomException(errorMessage: "No Internet");
    } catch (e) {
      print(e.toString());
      throw CustomException(errorMessage: "Could not fetch call history");
    }
  }

  ///
  /// All friend,friendRequest fucntion
  ///

  ///
  ///All friends stream
  ///

  static Stream<List<DocumentSnapshot>> friendsStream(String userId) {
    return _firebaseFirestore
        .collection(usersCollection)
        .doc(userId)
        .collection(friendsCollection)
        .orderBy("timestamp", descending: true)
        .limit(25)
        .snapshots()
        .map((query) => query.docs);
  }

  ///
  ///Fetch all friend request (of current user)
  ///

  static Stream<List<FriendRequest>> friendRequestStream(String userId) {
    return _firebaseFirestore
        .collection(usersCollection)
        .doc(userId)
        .collection(friendRequestCollection)
        .where("by", isNotEqualTo: userId)
        .snapshots()
        .map((query) =>
            query.docs.map((doc) => FriendRequest.fromSnapshot(doc)).toList());
  }

  ///
  ///Fetch friends for given user
  ///

  static Future<List<DocumentSnapshot>> getFriends(
      {String currentUserId, DocumentSnapshot lastDocumentSnapshot}) async {
    try {
      List<DocumentSnapshot> friends;
      QuerySnapshot querySnapshot;

      querySnapshot = await _firebaseFirestore
          .collection(usersCollection)
          .doc(currentUserId)
          .collection(friendsCollection)
          .orderBy("timestamp", descending: true)
          .startAfterDocument(lastDocumentSnapshot)
          .limit(25)
          .get();
      friends = querySnapshot.docs;

      return friends;
    } on PlatformException catch (e) {
      print(e.toString());
      throw CustomException(errorMessage: "Could not get friends");
    } on SocketException catch (e) {
      print(e.message);
      throw CustomException(errorMessage: "No Internet");
    } catch (e) {
      throw CustomException(errorMessage: "Could not get friends");
    }
  }

  /// Send friendrequest
  ///
  /// to send frined request
  static Future<void> sendFriendRequest(
      {String userId,
      String username,
      String userImageUrl,
      String currentUserId}) async {
    try {
      await _firebaseFirestore
          .collection(usersCollection)
          .doc(userId)
          .collection(friendRequestCollection)
          .doc(currentUserId)
          .set({
        "username": username,
        "by": currentUserId,
        "userImageUrl": userImageUrl,
        "timestamp": Timestamp.now()
      });
      await _firebaseFirestore
          .collection(usersCollection)
          .doc(currentUserId)
          .collection(friendRequestCollection)
          .doc(userId)
          .set({"by": currentUserId, "timestamp": Timestamp.now()});
    } on PlatformException catch (e) {
      print(e.message);
      throw CustomException(errorMessage: "Could not send friend request");
    } on SocketException catch (_) {
      throw CustomException(errorMessage: "No Internet");
    } catch (e) {
      print(e.toString());
      throw CustomException(errorMessage: "Could not send friend request");
    }
  }

  ///
  /// to remove friend request
  ///

  static Future<void> removeFriendRequest(
      {String userId, String currentUserId}) async {
    try {
      await _firebaseFirestore
          .collection(usersCollection)
          .doc(userId)
          .collection(friendRequestCollection)
          .doc(currentUserId)
          .delete();
      await _firebaseFirestore
          .collection(usersCollection)
          .doc(currentUserId)
          .collection(friendRequestCollection)
          .doc(userId)
          .delete();
    } on PlatformException catch (e) {
      print(e.message);
      throw CustomException(errorMessage: "Could not cancel friend request");
    } on SocketException catch (_) {
      throw CustomException(errorMessage: "No Internet");
    } catch (e) {
      print(e.toString());
      throw CustomException(errorMessage: "Could not cancel friend request");
    }
  }

  ///
  /// To check currentUser has sent freind request to given user
  /// or given user has sent friend request to current user
  ///
  static Future<int> requestStatus(
      {String userId, String currentUserId}) async {
    try {
      DocumentSnapshot documentSnapshot = await _firebaseFirestore
          .collection(usersCollection)
          .doc(currentUserId)
          .collection(friendRequestCollection)
          .doc(userId)
          .get();

      if (documentSnapshot.exists) {
        if (documentSnapshot.data()['by'] == currentUserId) {
          return 2; // current user has sent requqest to given user(friend)
        }
        // given user has sent request to current user
        return 3;
      }
      return 1; //1 means no request has been sent or received
    } on PlatformException catch (e) {
      print(e.message);
      throw CustomException(errorMessage: "Could not find request");
    } on SocketException catch (_) {
      throw CustomException(errorMessage: "No Internet");
    } catch (e) {
      print(e.toString());
      throw CustomException(errorMessage: "Could not find request");
    }
  }

  ///
  /// to check current user is friend with given user
  ///
  static Future<bool> checkIsFriend(
      {String userId, String currentUserId}) async {
    try {
      DocumentSnapshot documentSnapshot = await _firebaseFirestore
          .collection(usersCollection)
          .doc(currentUserId)
          .collection(friendsCollection)
          .doc(userId)
          .get();

      return documentSnapshot.exists;
    } on PlatformException catch (e) {
      print(e.message);
      throw CustomException(errorMessage: "Could not check friendship");
    } on SocketException catch (_) {
      throw CustomException(errorMessage: "No Internet");
    } catch (e) {
      print(e.toString());
      throw CustomException(errorMessage: "Could not check friendship");
    }
  }

  ///
  /// to add friend
  ///
  static Future<void> addFriend(
      {String userId,
      String currentUserId,
      String currnetUsername,
      String currentUserImageUrl,
      String username,
      String userImageUrl}) async {
    //
    try {
      print("Add friend");
      await _firebaseFirestore
          .collection(usersCollection)
          .doc(currentUserId)
          .collection(friendsCollection)
          .doc(userId)
          .set({
        "username": username,
        "userImageUrl": userImageUrl,
        "timestamp": Timestamp.now()
      });
      await _firebaseFirestore
          .collection(usersCollection)
          .doc(userId)
          .collection(friendsCollection)
          .doc(currentUserId)
          .set({
        "username": currnetUsername,
        "userImageUrl": currentUserImageUrl,
        "timestamp": Timestamp.now()
      });
    } on PlatformException catch (e) {
      print(e.message);
      throw CustomException(errorMessage: "Could not add friend");
    } on SocketException catch (_) {
      throw CustomException(errorMessage: "No Internet");
    } catch (e) {
      print(e.toString());
      throw CustomException(errorMessage: "Could not add friend");
    }
  }

  ///
  /// to remove friend
  ///
  static Future<void> removeFriend(
      {String userId, String currentUserId}) async {
    //
    try {
      await _firebaseFirestore
          .collection(usersCollection)
          .doc(currentUserId)
          .collection(friendsCollection)
          .doc(userId)
          .delete();

      await _firebaseFirestore
          .collection(usersCollection)
          .doc(userId)
          .collection(friendsCollection)
          .doc(currentUserId)
          .delete();
    } on PlatformException catch (e) {
      print(e.message);
      throw CustomException(errorMessage: "Could not remove friend");
    } on SocketException catch (_) {
      throw CustomException(errorMessage: "No Internet");
    } catch (e) {
      print(e.toString());
      throw CustomException(errorMessage: "Could not remove friend");
    }
  }
}
